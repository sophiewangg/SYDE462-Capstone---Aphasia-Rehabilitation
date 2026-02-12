import asyncio
import logging
import assemblyai as aai
# Note the specific V3 imports
from assemblyai.streaming.v3 import (
    StreamingClient,
    StreamingClientOptions,
    StreamingEvents,
    StreamingParameters,
    TurnEvent,
    StreamingError,
    BeginEvent
)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("uvicorn")


class TranscriptionService:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.client = None

    def connect_to_assemblyai(self, websocket, loop):
        # 1. Initialize with REQUIRED options
        options = StreamingClientOptions(
            api_key=self.api_key
        )

        self.client = StreamingClient(options=options)

        # 2. Define Event Handlers (same as before)
        def on_begin(client, event: BeginEvent):
            logger.info(f"🟢 Session Started: {event.id}")

        def on_turn(client, event: TurnEvent):
            if not event.transcript:
                return
            logger.info(f"🎤 Text: {event.transcript}")

            data = {
                "text": event.transcript,
                "end_of_turn_confidence": event.end_of_turn_confidence,
                "end_of_turn": event.end_of_turn,
            }

            asyncio.run_coroutine_threadsafe(
                websocket.send_json(data),
                loop
            )

        def on_error(client, error: StreamingError):
            logger.error(f"🔴 AssemblyAI Error: {error}")

        # 3. Attach handlers
        self.client.on(StreamingEvents.Begin, on_begin)
        self.client.on(StreamingEvents.Turn, on_turn)
        self.client.on(StreamingEvents.Error, on_error)

        # 4. Connect
        logger.info("📡 Connecting to AssemblyAI V3...")
        self.client.connect(
            StreamingParameters(  # These params need to be conservative to give users time to respond
                sample_rate=16000,
                encoding='pcm_s16le',
                # Threshold for model confidence turn has ended
                end_of_turn_confidence_threshold=0.7,
                # How long to wait for silence if confidence is above threshold
                min_end_of_turn_silence_when_confident=800,
                max_turn_silence=3600,  # Max silence allowed before forcing end of turn
                # disable turn formatting as this adds latency and is unessesary for LLM interpretation
                format_turns=False
            )
        )

    def feed_audio(self, data: bytes):
        if self.client:
            self.client.stream(data)

    def close(self):
        if self.client:
            # Graceful disconnect
            self.client.disconnect(terminate=True)
            self.client = None
