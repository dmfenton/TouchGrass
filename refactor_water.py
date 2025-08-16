#!/usr/bin/env python3
"""Refactor ReminderManager to use WaterTracker"""

import re

# Read the file
with open('Managers/ReminderManager.swift', 'r') as f:
    content = f.read()

# Remove the two logWater methods and water-related private methods
# Pattern 1: Remove logWater methods
content = re.sub(
    r'    func logWater\([^}]*?\}\n(?:    \n)?',
    '',
    content,
    flags=re.DOTALL
)

# Pattern 2: Remove updateWaterStreak method
content = re.sub(
    r'    private func updateWaterStreak\(\)[^}]*?\}\n(?:    \n)?',
    '',
    content,
    flags=re.DOTALL
)

# Pattern 3: Remove resetDailyWaterIntake method
content = re.sub(
    r'    private func resetDailyWaterIntake\(\)[^}]*?\}\n(?:    \n)?',
    '',
    content,
    flags=re.DOTALL
)

# Add new water tracking delegation methods after the snoozeReminder method
water_delegation = '''    
    // MARK: - Water tracking (delegates to WaterTracker)
    func logWater(_ amount: Int = 1) {
        waterTracker.logWater(amount)
    }
    
    // Computed properties for backward compatibility
    var waterTrackingEnabled: Bool {
        get { waterTracker.isEnabled }
        set { waterTracker.isEnabled = newValue }
    }
    
    var dailyWaterGoal: Int {
        get { waterTracker.dailyGoal }
        set { waterTracker.dailyGoal = newValue }
    }
    
    var currentWaterIntake: Int {
        get { waterTracker.currentIntake }
        set { waterTracker.currentIntake = newValue }
    }
    
    var waterUnit: WaterUnit {
        get { waterTracker.unit }
        set { waterTracker.unit = newValue }
    }
    
    var waterStreak: Int {
        waterTracker.streak
    }
'''

# Find a good place to insert the delegation methods (after snoozeReminder)
pattern = r'(    func snoozeReminder\(\) \{[^}]*?\})'
content = re.sub(pattern, r'\1\n' + water_delegation, content)

# Remove water-related lines from loadSettings
content = re.sub(
    r'        // Load water settings.*?waterStreak = defaults\.integer\(forKey: waterStreakKey\)\n',
    '',
    content,
    flags=re.DOTALL
)

# Remove the sync dailyWaterOz section
content = re.sub(
    r'        // Sync dailyWaterOz.*?\}\n',
    '',
    content,
    flags=re.DOTALL
)

# Remove water-related lines from saveSettings
content = re.sub(
    r'        // Save water settings.*?defaults\.set\(waterStreak, forKey: waterStreakKey\)\n',
    '',
    content,
    flags=re.DOTALL
)

# Write the refactored file
with open('Managers/ReminderManager.swift', 'w') as f:
    f.write(content)

print("Refactoring complete!")