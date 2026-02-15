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
    
    def evaluate_intent(self, transcript, expected_options):
            """
            Acts as a 'Judge' when Vector DB is unsure. 
            Determines if the transcript matches any of the expected intents contextually.
            """
            prompt = (
                f"Context: A user with aphasia is playing a dialogue game.\n"
                f"User said: \"{transcript}\"\n"
                f"The valid options for this moment are: {expected_options}\n\n"
                f"Task: Does the user's speech roughly align with any of the valid options? "
                f"Ignore stuttering or filler words.\n"
                f"Return a JSON object with: {{ 'is_match': boolean, 'matched_intent_index': int (or null) }}"
            )
            
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            }
            data = {
                "model": self.MODEL, 
                "input": prompt,
                "response_format": { "type": "json_object" }
            }

            try:
                response = requests.post(self.URL, headers=headers, json=data)
                result = response.json()
                text = result["output"][0]["content"][0]["text"]
                return json.loads(text)
            except Exception as e:
                print(f"LLM Judge Error: {e}")
                return {"is_match": False}