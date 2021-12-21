import os
import base64
import logging
import time
import random
import json
import datetime
import csv
from json import JSONDecodeError
from locust import HttpUser, SequentialTaskSet, task, between, events
from locust.exception import RescheduleTask, RescheduleTaskImmediately

# List of all gestures for random picking
gestures = ["rock", "paper", "scissors", "lizard", "spock"]

class PlayerSequence(SequentialTaskSet):
    oid = ""  # User GUID
    username = "" # User name, usually an email address

    access_token = ""
    headers = {}
    all_users = []

    def get_random_user(self):
        # Pick a random user (=line)
        random_user = random.choice(self.all_users)

        if (len(random_user) != 2):
            # we expect exactly 2 (username, oid) - if not, stop this user
            raise StopLocust()

        return random_user[0], random_user[1]

    def set_random_current_player(self):
        self.username, self.oid = self.get_random_user()

    # Fetch a random OID of a user which is not the same as self.oid. We use this as the opponent player in a game result
    def get_random_opponent(self):
        username, oid = self.get_random_user()

        if( oid == self.oid ): # pick another OID if we randomly picked the current player again
            return self.get_random_opponent()
        else:
            return oid


    # # Function to decode a JWT and extract the OID
    # def decode_jwt(self):
    #     payload = self.access_token.split('.')[1]
    #     # Apply padding. Add = until length is multiple of 4
    #     while len(payload) % 4 != 0:
    #         payload += "="

    #     decoded_payload = base64.b64decode(payload)
    #     decoded_token = json.loads(decoded_payload.decode("utf-8"))
    #     self.oid = decoded_token['oid']
    #     logging.info(f"(decode_jwt) Extracted oid {self.oid} from access token")

    # Function to call Azure AD B2C token endpoint to fetch an access_token for a user
    def aad_b2c_auth(self):
        # Configuration of authentication - these values should reflect the Azure B2C tenant used by the load test target.
        tenant = os.environ["TENANT_NAME"]
        ropc_policy = os.environ["ROPC_POLICY_NAME"]
        client_id = os.environ["CLIENT_ID"]
        password = os.environ["LOADTEST_USER_PASSWORD"] # we expect the same password for all users
        scope = f"https://{tenant}.onmicrosoft.com/{client_id}/Games.Access"

        url = f'https://{tenant}.b2clogin.com/{tenant}.onmicrosoft.com/{ropc_policy}/oauth2/v2.0/token?client_id={client_id}&username={self.username}&password={password}&grant_type=password&tenant={tenant}.onmicrosoft.com&scope={scope}'

        with self.client.post(url, name="Get access token", catch_response=True) as response:
            if response.status_code == 400:
                logging.info("(get_access_token) 400 - Bad request. Failed to fetch access token!")
                response.failure(f"Could not fetch access token from B2C. Code: {response.status_code}")
            elif response.status_code != 200:
                logging.error(f"(get_access_token) - failed response. Will retry. Response code: {response.status_code}")
                raise RescheduleTask()
            else:
                self.access_token = json.loads(response._content)['access_token']
                self.headers = {'Authorization': 'Bearer ' + self.access_token}
                logging.info(f"(aad_b2c_auth) Fetched access token for user {self.username}")

        # Not needed since we have the OID also in the input csv file
        # Decode JWT to extract oid (User GUID)
        # self.decode_jwt()

    def on_start(self):

        # Read the users file once
        with open(os.environ["LOCUST_USERSFILE"]) as csvfile:
            # reading the whole users file into memory
            all_data = csv.reader(csvfile, delimiter=',')
            self.all_users = list(all_data)

        # Get random user from the list as current player
        self.set_random_current_player()
        # Fetch an access_token to start with
        self.aad_b2c_auth()

    @task(10) # Weight of 10 means its 10 times more likely to be executed than weight of 1 = @task()
    def play_ai_game(self):
        # Play a game against the server-side AI
        json_body = f"{random.choice(gestures)}"

        with self.client.post("/api/1.0/game/ai", json=json_body, name="POST AI game", headers=self.headers, catch_response=True) as response:
            if response.status_code == 401:
                logging.info("(play_ai_game) 401 - Need to fetch a new access token!")
                self.aad_b2c_auth()
                raise RescheduleTaskImmediately()
            elif response.status_code != 202:
                logging.error(f"(play_ai_game) - failed response. Code: {response.status_code}")
                response.failure(f"Got wrong response. Code: {response.status_code}")

    @task(10)
    def post_new_game_result(self):
        # Create a new game result
        json_body = {
            "player1Gesture": {
                "playerId": f"{self.oid}",
                "gesture": f"{random.choice(gestures)}"
            },
            "player2Gesture": {
                "playerId": f"{self.get_random_opponent()}", # Get a random opponent player OID
                "gesture": f"{random.choice(gestures)}"
            },
            "gameDate": f"{datetime.datetime.utcnow().isoformat()}Z" # isoformat() does not include the trailing Z to indicate UTC
        }
        with self.client.post("/api/1.0/game", json=json_body, name="POST new game result", headers=self.headers, catch_response=True) as response:
            if response.status_code == 401:
                logging.info("(post_new_game_result) 401 - Need to fetch a new access token!")
                self.aad_b2c_auth()
                raise RescheduleTaskImmediately()
            elif response.status_code != 202:
                logging.error(f"(post_new_game_result) - failed response. Code: {response.status_code}")
                response.failure(f"Got wrong response. Code: {response.status_code}")

    @task(2)
    def get_my_playerstats(self):
        # Get stats for the current player
        with self.client.get("/api/1.0/player/me", name="GET my Player Stats", headers=self.headers, catch_response=True) as response:
            if response.status_code == 401:
                logging.info("(get_my_playerstats) 401 - Need to fetch a new access token!")
                self.aad_b2c_auth()
                raise RescheduleTaskImmediately()
            elif response.status_code != 200:
                logging.error(f"(get_my_playerstats) - failed response. Code: {response.status_code}")
                response.failure(f"Got wrong response. Code: {response.status_code}")

    @task(1)
    def list_my_gameresults(self):
        with self.client.get("/api/1.0/player/me/games", name="LIST my GameResults", headers=self.headers, catch_response=True) as response:
            if response.status_code == 401:
                logging.info("(list_my_gameresults) 401 - Need to fetch a new access token!") # usually happens when the access tokens expires after an hour
                self.aad_b2c_auth()
                raise RescheduleTaskImmediately() # re-run this task with the newly refreshed token
            elif response.status_code != 200:
                logging.error(f"(list_my_gameresults) - failed response. Code: {response.status_code}")
                response.failure(f"Got wrong response. Code: {response.status_code}")

class WebsiteUser(HttpUser):
    tasks  = [PlayerSequence]
    wait_time = between(0.5, 2.5)