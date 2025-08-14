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
enum ExerciseData {
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
    
    static let chinTuckQuick = Exercise(
        id: "chin-tuck-quick",
        name: "Quick Chin Tucks",
        duration: 15,
        category: .strengthen,
        instructions: [
            "Draw your chin straight back",
            "Hold for 3 seconds",
            "Release to neutral",
            "Repeat 3-5 times"
        ],
        benefits: "Quick posture reset for forward head position",
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
    
    static let scapularRetractionQuick = Exercise(
        id: "scapular-retraction-quick",
        name: "Quick Shoulder Blade Squeeze",
        duration: 15,
        category: .strengthen,
        instructions: [
            "Squeeze shoulder blades together",
            "Hold for 3 seconds",
            "Release",
            "Repeat 3-5 times"
        ],
        benefits: "Quick reset for rounded shoulders",
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
    
    // Hip, Glute & Knee exercises
    static let lowBackFlex = Exercise(
        id: "low-back-flex",
        name: "Low Back Flex",
        duration: 30,
        category: .mobilize,
        instructions: [
            "Stand with feet shoulder-width apart, knees slightly bent",
            "Place your hands on your thighs for support if needed",
            "Round your lower back and gently tuck your pelvis under while squeezing your glutes lightly",
            "Slowly return to a neutral position",
            "Perform 8-10 slow reps"
        ],
        benefits: "Gently loosen your lower back and hips",
        targetArea: "Lower back and hips"
    )
    
    static let standingHipFlexor = Exercise(
        id: "standing-hip-flexor",
        name: "Standing Hip Flexor Stretch",
        duration: 45,
        category: .stretch,
        instructions: [
            "Stand with feet hip-width apart",
            "Step your right foot back about 2-3 feet",
            "Keep your torso upright and gently tuck your pelvis under your spine",
            "Shift weight forward until you feel a stretch in the front of the right hip",
            "Hold for 10-15 seconds, then switch legs"
        ],
        benefits: "Open up tight hips from sitting all day",
        targetArea: "Hip flexors"
    )
    
    static let squatHipExtensions = Exercise(
        id: "squat-hip-extensions",
        name: "Squat Hip Extensions",
        duration: 45,
        category: .mobilize,
        instructions: [
            "Stand with feet shoulder-width apart, toes slightly turned out",
            "Drop into a comfortable squat - chest tall, knees over toes",
            "Push your hips back and straighten your legs partway until you feel a stretch in your hamstrings",
            "Return to the squat position, then stand tall by driving through your heels",
            "Repeat for 8-10 reps: Squat → Hip Extension → Squat → Stand"
        ],
        benefits: "Open tight hips and stretch your hamstrings",
        targetArea: "Hips and hamstrings"
    )
    
    static let standingGroinStretch = Exercise(
        id: "standing-groin",
        name: "Standing Groin Stretch",
        duration: 45,
        category: .stretch,
        instructions: [
            "Stand with feet wide apart",
            "Shift your weight to one side, bending that knee while keeping the other leg straight",
            "Keep chest tall and hips back",
            "Hold for 10-15 seconds per leg",
            "Repeat 2-3 times per leg"
        ],
        benefits: "Stretch tight inner thighs for better hip mobility",
        targetArea: "Inner thighs (adductors)"
    )
    
    static let seatedGluteMedStretch = Exercise(
        id: "seated-glute-med",
        name: "Seated Glute Med Stretch",
        duration: 45,
        category: .stretch,
        instructions: [
            "Sit tall in a sturdy chair",
            "Cross your right ankle over your left knee",
            "Keep back straight and hinge forward from hips until you feel a stretch in the outer right hip",
            "Hold for 10-15 seconds per side",
            "Repeat 2-3 times per side - avoid rounding the back"
        ],
        benefits: "Relieve tension in the side of your hips",
        targetArea: "Glutes and outer hips"
    )
    
    // Ankle & Foot exercises
    static let gastrocnemiusStretch = Exercise(
        id: "gastrocnemius-stretch",
        name: "Gastrocnemius Stretch (Straight Knee)",
        duration: 45,
        category: .stretch,
        instructions: [
            "Stand facing a wall, place both hands on it at shoulder height",
            "Step one foot back about 2-3 feet",
            "Keep the back leg straight and heel flat on the ground",
            "Lean your body forward until you feel a stretch in the upper calf",
            "Hold for 10-15 seconds per leg, repeat 2-3 times"
        ],
        benefits: "Loosen tight calves for easier walking and squatting",
        targetArea: "Upper calf muscles"
    )
    
    static let soleusStretch = Exercise(
        id: "soleus-stretch",
        name: "Soleus Stretch (Bent Knee)",
        duration: 45,
        category: .stretch,
        instructions: [
            "Stay in the same wall-facing position as the previous stretch",
            "Step one foot back about 2 feet",
            "Bend the back knee while keeping the heel pressed firmly to the floor",
            "Lean in until you feel a stretch lower in the calf near the Achilles tendon",
            "Hold for 10-15 seconds per leg, repeat 2-3 times"
        ],
        benefits: "Target deep calf muscles to boost ankle flexibility",
        targetArea: "Lower calf and Achilles"
    )
    
    static let toesUpInversionEversion = Exercise(
        id: "toes-up-inversion-eversion",
        name: "Toes-Up Inversion & Eversion",
        duration: 40,
        category: .mobilize,
        instructions: [
            "Sit or stand, heel on the ground",
            "Lift the front of your foot so your toes are up",
            "Inversion: Roll the lifted forefoot inward so the sole faces toward your other foot",
            "Eversion: Roll the lifted forefoot outward so the sole faces away",
            "Alternate slowly, 2 seconds each way, for 5-10 reps each direction"
        ],
        benefits: "Train ankle control for better balance and stability",
        targetArea: "Ankle stabilizers"
    )
    
    static let plantarDorsiflexion = Exercise(
        id: "plantar-dorsiflexion",
        name: "Plantar & Dorsiflexion",
        duration: 40,
        category: .mobilize,
        instructions: [
            "Sit tall or stand, feet hip-width apart",
            "Keep your heel firmly on the ground",
            "Dorsiflexion: Slowly lift your toes toward your shin as high as possible",
            "Plantar flexion: Slowly press your toes down, pointing them forward",
            "Move smoothly, 2 seconds up, 2 seconds down, for 5-10 reps"
        ],
        benefits: "Wake up your ankles and get the blood flowing",
        targetArea: "Ankle flexors"
    )
    
    static let ankleCircles = Exercise(
        id: "ankle-circles",
        name: "Ankle Circles",
        duration: 60,
        category: .mobilize,
        instructions: [
            "Sit or stand with one foot lifted slightly off the floor",
            "Keep your knee and leg still - only your ankle moves",
            "Draw a slow, controlled circle with your toes, as large as comfortable",
            "Complete 5 circles clockwise, then 5 counterclockwise",
            "Switch feet and repeat 2-3 times each leg"
        ],
        benefits: "Free up ankle motion in every direction",
        targetArea: "Full ankle mobility"
    )
    
    // Additional exercises for eyes and breathing
    static let eyeExercise20_20_20 = Exercise(
        id: "20-20-20",
        name: "20-20-20 Rule",
        duration: 30,
        category: .quickReset,
        instructions: [
            "Look away from your screen",
            "Focus on something 20 feet away",
            "Hold your gaze for 20 seconds",
            "Blink slowly several times",
            "Return to your screen refreshed"
        ],
        benefits: "Reduces eye strain and fatigue",
        targetArea: "Eyes and focus muscles"
    )
    
    static let palming = Exercise(
        id: "palming",
        name: "Eye Palming",
        duration: 30,
        category: .quickReset,
        instructions: [
            "Rub your palms together to warm them",
            "Cup your palms over closed eyes",
            "Don't press on the eyeballs",
            "Relax in the darkness for 30 seconds",
            "Slowly remove hands and open eyes"
        ],
        benefits: "Relaxes eye muscles and reduces strain",
        targetArea: "Eyes"
    )
    
    static let deepBreathing = Exercise(
        id: "deep-breathing",
        name: "4-7-8 Breathing",
        duration: 60,
        category: .quickReset,
        instructions: [
            "Sit up straight with feet flat on floor",
            "Exhale completely through your mouth",
            "Close mouth, inhale through nose for 4 counts",
            "Hold breath for 7 counts",
            "Exhale through mouth for 8 counts",
            "Repeat 3-4 times"
        ],
        benefits: "Reduces stress, improves oxygen flow, resets posture",
        targetArea: "Respiratory system and nervous system"
    )
    
    // Exercise Sets for different time constraints
    static let quickReset = ExerciseSet(
        id: "quick-reset",
        name: "30-Second Posture Reset",
        duration: 30,
        exercises: [chinTuckQuick, scapularRetractionQuick],
        description: "Quick posture reset in 30 seconds"
    )
    
    static let quickMovement = ExerciseSet(
        id: "quick-movement",
        name: "Quick Movement Break",
        duration: 30,
        exercises: [neckRolls],
        description: "Quick movement break for busy moments"
    )
    
    static let eyeBreak = ExerciseSet(
        id: "eye-break",
        name: "Eye Relief Routine",
        duration: 60,
        exercises: [eyeExercise20_20_20, palming],
        description: "Reduce eye strain from screen time"
    )
    
    static let breathingExercise = ExerciseSet(
        id: "breathing",
        name: "Breathing & Relaxation",
        duration: 60,
        exercises: [deepBreathing],
        description: "Reset your breathing and reduce stress"
    )
    
    static let oneMinuteBreak = ExerciseSet(
        id: "one-minute",
        name: "1-Minute Posture Break",
        duration: 60,
        exercises: [chinTuck],
        description: "Essential exercise for forward head posture"
    )
    
    static let upperBodyRoutine = ExerciseSet(
        id: "upper-body",
        name: "Upper Body & Posture",
        duration: 180,
        exercises: [doorwayStretch, chinTuck, scapularRetraction, upperTrapStretch],
        description: "3-minute routine for neck, shoulders, and upper back"
    )
    
    static let lowerBodyRoutine = ExerciseSet(
        id: "lower-body",
        name: "Hips, Glutes & Knees",
        duration: 240,
        exercises: [lowBackFlex, standingHipFlexor, squatHipExtensions, standingGroinStretch, seatedGluteMedStretch],
        description: "5-minute routine to relieve lower body tension from sitting"
    )
    
    static let ankleFootRoutine = ExerciseSet(
        id: "ankle-foot",
        name: "Ankle & Foot Mobility",
        duration: 270,
        exercises: [gastrocnemiusStretch, soleusStretch, toesUpInversionEversion, plantarDorsiflexion, ankleCircles],
        description: "4.5-minute routine for ankle flexibility and foot health"
    )
    
    static let allExerciseSets = [
        oneMinuteBreak,
        upperBodyRoutine,
        lowerBodyRoutine,
        ankleFootRoutine
    ]
    
    static let coreExercises = [
        chinTuck,
        scapularRetraction,
        doorwayStretch,
        upperTrapStretch
    ]
}
