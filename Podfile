# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'FaceRecognitionClient' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for FaceRecognitionClient
  
  # MediaPipe Face Landmarker for consistent face detection with CoMa web app
  pod 'MediaPipeTasksVision'

  target 'FaceRecognitionClientTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'FaceRecognitionClientUITests' do
    # Pods for testing
  end

end

# Post install hook to ensure proper build settings
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      # Generate debug symbols for better crash symbolication
      config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
      config.build_settings['COPY_PHASE_STRIP'] = 'NO'
    end
  end
end
