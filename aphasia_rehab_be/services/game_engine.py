from .cue_service import CueService
from .vector_service import VectorService


class GameEngine:
    # Tunable Thresholds
    STRICT_PASS_THRESHOLD = 0.45  # If distance is lower than this, auto-pass
    LLM_JUDGE_THRESHOLD = 0.75    # If between 0.45 and 0.75, ask LLM. Above 0.75 = Fail.

    def __init__(self, vector_service: VectorService, cue_service: CueService, db_session, dialogue_json: dict):
        self.vector_service = vector_service
        self.cue_service = cue_service
        self.dialogue_map = dialogue_json["nodes"]
        self.start_node = dialogue_json.get("start_node", "start_node")
        # In-memory only: dialogue progresses per user, not persisted to DB
        self._session_state: dict[str, str] = {}

    def get_user_state(self, user_id: str) -> str:
        return self._session_state.get(user_id, self.start_node)

    def update_user_state(self, user_id: str, new_node_id: str) -> None:
        self._session_state[user_id] = new_node_id

    def process_turn(self, user_id: str, transcript: str):
        """
        Main Game Logic:
        1. Check Vector DB.
        2. If good match -> Move Next.
        3. If okay match -> Ask LLM Judge.
        4. If bad match -> Generate Cue.
        State is kept in memory only (no DB persistence).
        """
        current_node_id = self.get_user_state(user_id)
        
        # 1. Vector Search
        # We wrap this in try/except in case the collection is empty or missing
        current_options = self.dialogue_map.get(current_node_id, {}).get("options", [])
        try:
            target_node_id, distance = self.vector_service.find_best_path(transcript, current_options)
        except Exception as e:
            # Fallback for errors (e.g., node has no options)
            return {
                "status": "error",
                "message": "End of conversation or system error.", 
                "npc_text": None
            }

        print(f"🔍 Vector Distance: {distance} | Transcript: {transcript}")

        # 2. Logic Gate
        next_node = None
        
        # CASE A: Strong Vector Match (Auto-Pass)
        if distance < self.STRICT_PASS_THRESHOLD:
            next_node = target_node_id

        # CASE B: Ambiguous (Ask the Judge)
        elif distance < self.LLM_JUDGE_THRESHOLD:
            print("⚖️ Distance ambiguous. Calling LLM Judge...")
            
            # Get the text descriptions of options for the current node to send to LLM
            current_options = self.dialogue_map[current_node_id].get("options", [])
            readable_options = [opt["user_phrases"] for opt in current_options]
            
            judgment = self.cue_service.evaluate_intent(transcript, readable_options)
            
            if judgment.get("is_match"):
                # LLM says it's good, find which target it matched to
                idx = judgment.get("matched_intent_index", 0)
                next_node = current_options[idx]["target"]
            else:
                pass # Judge said no, fall through to failure

        # 3. Handle Result
        if next_node:
            # SUCCESS: Move user to next node
            self.update_user_state(user_id, next_node)
            new_npc_text = self.dialogue_map[next_node]["npc_text"]
            return {
                "status": "success",
                "npc_text": new_npc_text,
                "confidence": distance
            }
        
        else:
            # FAILURE: User didn't make sense. Generate a Cue.
            print("❌ Match failed. Generating Cue...")
            
            # We need the "Goal" of the current node to generate a cue
            # (assuming the first option is the 'ideal' one for the prompt)
            node_data = self.dialogue_map[current_node_id]
            goal_text = node_data["options"][0]["user_phrases"][0] if node_data["options"] else "unknown"
            
            cues = self.cue_service.generate_cues(transcript, goal=goal_text)
            
            return {
                "status": "retry",
                "feedback": "I didn't quite catch that.",
                "cues": cues
            }