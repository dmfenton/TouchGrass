#!/usr/bin/env ruby
# Comprehensive Xcode project sync script using xcodeproj gem
# Handles both adding new files and reorganizing existing files

require 'xcodeproj'
require 'pathname'

class XcodeProjectSync
  def initialize(project_path = 'TouchGrass.xcodeproj')
    @project_path = project_path
    @project = Xcodeproj::Project.open(project_path)
    @main_group = @project.main_group
    @source_group = find_source_group
    @organized_count = 0
  end

  def self.run(command, files = [])
    sync = new
    case command
    when 'organize'
      sync.organize_all_files
    when 'add'
      if files.empty?
        puts "❌ No files specified to add"
        exit 1
      end
      sync.add_files(files)
    when 'check'
      sync.check_organization
    else
      puts "Usage: #{$0} <organize|add|check> [files...]"
      puts ""
      puts "Commands:"
      puts "  organize          - Reorganize all files into proper groups"
      puts "  add <files...>    - Add new files to project in correct groups"
      puts "  check             - Check current organization status"
      puts ""
      puts "Examples:"
      puts "  #{$0} organize"
      puts "  #{$0} add Views/NewView.swift Models/NewModel.swift"
      puts "  #{$0} check"
      exit 1
    end
  end

  def find_source_group
    # Find the source group (it has empty name but path "." or is the main group)
    source_group = @main_group.groups.find { |g| g.name.nil? || g.name.empty? || g.name == '.' }
    source_group || @main_group
  end

  def ensure_groups_exist
    # Find or create groups at the main level
    @managers_group = find_or_create_group(@main_group, 'Managers')
    @models_group = find_or_create_group(@main_group, 'Models')
    @views_group = find_or_create_group(@main_group, 'Views')
    @touchgrass_group = find_or_create_group(@main_group, 'TouchGrass')

    # Create subgroups
    @design_group = find_or_create_group(@touchgrass_group, 'Design')
    @components_group = find_or_create_group(@touchgrass_group, 'Components', 'Views/Components')

    # Ensure groups don't have problematic paths that cause duplication
    [@managers_group, @models_group, @views_group, @touchgrass_group, @design_group].each do |group|
      group.path = nil if group
    end
  end

  def find_or_create_group(parent_group, name, path = nil)
    group = parent_group.children.find { |g| g.is_a?(Xcodeproj::Project::Object::PBXGroup) && g.name == name }
    unless group
      group = parent_group.new_group(name, path)
      puts "✅ Created group: #{name}"
    end
    group
  end

  def determine_target_group(file_path)
    file_name = File.basename(file_path)
    
    # Determine target based on file name and path
    case file_name
    when /Manager\.swift$/, 'ActivityTracker.swift', 'TimerService.swift', 'PreferencesStore.swift'
      @managers_group
    when 'Exercise.swift', 'Messages.swift'
      @models_group
    when 'DesignSystem.swift'
      @design_group
    when 'TouchGrassModeRefactored.swift'
      @touchgrass_group
    else
      # Check path-based classification
      if file_path.include?('Views/Components/') || 
         ['ActivitySelectionView.swift', 'CalendarContextView.swift', 'CompletionView.swift',
          'ExerciseMenuView.swift', 'InteractiveButton.swift', 'WaterTrackingBar.swift'].include?(file_name)
        @components_group
      elsif file_path.include?('Views/') || file_name.include?('View') || file_name.include?('Window') || file_name.include?('Controller')
        @views_group
      else
        # Keep in source group for root files like TouchGrassApp.swift, Info.plist
        @source_group
      end
    end
  end

  def add_files(file_paths)
    ensure_groups_exist
    
    file_paths.each do |file_path|
      unless File.exist?(file_path)
        puts "❌ File not found: #{file_path}"
        next
      end

      file_name = File.basename(file_path)
      
      # Check if file already exists in project
      if @project.files.any? { |f| f.path == file_path || f.name == file_name }
        puts "✓ #{file_name} already in project"
        next
      end

      target_group = determine_target_group(file_path)
      
      # Add file reference to the appropriate group
      file_ref = target_group.new_file(file_path)
      
      # Add to main target's sources build phase
      main_target = @project.targets.first
      if file_path.end_with?('.swift')
        main_target.add_file_references([file_ref])
      end
      
      group_name = target_group.name || 'root'
      puts "✅ Added #{file_name} to #{group_name} group"
      @organized_count += 1
    end

    save_project
  end

  def organize_all_files
    ensure_groups_exist
    
    # Files to keep in source group root
    root_files = ['Info.plist', 'TouchGrassApp.swift', 'AppIcon.icns']
    
    # Process all file references in the source group
    files_to_move = @source_group.files.dup
    
    files_to_move.each do |file_ref|
      file_name = File.basename(file_ref.path || file_ref.name || '')
      
      # Skip if it's a root file
      next if root_files.include?(file_name)
      
      target_group = determine_target_group(file_ref.path || file_name)
      
      # Skip if already in the right group
      next if file_ref.parent == target_group
      
      if target_group && target_group != @source_group
        # Remove from current group
        file_ref.parent.children.delete(file_ref)
        # Add to target group
        target_group.children << file_ref
        
        @organized_count += 1
        puts "📁 Moved #{file_name} to #{target_group.name}"
      end
    end

    save_project
  end

  def check_organization
    ensure_groups_exist
    
    puts "📊 Xcode Project Organization Status"
    puts "="*50
    puts ""
    
    puts "Current groups:"
    [@managers_group, @models_group, @views_group, @design_group, @components_group].each do |group|
      next unless group
      file_count = group.files.count
      puts "  - #{group.name}: #{file_count} files"
      if file_count > 0
        group.files.each { |f| puts "    • #{File.basename(f.path || f.name || 'Unknown')}" }
      end
    end
    
    puts ""
    puts "Files in source root:"
    @source_group.files.each do |file_ref|
      puts "  • #{File.basename(file_ref.path || file_ref.name || 'Unknown')}"
    end
    
    # Check for unorganized files
    unorganized = []
    @source_group.files.each do |file_ref|
      file_name = File.basename(file_ref.path || file_ref.name || '')
      unless ['Info.plist', 'TouchGrassApp.swift', 'AppIcon.icns'].include?(file_name)
        unorganized << file_name
      end
    end
    
    if unorganized.any?
      puts ""
      puts "⚠️  Files that could be organized:"
      unorganized.each { |f| puts "  • #{f}" }
      puts ""
      puts "Run: make xcode-organize"
    else
      puts ""
      puts "✅ All files are properly organized!"
    end
  end

  def save_project
    @project.save
    
    if @organized_count > 0
      puts ""
      puts "✅ Project reorganized successfully!"
      puts "📊 Organized #{@organized_count} files into groups"
      puts ""
      puts "Please rebuild the project in Xcode."
    end
  end
end

# Run the script
if __FILE__ == $0
  command = ARGV[0]
  files = ARGV[1..-1] || []
  XcodeProjectSync.run(command, files)
end