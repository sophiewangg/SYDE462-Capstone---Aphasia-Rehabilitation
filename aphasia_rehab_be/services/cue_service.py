import requests
import json

class CueService:
    URL = "https://api.openai.com/v1/responses"
    MODEL = "gpt-4o-mini"

    def __init__(self, api_key: str):
        self.api_key = api_key

    def build_prompt(self, goal, transcription):
        return f"You are talking to someone with aphasia who has the following goal: {goal}.\n" \
            f"This is what they have just said: {transcription}.\n" \
            f"Provide the following cues: semantic, a word that rhymes, the first sound (>1 letters)" \
            f"Return a JSON object with the fields: 'likely_word', 'semantic', 'rhyming', 'first_sound'"
        
    def generate_cues(self, transcription, goal):
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        data = {
            "model": self.MODEL,  # use GPT-4o mini
            "input": self.build_prompt(goal, transcription)
        }

        response = requests.post(self.URL, headers=headers, json=data)
        result = response.json()

        text = result["output"][0]["content"][0]["text"]

        # remove markdown code fences
        clean = text.replace("```json", "").replace("```", "").strip()

        # convert string → dict
        parsed = json.loads(clean)
        return parsed