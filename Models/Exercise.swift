//
//  Exercise.swift
//  TouchGrass
//
//  Exercise model and data for evidence-based posture correction
//

import Foundation

struct Exercise: Identifiable, Codable {
    let id: String
    let name: String
    let duration: Int // in seconds
    let category: ExerciseCategory
    let instructions: [String]
    let benefits: String
    let targetArea: String
    
    enum ExerciseCategory: String, Codable, CaseIterable {
        case stretch = "Stretch"
        case strengthen = "Strengthen"
        case mobilize = "Mobilize"
        case quickReset = "Quick Reset"
    }
}

struct ExerciseSet: Identifiable, Codable {
    let id: String
    let name: String
    let duration: Int // total seconds
    let exercises: [Exercise]
    let description: String
}

// Evidence-based exercises from 2024 research
struct ExerciseData {
    static let chinTuck = Exercise(
        id: "chin-tuck",
        name: "Chin Tucks",
        duration: 60,
        category: .strengthen,
        instructions: [
            "Sit or stand with spine tall and shoulders relaxed",
            "Keep your eyes looking straight ahead",
            "Slowly draw your chin straight back (not down)",
            "Imagine making a double chin",
            "Hold for 5 seconds",
            "Slowly release to neutral",
            "Repeat 10 times"
        ],
        benefits: "Strengthens deep neck flexors, reduces forward head posture",
        targetArea: "Neck and upper cervical spine"
    )
    
    static let scapularRetraction = Exercise(
        id: "scapular-retraction",
        name: "Scapular Retraction",
        duration: 45,
        category: .strengthen,
        instructions: [
            "Sit or stand with arms at your sides",
            "Keep shoulders down and relaxed",
            "Squeeze shoulder blades together",
            "Imagine holding a pencil between your shoulder blades",
            "Hold for 3-5 seconds",
            "Slowly release",
            "Repeat 10-15 times"
        ],
        benefits: "Strengthens mid-back muscles, improves upper back posture",
        targetArea: "Rhomboids and middle trapezius"
    )
    
    static let doorwayStretch = Exercise(
        id: "doorway-stretch",
        name: "Doorway Chest Stretch",
        duration: 60,
        category: .stretch,
        instructions: [
            "Stand in doorway with arm at 90 degrees",
            "Place forearm against door frame",
            "Step forward until you feel stretch in chest",
            "Keep shoulder blade pulled back",
            "Hold for 30 seconds",
            "Switch to other side",
            "Repeat once more each side"
        ],
        benefits: "Lengthens tight chest muscles, reduces rounded shoulders",
        targetArea: "Pectoralis major and minor"
    )
    
    static let upperTrapStretch = Exercise(
        id: "upper-trap-stretch",
        name: "Upper Trapezius Stretch",
        duration: 60,
        category: .stretch,
        instructions: [
            "Sit or stand with good posture",
            "Tilt head to right, bringing ear toward shoulder",
            "Place right hand gently on left side of head",
            "Apply gentle pressure for deeper stretch",
            "Keep left shoulder down",
            "Hold for 30 seconds",
            "Switch sides and repeat"
        ],
        benefits: "Relieves neck tension, reduces shoulder elevation",
        targetArea: "Upper trapezius and levator scapulae"
    )
    
    static let neckRolls = Exercise(
        id: "neck-rolls",
        name: "Gentle Neck Rolls",
        duration: 30,
        category: .mobilize,
        instructions: [
            "Sit or stand with shoulders relaxed",
            "Slowly look down, chin to chest",
            "Roll head to right shoulder",
            "Continue back to center",
            "Roll to left shoulder",
            "Return to center",
            "Repeat 3-5 times slowly"
        ],
        benefits: "Improves neck mobility, reduces stiffness",
        targetArea: "Cervical spine"
    )
    
    static let shoulderRolls = Exercise(
        id: "shoulder-rolls",
        name: "Shoulder Rolls",
        duration: 20,
        category: .mobilize,
        instructions: [
            "Sit or stand with arms relaxed",
            "Lift shoulders up toward ears",
            "Roll shoulders back",
            "Drop shoulders down",
            "Roll forward to starting position",
            "Repeat 5 times backward",
            "Then 5 times forward"
        ],
        benefits: "Releases shoulder tension, improves circulation",
        targetArea: "Shoulders and upper back"
    )
    
    static let thoracicExtension = Exercise(
        id: "thoracic-extension",
        name: "Seated Thoracic Extension",
        duration: 45,
        category: .mobilize,
        instructions: [
            "Sit tall in chair with feet flat",
            "Clasp hands behind head",
            "Keep elbows wide",
            "Gently arch upper back over chair",
            "Look slightly upward",
            "Hold for 3-5 seconds",
            "Return to neutral",
            "Repeat 8-10 times"
        ],
        benefits: "Counteracts hunched posture, improves spine mobility",
        targetArea: "Thoracic spine"
    )
    
    // Exercise Sets for different time constraints
    static let quickReset = ExerciseSet(
        id: "quick-reset",
        name: "30-Second Reset",
        duration: 30,
        exercises: [neckRolls],
        description: "Quick movement break for busy moments"
    )
    
    static let oneMinuteBreak = ExerciseSet(
        id: "one-minute",
        name: "1-Minute Posture Break",
        duration: 60,
        exercises: [chinTuck],
        description: "Essential exercise for forward head posture"
    )
    
    static let twoMinuteRoutine = ExerciseSet(
        id: "two-minute",
        name: "2-Minute Routine",
        duration: 120,
        exercises: [doorwayStretch, scapularRetraction],
        description: "Stretch and strengthen combination"
    )
    
    static let fullRoutine = ExerciseSet(
        id: "full-routine",
        name: "3-Minute Full Routine",
        duration: 180,
        exercises: [doorwayStretch, chinTuck, scapularRetraction, upperTrapStretch],
        description: "Complete evidence-based exercise protocol"
    )
    
    static let allExerciseSets = [
        quickReset,
        oneMinuteBreak,
        twoMinuteRoutine,
        fullRoutine
    ]
    
    static let coreExercises = [
        chinTuck,
        scapularRetraction,
        doorwayStretch,
        upperTrapStretch
    ]
}