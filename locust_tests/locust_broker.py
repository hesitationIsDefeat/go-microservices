from locust import HttpUser, task, between

class BrokerUser(HttpUser):
    wait_time = between(1, 3)
    host = "http://34.111.13.158"

    @task
    def test_broker_mail(self):
        """
        Simulates a request to the broker service.
        Endpoint: /handle
        Method: POST
        """
        payload = {
            "action": "mail",
            "mail": {
                "from": "broker@test.com",
                "to": "user@test.com",
                "subject": "Final Test",
                "message": "This email should definitely arrive!"
            }
        }
        
        # Using json=payload automatically sets Content-Type: application/json
        with self.client.post("/handle", json=payload, catch_response=True) as response:
            if response.status_code == 200 or response.status_code == 202:
                response.success()
            else:
                response.failure(f"Broker request failed: {response.status_code} - {response.text}")
