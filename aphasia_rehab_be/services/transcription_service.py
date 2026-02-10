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
                "confidence": event.end_of_turn_confidence,
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
            StreamingParameters(
                sample_rate=16000,
                encoding='pcm_s16le'
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
