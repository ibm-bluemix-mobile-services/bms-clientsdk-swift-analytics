Pod::Spec.new do |s|
  s.name              = 'BMSAnalytics'
  s.version           = '2.2.4'
  s.summary           = 'The analytics component of the Swift client SDK for IBM Bluemix Mobile Services'
  s.homepage          = 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics'
  s.documentation_url = 'https://ibm-bluemix-mobile-services.github.io/API-docs/client-SDK/BMSAnalytics/Swift/index.html'
  s.license           = 'Apache License, Version 2.0'
  s.authors           = { 'IBM Bluemix Services Mobile SDK' => 'mobilsdk@us.ibm.com' }

  s.source       = { :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics.git', :tag => s.version, }

  s.subspec 'SSZipArchive' do |ss|
    ss.source_files = 'Source/SSZipArchive/*.{m,h}', 'Source/SSZipArchive/minizip/*.{c,h}', 'Source/SSZipArchive/minizip/aes/*.{c,h}' 
    ss.libraries = 'z'
    ss.pod_target_xcconfig = {'SWIFT_INCLUDE_PATHS' => '$(SRCROOT)/Source/SSZipArchive','LIBRARY_SEARCH_PATHS' => '$(SRCROOT)/Source/SSZipArchive'}
    ss.public_header_files= 'Source/SSZipArchive/*.h','Source/SSZipArchive/minizip/*.h','Source/SSZipArchive/minizip/aes/*.h'
  end

  s.source_files = 'Source/**/*.swift','Source/Resource/*.h'
  s.ios.exclude_files = 'Source/**/*watchOS*.swift'
  s.watchos.exclude_files = 'Source/**/*iOS*.swift','Source/Feedback','Source/SSZipArchive/*.{swift,h}', 'Source/SSZipArchive/minizip/*.{c,h}', 'Source/Zip/minizip/aes/*.{c,h}'
  s.dependency 'BMSCore', '~> 2.1'

  s.requires_arc = true
  s.ios.resources = ['Source/Resources/*.{storyboard,xcassets,json,imageset,png}']
  s.ios.deployment_target = '8.0'
  s.watchos.deployment_target = '2.0'
end
