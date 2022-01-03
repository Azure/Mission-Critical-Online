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


class PlayerSequence(SequentialTaskSet):

    headers = {}


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