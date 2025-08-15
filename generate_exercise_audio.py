#!/usr/bin/env python3
"""
Generate audio files for all exercise instructions using OpenAI TTS API.
This script reads exercise data and creates MP3 files for each instruction segment.
"""

import os
import json
import re
from pathlib import Path
from openai import OpenAI
import hashlib

# Initialize OpenAI client
client = OpenAI()

# Define the exercises and their instructions
EXERCISES = {
    "chin_tuck": {
        "name": "Chin Tuck",
        "benefits": "Strengthens neck muscles and improves posture",
        "instructions": [
            "Keep your shoulders back and spine straight",
            "Without tilting your head, gently draw your chin backward",
            "Hold for 5 seconds, feeling a gentle stretch at the base of your skull",
            "Slowly release back to neutral position",
            "Repeat 3-5 times"
        ]
    },
    "chin_tuck_quick": {
        "name": "Quick Chin Tuck",
        "benefits": "Quick posture reset for your neck",
        "instructions": [
            "Pull chin straight back (not down)",
            "Hold for 5 seconds",
            "Release slowly",
            "Repeat 3 times"
        ]
    },
    "scapular_retraction": {
        "name": "Shoulder Blade Squeeze",
        "benefits": "Counteracts rounded shoulders from computer work",
        "instructions": [
            "Sit or stand with spine straight",
            "Pull your shoulder blades back and together",
            "Imagine trying to hold a pencil between your shoulder blades",
            "Hold for 5 seconds",
            "Release slowly",
            "Repeat 5-10 times"
        ]
    },
    "scapular_retraction_quick": {
        "name": "Quick Shoulder Reset",
        "benefits": "Instant shoulder alignment fix",
        "instructions": [
            "Squeeze shoulder blades together",
            "Hold for 5 seconds",
            "Release",
            "Repeat 3 times"
        ]
    },
    "doorway_stretch": {
        "name": "Doorway Chest Stretch",
        "benefits": "Opens chest and counteracts forward shoulder position",
        "instructions": [
            "Stand in a doorway with arms at 90 degrees",
            "Place forearms on door frame",
            "Step forward slowly until you feel a stretch across your chest",
            "Hold for 30 seconds",
            "Step back and relax",
            "Repeat 2-3 times"
        ]
    },
    "upper_trap_stretch": {
        "name": "Upper Trap Stretch",
        "benefits": "Relieves tension in neck and shoulders",
        "instructions": [
            "Sit or stand with good posture",
            "Tilt your head to one side, bringing ear toward shoulder",
            "Place hand on opposite side of head for gentle pressure",
            "Hold for 30 seconds",
            "Slowly return to center",
            "Repeat on other side"
        ]
    },
    "neck_rolls": {
        "name": "Gentle Neck Rolls",
        "benefits": "Improves neck mobility and reduces stiffness",
        "instructions": [
            "Start with your head centered and shoulders relaxed",
            "Slowly lower chin to chest",
            "Gently roll head to the right",
            "Continue rolling back (look at ceiling)",
            "Roll to the left side",
            "Return to starting position",
            "Repeat 2-3 times, then reverse direction"
        ]
    },
    "shoulder_rolls": {
        "name": "Shoulder Rolls",
        "benefits": "Releases shoulder tension and improves circulation",
        "instructions": [
            "Sit or stand with arms relaxed at your sides",
            "Lift shoulders up toward your ears",
            "Roll shoulders back in a circular motion",
            "Lower shoulders down",
            "Complete 5 rolls backward",
            "Reverse and do 5 rolls forward"
        ]
    },
    "thoracic_extension": {
        "name": "Thoracic Extension",
        "benefits": "Improves upper back mobility and reduces hunching",
        "instructions": [
            "Sit tall in your chair with feet flat on floor",
            "Place hands behind your head, elbows wide",
            "Gently arch your upper back over the chair",
            "Look slightly upward as you extend",
            "Hold for 5 seconds",
            "Return to neutral",
            "Repeat 5 times"
        ]
    },
    "low_back_flex": {
        "name": "Low Back Flexion",
        "benefits": "Relieves lower back tension",
        "instructions": [
            "Stand with feet hip-width apart",
            "Slowly bend forward from the hips",
            "Let arms hang toward the floor",
            "Hold for 10-15 seconds",
            "Slowly roll back up to standing"
        ]
    },
    "standing_hip_flexor": {
        "name": "Standing Hip Flexor Stretch",
        "benefits": "Loosens tight hip flexors from prolonged sitting",
        "instructions": [
            "Stand with one foot forward in a lunge position",
            "Keep back leg straight, front knee bent at 90 degrees",
            "Push hips forward gently",
            "Hold for 30 seconds",
            "Switch legs and repeat"
        ]
    },
    "squat_hip_extensions": {
        "name": "Squat Hip Extensions",
        "benefits": "Activates glutes and improves hip mobility",
        "instructions": [
            "Stand with feet shoulder-width apart",
            "Perform a partial squat (45 degrees)",
            "Push through heels to stand",
            "Squeeze glutes at the top",
            "Repeat 10-15 times"
        ]
    },
    "standing_groin_stretch": {
        "name": "Standing Groin Stretch",
        "benefits": "Improves inner thigh flexibility",
        "instructions": [
            "Stand with feet wider than shoulder-width",
            "Shift weight to right side, bending right knee",
            "Keep left leg straight",
            "Hold for 20 seconds",
            "Return to center and switch sides"
        ]
    },
    "seated_glute_med_stretch": {
        "name": "Seated Glute Stretch",
        "benefits": "Relieves hip and glute tension",
        "instructions": [
            "Sit tall in your chair",
            "Cross right ankle over left knee",
            "Gently press down on right knee",
            "Lean forward slightly for deeper stretch",
            "Hold for 30 seconds",
            "Switch sides and repeat"
        ]
    },
    "gastrocnemius_stretch": {
        "name": "Calf Stretch (Gastrocnemius)",
        "benefits": "Stretches upper calf muscle",
        "instructions": [
            "Stand facing a wall, hands against wall",
            "Step right foot back, keeping heel on ground",
            "Keep back leg straight",
            "Lean forward until you feel calf stretch",
            "Hold for 30 seconds",
            "Switch legs"
        ]
    },
    "soleus_stretch": {
        "name": "Calf Stretch (Soleus)",
        "benefits": "Targets lower calf muscle",
        "instructions": [
            "Stand facing a wall, hands against wall",
            "Step right foot back",
            "Bend both knees slightly",
            "Keep back heel on ground",
            "Hold for 30 seconds",
            "Switch legs"
        ]
    },
    "toes_up_inversion_eversion": {
        "name": "Ankle Inversion/Eversion",
        "benefits": "Improves ankle stability and flexibility",
        "instructions": [
            "Sit with feet flat on floor",
            "Lift toes while keeping heels down",
            "Roll ankles inward (inversion)",
            "Roll ankles outward (eversion)",
            "Repeat 10 times each direction"
        ]
    },
    "plantar_dorsiflexion": {
        "name": "Ankle Pumps",
        "benefits": "Improves circulation and ankle mobility",
        "instructions": [
            "Sit or stand comfortably",
            "Point toes down (plantar flexion)",
            "Pull toes up toward shins (dorsiflexion)",
            "Hold each position for 2 seconds",
            "Repeat 15-20 times"
        ]
    },
    "ankle_circles": {
        "name": "Ankle Circles",
        "benefits": "Full range ankle mobility",
        "instructions": [
            "Sit with one leg extended",
            "Make slow circles with your foot",
            "Complete 10 circles clockwise",
            "Complete 10 circles counter-clockwise",
            "Switch feet and repeat"
        ]
    },
    "eye_exercise_20_20_20": {
        "name": "20-20-20 Rule",
        "benefits": "Reduces eye strain from screen time",
        "instructions": [
            "Look away from your screen",
            "Focus on something 20 feet away",
            "Hold your gaze for 20 seconds",
            "Blink several times to refresh"
        ]
    },
    "palming": {
        "name": "Eye Palming",
        "benefits": "Relaxes eye muscles and reduces strain",
        "instructions": [
            "Rub palms together to warm them",
            "Cup palms over closed eyes",
            "Don't press on eyeballs",
            "Breathe deeply and relax",
            "Hold for 30 seconds"
        ]
    },
    "deep_breathing": {
        "name": "Deep Breathing",
        "benefits": "Reduces stress and improves focus",
        "instructions": [
            "Sit comfortably with spine straight",
            "Breathe in slowly through nose for 4 counts",
            "Hold breath for 4 counts",
            "Exhale slowly through mouth for 6 counts",
            "Repeat 5-10 times"
        ]
    }
}

def generate_audio_file(text, output_path, voice="nova", instructions=None):
    """Generate an audio file from text using OpenAI TTS API."""
    try:
        # Use the newer model with instructions if provided
        if instructions:
            response = client.audio.speech.create(
                model="gpt-4o-mini-tts",
                voice=voice,
                input=text,
                instructions=instructions
            )
        else:
            response = client.audio.speech.create(
                model="tts-1-hd",  # Higher quality for non-instructed speech
                voice=voice,
                input=text
            )
        
        # Save the audio file
        response.stream_to_file(output_path)
        return True
    except Exception as e:
        print(f"Error generating audio for {output_path}: {e}")
        return False

def main():
    # Create assets directory structure
    assets_dir = Path("Assets/Audio/Exercises")
    assets_dir.mkdir(parents=True, exist_ok=True)
    
    # Voice selection - nova is clear and professional
    voice = "nova"
    
    # Track generated files
    generated_files = []
    audio_manifest = {}
    
    print("🎙️  Generating exercise audio files using OpenAI TTS...")
    print(f"   Voice: {voice}")
    print(f"   Output directory: {assets_dir}")
    print("")
    
    for exercise_key, exercise_data in EXERCISES.items():
        print(f"📝 Processing {exercise_data['name']}...")
        
        exercise_dir = assets_dir / exercise_key
        exercise_dir.mkdir(exist_ok=True)
        
        exercise_audio = {
            "name": exercise_data["name"],
            "files": {}
        }
        
        # Generate intro audio (name + benefits)
        intro_text = f"Starting {exercise_data['name']}. {exercise_data['benefits']}"
        intro_path = exercise_dir / "intro.mp3"
        
        if generate_audio_file(
            intro_text, 
            intro_path, 
            voice=voice,
            instructions="Speak clearly and professionally, with a calm and encouraging tone"
        ):
            exercise_audio["files"]["intro"] = str(intro_path.relative_to(Path.cwd()))
            print(f"   ✓ Generated intro")
        
        # Generate audio for each instruction
        for i, instruction in enumerate(exercise_data["instructions"], 1):
            instruction_text = f"Step {i}: {instruction}"
            instruction_path = exercise_dir / f"step_{i}.mp3"
            
            if generate_audio_file(
                instruction_text,
                instruction_path,
                voice=voice,
                instructions="Speak clearly with good pacing, as if guiding someone through an exercise"
            ):
                exercise_audio["files"][f"step_{i}"] = str(instruction_path.relative_to(Path.cwd()))
                print(f"   ✓ Generated step {i}")
        
        # Generate completion message
        completion_text = "Great job! Exercise complete."
        completion_path = exercise_dir / "complete.mp3"
        
        if generate_audio_file(
            completion_text,
            completion_path,
            voice=voice,
            instructions="Speak with an encouraging and congratulatory tone"
        ):
            exercise_audio["files"]["complete"] = str(completion_path.relative_to(Path.cwd()))
            print(f"   ✓ Generated completion")
        
        audio_manifest[exercise_key] = exercise_audio
        print("")
    
    # Save manifest file
    manifest_path = assets_dir / "audio_manifest.json"
    with open(manifest_path, "w") as f:
        json.dump(audio_manifest, f, indent=2)
    
    print(f"✅ Audio generation complete!")
    print(f"   Generated files in: {assets_dir}")
    print(f"   Manifest saved to: {manifest_path}")
    
    # Generate Swift helper file
    swift_helper = generate_swift_helper(audio_manifest)
    swift_path = Path("Models/ExerciseAudio.swift")
    with open(swift_path, "w") as f:
        f.write(swift_helper)
    print(f"   Swift helper saved to: {swift_path}")

def generate_swift_helper(manifest):
    """Generate a Swift file with audio file paths."""
    swift_code = """//
//  ExerciseAudio.swift
//  TouchGrass
//
//  Auto-generated file containing audio asset paths for exercises
//

import Foundation

struct ExerciseAudio {
    let exerciseKey: String
    let introPath: String?
    let stepPaths: [String]
    let completePath: String?
    
    static let audioAssets: [String: ExerciseAudio] = [
"""
    
    for exercise_key, data in manifest.items():
        files = data["files"]
        intro = files.get("intro", "nil")
        complete = files.get("complete", "nil")
        
        # Collect step paths
        steps = []
        step_num = 1
        while f"step_{step_num}" in files:
            steps.append(f'"{files[f"step_{step_num}"]}"')
            step_num += 1
        
        intro_str = f'"{intro}"' if intro != "nil" else "nil"
        complete_str = f'"{complete}"' if complete != "nil" else "nil"
        steps_str = "[" + ", ".join(steps) + "]"
        
        swift_code += f"""        "{exercise_key}": ExerciseAudio(
            exerciseKey: "{exercise_key}",
            introPath: {intro_str},
            stepPaths: {steps_str},
            completePath: {complete_str}
        ),
"""
    
    swift_code += """    ]
    
    static func audioFor(_ exerciseKey: String) -> ExerciseAudio? {
        return audioAssets[exerciseKey]
    }
}
"""
    
    return swift_code

if __name__ == "__main__":
    # Check for API key
    if not os.environ.get("OPENAI_API_KEY"):
        print("❌ Error: OPENAI_API_KEY environment variable not set")
        print("   Please set your OpenAI API key:")
        print("   export OPENAI_API_KEY='your-key-here'")
        exit(1)
    
    main()