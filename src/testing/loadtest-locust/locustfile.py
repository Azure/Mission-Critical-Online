import os
import base64
import logging
import time
import random
import json
import datetime
from json import JSONDecodeError
from locust import HttpUser, SequentialTaskSet, task, between, events
from locust.exception import RescheduleTask, RescheduleTaskImmediately

class WebsiteUserSequence(SequentialTaskSet):

    headers = { "X-TEST-DATA": "true" }  # Header to indicate that posted comments and rating are just for testing and can be deleted again by the app

    randomItemId = ""

    @task(2)
    def list_catalogitems(self):
        # Get list of catatlog items
        with self.client.get("/api/1.0/catalogitem", name="GET List of CatalogItems", catch_response=True) as response:
            if response.status_code != 200:
                logging.error(f"(list_catalogitems) - failed response. Code: {response.status_code}")
                response.failure(f"Got wrong response. Code: {response.status_code}")
            else:
                json_response = response.json()
                # Pick a random item from the catalog for further actions
                self.randomItemId = random.choice(json_response)['id']

    @task(20)
    def show_catalogitem(self):
        # Open a catalog item
        with self.client.get(f"/api/1.0/catalogitem/{self.randomItemId}", name="GET Catalog Item", catch_response=True) as response:
            if response.status_code != 200:
                logging.error(f"(show_catalogitem) - failed response. Code: {response.status_code}")
                response.failure(f"Got wrong response. Code: {response.status_code}")

    @task(10)
    def post_new_rating(self):
        # Post a new rating
        json_body = {
            "rating": random.randint(1, 5)
        }
        with self.client.post(f"/api/1.0/catalogitem/{self.randomItemId}/ratings", json=json_body, name="POST new rating", headers=self.headers, catch_response=True) as response:
            if response.status_code != 202:
                logging.error(f"(post_new_rating) - failed response. Code: {response.status_code}")
                response.failure(f"Got wrong response. Code: {response.status_code}")

    @task(2)
    def post_new_comment(self):
        # Post a new comment
        json_body = {
            "authorName": "Locust Test User",
            "text": "This is a load test entry"
        }
        with self.client.post(f"/api/1.0/catalogitem/{self.randomItemId}/comments", json=json_body, name="POST new comment", headers=self.headers, catch_response=True) as response:
            if response.status_code != 202:
                logging.error(f"(post_new_comment) - failed response. Code: {response.status_code}")
                response.failure(f"Got wrong response. Code: {response.status_code}")


class WebsiteUser(HttpUser):
    tasks  = [WebsiteUserSequence]
    wait_time = between(0.5, 2.5)