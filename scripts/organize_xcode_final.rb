#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'TouchGrass.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main group
main_group = project.main_group

# Find the source group (it has empty name but path ".")
source_group = main_group.groups.find { |g| g.name.nil? || g.name.empty? || g.name == '.' }
unless source_group
  puts "❌ Could not find source group"
  exit 1
end

puts "Found source group with #{source_group.children.count} children"

# Find or create groups at the main level
def find_or_create_group(parent_group, name, path = nil)
  group = parent_group.children.find { |g| g.is_a?(Xcodeproj::Project::Object::PBXGroup) && g.name == name }
  unless group
    group = parent_group.new_group(name, path)
    puts "✅ Created group: #{name}"
  else
    puts "Found existing group: #{name}"
  end
  group
end

# Find existing or create new groups
managers_group = find_or_create_group(main_group, 'Managers', 'Managers')
models_group = find_or_create_group(main_group, 'Models', 'Models')
views_group = find_or_create_group(main_group, 'Views', 'Views')
touchgrass_group = find_or_create_group(main_group, 'TouchGrass', 'TouchGrass')

# Create subgroups
design_group = find_or_create_group(touchgrass_group, 'Design', 'Design')
components_group = find_or_create_group(touchgrass_group, 'Components', 'Views/Components')

# Files to keep in source group root
root_files = ['Info.plist', 'TouchGrassApp.swift', 'AppIcon.icns']

# Track organized files
organized_count = 0

# Process all file references in the source group
files_to_move = source_group.files.dup

files_to_move.each do |file_ref|
  file_name = File.basename(file_ref.path || file_ref.name || '')
  
  # Skip if it's a root file
  next if root_files.include?(file_name)
  
  target_group = nil
  
  # Determine target based on file name and path
  case file_name
  when 'ActivityTracker.swift', 'CalendarManager.swift', 'OnboardingManager.swift',
       'ReminderManager.swift', 'UpdateManager.swift', 'WaterTracker.swift',
       'WindowHelper.swift', 'WorkHoursManager.swift', 'TimerService.swift',
       'PreferencesStore.swift'
    target_group = managers_group
    
  when 'Exercise.swift', 'Messages.swift'
    target_group = models_group
    
  when 'CustomizationView.swift', 'CustomizationWindowController.swift',
       'ExerciseSelectionView.swift', 'ExerciseView.swift', 'ExerciseWindowController.swift',
       'GrassIcon.swift', 'OnboardingCustomizationView.swift', 'OnboardingHeaderView.swift',
       'OnboardingWindow.swift', 'SimpleOnboardingWindow.swift', 'TouchGrassOnboarding.swift',
       'TouchGrassOnboardingController.swift', 'UpdateProgressView.swift',
       'WorkHoursSettingsView.swift', 'TouchGrassMode.swift', 'TouchGrassModeController.swift'
    target_group = views_group
    
  when 'DesignSystem.swift'
    target_group = design_group
    
  when 'ActivitySelectionView.swift', 'CalendarContextView.swift', 'CompletionView.swift',
       'ExerciseMenuView.swift', 'InteractiveButton.swift', 'WaterTrackingBar.swift'
    # These are components - check path to disambiguate from Views files
    if file_ref.path && file_ref.path.include?('Components')
      target_group = components_group
    end
    
  when 'TouchGrassModeRefactored.swift'
    target_group = touchgrass_group
  end
  
  if target_group
    # Remove from source group
    source_group.children.delete(file_ref)
    # Add to target group
    target_group.children << file_ref
    
    organized_count += 1
    puts "📁 Moved #{file_name} to #{target_group.name}"
  end
end

# Save the project
project.save

puts ""
puts "✅ Project reorganized successfully!"
puts "📊 Organized #{organized_count} files into groups"
puts ""
puts "Groups updated:"
puts "  - Managers: #{managers_group.files.count} files"
puts "  - Models: #{models_group.files.count} files"
puts "  - Views: #{views_group.files.count} files"
puts "  - TouchGrass/Design: #{design_group.files.count} files"
puts "  - TouchGrass/Components: #{components_group.files.count} files"
puts ""
puts "Please rebuild the project in Xcode."