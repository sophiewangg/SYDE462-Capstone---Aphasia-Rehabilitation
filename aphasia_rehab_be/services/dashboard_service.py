import requests
import json

class DashboardService:
    URL = "https://api.openai.com/v1/responses"
    MODEL = "gpt-4o-mini"

    def __init__(self, api_key: str):
        self.api_key = api_key

    def build_prompt(self, goal, transcription):
        return f"You are talking to someone with aphasia who has been given the following prompt: {goal}.\n" \
            f"This was their one word response: {transcription}.\n" \
            f"Suggest two responses they could try next time for a more advanced respomse" \
            f"Return a JSON object with the fields: 'improved_response_1' and 'improved_response_2', 'prompt', 'response'"
    
    def improve_response(self, prompt: str, response: str):
            from worker import improve_response
            
            # Start the task in the background
            task = improve_response.delay(prompt, response)

            # RETURN ONLY THE ID. FastAPI can easily turn this into JSON.
            # Do NOT try to access 'task.result' or 'task.improved_response' here.
            return {"task_id": task.id}

    def get_improved_response(self, prompt: str, response: str):
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        data = {
            "model": self.MODEL,  # use GPT-4o mini
            "input": self.build_prompt(prompt, response)
        }

        response = requests.post(self.URL, headers=headers, json=data)
        result = response.json()

        text = result["output"][0]["content"][0]["text"]

        # remove markdown code fences
        clean = text.replace("```json", "").replace("```", "").strip()

        # convert string → dict
        parsed = json.loads(clean)

        print(parsed)
        return parsed