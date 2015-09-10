require 'xcodeproj'

files = Dir["../../*.xcodeproj"]
if files.size > 0
  path_to_project = files[0]
  project = Xcodeproj::Project.open(path_to_project)
  main_target = project.targets.first
  phase = nil
  main_target.build_phases.each_with_index do |value, index|
    if value.isa == "PBXShellScriptBuildPhase" and value.name == "R"
      phase = value
    end
  end
  if !phase
    phase = project.new(Xcodeproj::Project::PBXShellScriptBuildPhase)
    phase.name = "R"
    phase.shell_script = '"$PODS_ROOT/R/tools/RLocalizable" -o "$SRCROOT/$TARGET_NAME/R/string" -p "$TARGET_NAME" "$SRCROOT/$TARGET_NAME/Localizable.strings"'
    main_target.build_phases.insert(0,phase)
    project.save()
  end
end