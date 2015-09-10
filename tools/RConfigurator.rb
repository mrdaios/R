require 'xcodeproj'

# https://github.com/epam/lib-obj-c-attr/blob/master/libObjCAttr/Resources/ROADConfigurator.rb#L18
class RConfigurator
  def self.post_install(installer_representation)
    Xcodeproj::UI.puts "start RConfigurator config"
    RConfigurator::modify_build_phases(installer_representation)
  end
  def self.modify_build_phases(installer_representation)
    installer_representation.analysis_result.targets.each do |target|
      libRPod = false
      target.pod_targets.each do |pod_target|
        if pod_target.pod_name == 'R'
          libRPod = true
        end
      end

      if !libRPod
        next
      end

      if target.user_project_path.exist? && target.user_target_uuids.any?
        project = Xcodeproj::Project.open(target.user_project_path)
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
          phase.shell_script = '"$PODS_ROOT/R/tools/RLocalizable" -o "$SRCROOT/$TARGET_NAME/R/string" -p "$TARGET_NAME" "$SRCROOT/$TARGET_NAME/Localizable.strings"
          "$PODS_ROOT/R/tools/RImage" -o "$SRCROOT/$TARGET_NAME/R/image" -p "$TARGET_NAME" "$SRCROOT/$TARGET_NAME/Images.xcassets"'
          main_target.build_phases.insert(0,phase)
          project.save()
        end
      end
    end
  end
end