import requests
import json

class LLMFallbackService:
    URL = "https://api.openai.com/v1/responses"
    MODEL = "gpt-4o-mini"

    def __init__(self, api_key: str):
        self.api_key = api_key

    def handle_reservation(self, transcription, current_prompt):
        return f"You are talking to someone with aphasia who has been given the following prompt: {current_prompt}.\n" \
            f"This is what they have just said: {transcription}.\n" \
            f"If the user's text indicates they have a reservation, 'intents' = ['reservation_yes']\n" \
            f"If the user's text indicates they do not have a reservation, 'intents' = ['reservation_no']\n" \
            f"If the user's text indicates neither/is irrelevant, 'intents' = null \n" \
            f"Return a JSON object with the fields: 'intents' which is a list of strings or null\n"


    def number_people(self, transcription, current_prompt):
        return f"You are talking to someone with aphasia.\n\n" \
        f"Prompt given to the user: {current_prompt}\n" \
        f"User's response: {transcription}\n\n" \
        f"Task:\n" \
        f"Determine whether the user’s response clearly answers the prompt question " \
        f"Rules:\n" \
        f"- If the response includes any clear number of people (e.g., \"one\", \"two\", \"3 people\", \"just me\"), return:\n" \
        f"  {{\"intents\": [\"one_person\"]}}\n" \
        f"- If the response does NOT clearly indicate a number of people, return:\n" \
        f"  {{\"intents\": null}}\n\n" \
        f"Important:\n" \
        f"- The label \"one_person\" means the user successfully answered the question, regardless of the actual number.\n" \
        f"- Do NOT interpret \"one_person\" literally.\n\n"

    def drinks_offer(self, transcription, current_prompt):
        return f"You are talking to someone with aphasia.\n\n" \
        f"Prompt given to the user: {current_prompt}\n" \
        f"User's response: {transcription}\n\n" \
        f"Task:\n" \
        f"Determine whether the user’s response clearly answers the prompt question " \
        f"Rules:\n" \
        f"- If the response includes any clear drink that is a soda, lemonade, tea, coffee, beer, wine, return:\n" \
        f"  {{\"intents\": [\"beverage_other\"]}}\n" \
        f"- If the response does NOT clearly indicate a beverage, return:\n" \
        f"  {{\"intents\": null}}\n\n" \
        f"Important:\n" \
        f"- The label \"beverage_other\" means the user successfully answered the question, regardless of the actual beverage.\n" \
        f"- Do NOT interpret \"beverage_other\" literally.\n\n"

    def ice_question(self, transcription, current_prompt):
        return f"You are talking to someone with aphasia.\n\n" \
        f"Prompt given to the user: {current_prompt}\n" \
        f"User's response: {transcription}\n\n" \
        f"Task:\n" \
        f"Determine whether the user’s response clearly answers the prompt question " \
        f"Rules:\n" \
        f"- If the response indicates the user wants ice in their drink, return:\n" \
        f"  {{\"intents\": [\"yes_ice\"]}}\n" \
        f"- If the response indicates the user doesn't want ice in their drink, return:\n" \
        f"  {{\"intents\": [\"no_ice\"]}}\n" \
        f"- If the response does NOT clearly indicate if they want ice in their drink, return:\n" \
        f"  {{\"intents\": null}}\n\n"

    def water_type(self, transcription, current_prompt):
        return f"You are talking to someone with aphasia.\n\n" \
        f"Prompt given to the user: {current_prompt}\n" \
        f"User's response: {transcription}\n\n" \
        f"Task:\n" \
        f"Determine whether the user’s response clearly answers the prompt question " \
        f"Rules:\n" \
        f"- If the response indicates the user wants sparkling water, return:\n" \
        f"  {{\"intents\": [\"water_sparkling\"]}}\n" \
        f"- If the response indicates the user wants still water, return:\n" \
        f"  {{\"intents\": [\"water_tap\"]}}\n" \
        f"- If the response does NOT clearly indicate if they want still or sparkling water, return:\n" \
        f"  {{\"intents\": null}}\n\n"

    def ready_to_order(self, transcription, current_prompt):
        return f"You are talking to someone with aphasia.\n\n" \
        f"Prompt given to the user: {current_prompt}\n" \
        f"User's response: {transcription}\n\n" \
        f"Task:\n" \
        f"Determine whether the user’s response clearly answers the prompt question " \
        f"Rules:\n" \
        f"- If the response indicates the user is ready to order, return:\n" \
        f"  {{\"intents\": [\"ready_yes\"]}}\n" \
        f"- If the response indicates the user is not ready to order, return:\n" \
        f"  {{\"intents\": [\"ready_no\"]}}\n" \
        f"- If the response does NOT clearly indicate if they are ready to order, return:\n" \
        f"  {{\"intents\": null}}\n\n"
    
    def appetizers(self, transcription, current_prompt):
        return f"You are talking to someone with aphasia.\n\n" \
        f"Prompt given to the user: {current_prompt}\n" \
        f"User's response: {transcription}\n\n" \
        f"Task:\n" \
        f"Determine whether the user’s response clearly answers the prompt question " \
        f"Rules:\n" \
        f"- If the response indicates the user wants no appetizers, return:\n" \
        f"  {{\"intents\": [\"no_appetizer\"]}}\n" \
        f"- If the response indicates the user is asking about the specials/soup of the day, return:\n" \
        f"  {{\"intents\": [\"ask_specials\"]}}\n" \
        f"- If the response indicates the user is asking for recommendations, return:\n" \
        f"  {{\"intents\": [\"ask_recommendations\"]}}\n" \
        f"- If the response indicates the user is ordering the soup, return:\n" \
        f"  {{\"intents\": [\"order_soup\"]}}\n" \
        f"- If the response indicates the user is ordering the soup, return:\n" \
        f"  {{\"intents\": [\"order_bruschetta\"]}}\n" \
        f"- If the response does NOT clearly indicate what they are ordering as an appetizer, return:\n" \
        f"  {{\"intents\": null}}\n\n"

    def entrees(self, transcription, current_prompt):
        return f"You are talking to someone with aphasia.\n\n" \
        f"Prompt given to the user: {current_prompt}\n" \
        f"User's response: {transcription}\n\n" \
        f"Task:\n" \
        f"Determine whether the user’s response clearly answers the prompt question " \
        f"Rules:\n" \
        f"- If the response indicates the user wants no entrees, return:\n" \
        f"  {{\"intents\": [\"no_entrees\"]}}\n" \
        f"- If the response indicates the user is ordering the Ribeye Steak, return:\n" \
        f"  {{\"intents\": [\"order_steak\"]}}\n" \
        f"- If the response indicates the user is ordering the Chicken Katsu, return:\n" \
        f"  {{\"intents\": [\"order_chicken\"]}}\n" \
        f"- If the response indicates the user is ordering the Seafood Alfredo, return:\n" \
        f"  {{\"intents\": [\"order_pasta\"]}}\n" \
        f"- If the response does NOT clearly indicate what they are ordering as an entree, return:\n" \
        f"  {{\"intents\": null}}\n\n"

    def steak_doneness(self, transcription, current_prompt):
        return f"You are talking to someone with aphasia.\n\n" \
        f"Prompt given to the user: {current_prompt}\n" \
        f"User's response: {transcription}\n\n" \
        f"Task:\n" \
        f"Determine whether the user’s response clearly answers the prompt question " \
        f"Rules:\n" \
        f"- If the response includes any clear steak doneness, return:\n" \
        f"  {{\"intents\": [\"steak_doneness\"]}}\n" \
        f"- If the response does NOT clearly indicate steak doneness, return:\n" \
        f"  {{\"intents\": null}}\n\n" \
        f"Important:\n" \
        f"- The label \"steak_doneness\" means the user successfully answered the question, regardless of the steak doneness.\n"

    def side_choice(self, transcription, current_prompt):
        return f"You are talking to someone with aphasia.\n\n" \
        f"Prompt given to the user: {current_prompt}\n" \
        f"User's response: {transcription}\n\n" \
        f"Task:\n" \
        f"Determine whether the user’s response clearly answers the prompt question " \
        f"Rules:\n" \
        f"- If the response indicates the user wants fries, return:\n" \
        f"  {{\"intents\": [\"side_fries\"]}}\n" \
        f"- If the response indicates the user wants salad, return:\n" \
        f"  {{\"intents\": [\"side_salad\"]}}\n" \
        f"- If the response indicates the user wants no sides, return:\n" \
        f"  {{\"intents\": [\"side_salad\"]}}\n" \
        f"- If the response does NOT clearly indicate what they are ordering as an entree, return:\n" \
        f"  {{\"intents\": null}}\n\n" \
        f"Important:\n" \
        f"- The label \"side_salad\" means the user successfully answered the question, regardless of if they ordered a salad or no side.\n"
    
    def is_that_all(self, transcription, current_prompt):
        return f"You are talking to someone with aphasia.\n\n" \
        f"Prompt given to the user: {current_prompt}\n" \
        f"User's response: {transcription}\n\n" \
        f"Task:\n" \
        f"Determine whether the user’s response clearly answers the prompt question " \
        f"Rules:\n" \
        f"- If the response indicates that they are done ordering, return:\n" \
        f"  {{\"intents\": [\"is_that_all_yes\"]}}\n" \
        f"- If the response indicates that they are not done ordering, return:\n" \
        f"  {{\"intents\": [\"is_that_all_no\"]}}\n" \
        f"- If the response does NOT clearly indicate if they are done ordering, return:\n" \
        f"  {{\"intents\": null}}\n\n" \
        
    def how_is_everything(self, transcription, current_prompt):
        return f"You are talking to someone with aphasia.\n\n" \
        f"Prompt given to the user: {current_prompt}\n" \
        f"User's response: {transcription}\n\n" \
        f"Task:\n" \
        f"Determine whether the user’s response clearly answers the prompt question " \
        f"Rules:\n" \
        f"- If the response includes any clear answer to the question, return:\n" \
        f"  {{\"intents\": [\"satisfied\"]}}\n" \
        f"- If the response does NOT clearly answer the question question, return:\n" \
        f"  {{\"intents\": null}}\n\n" \
        f"Important:\n" \
        f"- The label \"satisfied\" means the user successfully answered the question, regardless of the actual satisfaction.\n" \
        f"- Do NOT interpret \"satisfied\" literally.\n\n"

    def are_you_done(self, transcription, current_prompt):
        return f"You are talking to someone with aphasia.\n\n" \
        f"Prompt given to the user: {current_prompt}\n" \
        f"User's response: {transcription}\n\n" \
        f"Task:\n" \
        f"Determine whether the user’s response clearly answers the prompt question " \
        f"Rules:\n" \
        f"- If the response indicates that they are done with their food, return:\n" \
        f"  {{\"intents\": [\"done_eating_yes\"]}}\n" \
        f"- If the response indicates that they are not done with their food, return:\n" \
        f"  {{\"intents\": [\"done_eating_no\"]}}\n" \
        f"- If the response does NOT clearly indicate if they are done with their food, return:\n" \
        f"  {{\"intents\": null}}\n\n" \
        
    def ready_for_bill(self, transcription, current_prompt):
        return f"You are talking to someone with aphasia.\n\n" \
        f"Prompt given to the user: {current_prompt}\n" \
        f"User's response: {transcription}\n\n" \
        f"Task:\n" \
        f"Determine whether the user’s response clearly answers the prompt question " \
        f"Rules:\n" \
        f"- If the response indicates that they are ready for the bill, return:\n" \
        f"  {{\"intents\": [\"ready_for_bill_yes\"]}}\n" \
        f"- If the response indicates that they are not ready for the bill, return:\n" \
        f"  {{\"intents\": [\"ready_for_bill_no\"]}}\n" \
        f"- If the response does NOT clearly indicate if they are ready for the bill, return:\n" \
        f"  {{\"intents\": null}}\n\n" \
        
    def payment_method(self, transcription, current_prompt):
        return f"You are talking to someone with aphasia.\n\n" \
        f"Prompt given to the user: {current_prompt}\n" \
        f"User's response: {transcription}\n\n" \
        f"Task:\n" \
        f"Determine whether the user’s response clearly answers the prompt question " \
        f"Rules:\n" \
        f"- If the response includes any clear payment method, return:\n" \
        f"  {{\"intents\": [\"payment_method\"]}}\n" \
        f"- If the response does NOT clearly indicate a payment method, return:\n" \
        f"  {{\"intents\": null}}\n\n" \
        f"Important:\n" \
        f"- The label \"payment_method\" means the user successfully answered the question, regardless of the actual payment method.\n" \
        f"- Do NOT interpret \"payment_method\" literally.\n\n"
    
    def receipt(self, transcription, current_prompt):
        return f"You are talking to someone with aphasia.\n\n" \
        f"Prompt given to the user: {current_prompt}\n" \
        f"User's response: {transcription}\n\n" \
        f"Task:\n" \
        f"Determine whether the user’s response clearly answers the prompt question " \
        f"Rules:\n" \
        f"- If the response indicates that they want their receipt, return:\n" \
        f"  {{\"intents\": [\"receipt_yes\"]}}\n" \
        f"- If the response indicates that they don't want their receipt, return:\n" \
        f"  {{\"intents\": [\"receipt_no\"]}}\n" \
        f"- If the response does NOT clearly indicate if they want their receipt, return:\n" \
        f"  {{\"intents\": null}}\n\n" \
    
    def perform_llm_fallback(self, transcription, current_step, current_prompt):
        # The "Switch" table
        handlers = {
            "reservation": self.handle_reservation,
            "numberPeople": self.number_people,
            "drinksOffer": self.drinks_offer,
            "iceQuestion": self.ice_question,
            "waterType": self.water_type,
            "readyToOder": self.ready_to_order,
            "appetizers": self.appetizers,
            "entrees": self.entrees,
            "steakDoness": self.steak_doneness,
            "sideChoice": self.side_choice,
            "isThatAll": self.is_that_all,
            "howIsEverything": self.how_is_everything,
            "areYouDone": self.are_you_done,
            "readyForBill": self.ready_for_bill,
            "paymentMethod": self.payment_method,
            "receipt": self.receipt
        }
        print(handlers.get(current_step, lambda x: "Unknown step")(transcription, current_prompt))
        result = handlers.get(current_step, lambda x: "Unknown step")(transcription, current_prompt)

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        data = {
            "model": self.MODEL,  # use GPT-4o mini
            "input": result
        }

        response = requests.post(self.URL, headers=headers, json=data)
        result = response.json()

        text = result["output"][0]["content"][0]["text"]
        print(text)

        # remove markdown code fences
        clean = text.replace("```json", "").replace("```", "").strip()

        # convert string → dict
        parsed = json.loads(clean)
        return parsed