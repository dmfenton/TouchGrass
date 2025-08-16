#!/bin/bash

# Script to add test files to Xcode project
# This creates the test target and adds all test files

set -e

echo "📝 Adding test target to Xcode project..."

# Create the test scheme file
mkdir -p TouchGrass.xcodeproj/xcshareddata/xcschemes

cat > TouchGrass.xcodeproj/xcshareddata/xcschemes/TouchGrassTests.xcscheme << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.3">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "B71234501234567812345678"
               BuildableName = "Touch Grass.app"
               BlueprintName = "TouchGrass"
               ReferencedContainer = "container:TouchGrass.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "TEST1234567890ABCDEF12"
               BuildableName = "TouchGrassTests.xctest"
               BlueprintName = "TouchGrassTests"
               ReferencedContainer = "container:TouchGrass.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      codeCoverageEnabled = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "TEST1234567890ABCDEF12"
               BuildableName = "TouchGrassTests.xctest"
               BlueprintName = "TouchGrassTests"
               ReferencedContainer = "container:TouchGrass.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "B71234501234567812345678"
            BuildableName = "Touch Grass.app"
            BlueprintName = "TouchGrass"
            ReferencedContainer = "container:TouchGrass.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "B71234501234567812345678"
            BuildableName = "Touch Grass.app"
            BlueprintName = "TouchGrass"
            ReferencedContainer = "container:TouchGrass.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
EOF

echo "✅ Test scheme created"

# Now we need to update the project.pbxproj file
echo "📝 Note: You'll need to manually add the test files to Xcode:"
echo ""
echo "1. Open TouchGrass.xcodeproj in Xcode"
echo "2. File → New → Target → macOS → Unit Testing Bundle"
echo "3. Name it 'TouchGrassTests'"
echo "4. Add the test files from TouchGrassTests/ folder"
echo ""
echo "Test files to add:"
find TouchGrassTests -name "*.swift" | while read file; do
    echo "  - $file"
done

echo ""
echo "After adding the files, you can run tests with:"
echo "  make test"
echo "  make test-coverage"
echo "  make test-verbose"