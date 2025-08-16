# Audio Generation for Exercise Instructions

This document describes how to generate audio files for exercise coaching using OpenAI's Text-to-Speech API.

## Setup

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. Set your OpenAI API key:
```bash
export OPENAI_API_KEY='your-api-key-here'
```

## Generate Audio Files

Run the generation script:
```bash
python generate_exercise_audio.py
```

This will:
- Create audio files for all exercise instructions in `Assets/Audio/Exercises/`
- Generate an intro audio for each exercise (name + benefits)
- Create numbered step audio files for each instruction
- Add a completion message audio
- Save a manifest file (`audio_manifest.json`) tracking all generated files
- Generate a Swift helper file (`Models/ExerciseAudio.swift`) for easy access in the app

## Audio Format

- **Format**: MP3
- **Model**: `gpt-4o-mini-tts` for instructed speech, `tts-1-hd` for high quality
- **Voice**: Nova (clear and professional)
- **Instructions**: Each audio is generated with specific tone instructions for context

## Directory Structure

```
Assets/
└── Audio/
    └── Exercises/
        ├── audio_manifest.json
        ├── chin_tuck/
        │   ├── intro.mp3
        │   ├── step_1.mp3
        │   ├── step_2.mp3
        │   ├── ...
        │   └── complete.mp3
        ├── scapular_retraction/
        │   └── ...
        └── ...
```

## Cost Estimation

- **TTS-1-HD**: $0.030 per 1,000 characters
- **GPT-4o-mini-TTS**: $0.015 per 1,000 characters
- Estimated total characters for all exercises: ~15,000
- Estimated cost: ~$0.25 - $0.45 for complete generation

## Updating Audio

To regenerate audio files (e.g., after changing instructions or voice):
1. Update the exercise data in `generate_exercise_audio.py`
2. Run the script again
3. Commit the new audio files to the repository

## Integration with App

The generated `ExerciseAudio.swift` file provides a simple API:

```swift
// Get audio paths for an exercise
if let audio = ExerciseAudio.audioFor("chin_tuck") {
    // Play intro
    playAudioFile(audio.introPath)
    
    // Play each step
    for stepPath in audio.stepPaths {
        playAudioFile(stepPath)
    }
    
    // Play completion
    playAudioFile(audio.completePath)
}
```

This allows the app to use pre-generated, high-quality audio instead of system TTS, providing:
- Consistent voice across all devices
- No synthesis delays
- Better voice quality
- Reduced UI jitter during playback