#!/bin/bash



pw-cat -r --format s16 --rate 24000 --channels 1 - | \
    ffmpeg -f s16le -ar 24000 -ac 1 -i - -f s16le - | \
    base64 | \
    websocat -H="Authorization: Bearer $OPENAI_API_KEY" -H="OpenAI-Beta: realtime=v1" \
    "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-10-01"
