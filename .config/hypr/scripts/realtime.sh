#!/bin/bash



# pw-cat -r --format s16 --rate 24000 --channels 1 - \
#     | ffmpeg -f s16le -ar 24000 -ac 1 -i - -f s16le - \
#     | base64 \
#     | websocat -H="Authorization: Bearer $OPENAI_API_KEY" -H="OpenAI-Beta: realtime=v1" \
#     "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-10-01"

mkfifo /tmp/openai_voice_inp
mkfifo /tmp/openai_voice_out


websocat -H="Authorization: Bearer $OPENAI_API_KEY" -H="OpenAI-Beta: realtime=v1" \
        "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-10-01" \
        < /tmp/openai_voice_inp > /tmp/openai_voice_out


cat << EOF
{
    "type": "session.update",
    "session": {
        "modalities": ["text", "audio"],
        "instructions": "Your knowledge cutoff is 2023-10. You are a helpful assistant.",
        "voice": "alloy",
        "input_audio_format": "pcm16",
        "output_audio_format": "pcm16",
        "input_audio_transcription": {
            "enabled": true,
            "model": "whisper-1"
        },
        "turn_detection": {
            "type": "server_vad",
            "threshold": 0.5,
            "prefix_padding_ms": 300,
            "silence_duration_ms": 200
        },
        "temperature": 0.8,
        "max_output_tokens": null
    }
}
EOF

# ffmpeg -f pulse -i default -ar 24000 -ac 1 -af silenceremove=stop_periods=-1:start_threshold=-20dB:stop_threshold=-20dB -c:v copy -f wav output.wav
ffmpeg -f pulse -i default -ar 24000 -ac 1 -f s16le - \
    | base64 \
    | jq -R '{type: "input_audio_buffer.append", audio: .}' \
    > /tmp/openai_voice_inp

    # | websocat -H="Authorization: Bearer $OPENAI_API_KEY" -H="OpenAI-Beta: realtime=v1" \
    #     "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-10-01"


rm /tmp/openai_voice_inp
rm /tmp/openai_voice_out
