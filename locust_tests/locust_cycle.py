from locust import HttpUser, task, between

class ServiceCycleUser(HttpUser):
    wait_time = between(1, 3)

    @task
    def test_service_cycle(self):
        """
        Simulates the full service cycle request.
        Endpoint: /test_service_cycle
        Method: POST
        """
        payload = {
            "email": "admin@example.com",
            "password": "password"
        }
        
        # headers are automatically handled for json=payload (Content-Type: application/json)
        with self.client.post("/test_service_cycle", json=payload, catch_response=True) as response:
            if response.status_code != 202:
                response.failure(f"Cycle failed: {response.status_code} - {response.text}")
            else:
                try:
                    json_response = response.json()
                    if json_response.get("error") is True:
                         response.failure(f"Cycle returned error: {response.text}")
                except Exception as e:
                    response.failure(f"Invalid JSON: {e}")
