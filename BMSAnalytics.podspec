Pod::Spec.new do |s|

  s.name         = 'BMSAnalytics'
  s.version      = '0.0.11'
  s.summary      = 'The analytics component of the Swift client SDK for IBM Bluemix Mobile Services'
  s.homepage     = 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics'
  s.license      = 'Apache License, Version 2.0'
  s.authors      = { 'IBM Bluemix Services Mobile SDK' => 'mobilsdk@us.ibm.com' }

  s.source       = { :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics.git', :tag => "v#{s.version}" }
  s.source_files = 'Source/**/*.swift'
  s.ios.exclude_files = 'Source/**/*watchOS*.swift'
  s.watchos.exclude_files = 'Source/**/*iOS*.swift'

  s.dependency 'BMSCore', '~> 0.0.31'

  s.requires_arc = true

  s.ios.deployment_target = '8.0'
  s.watchos.deployment_target = '2.0'

end
