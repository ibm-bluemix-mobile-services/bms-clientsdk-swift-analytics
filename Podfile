
use_frameworks!



# Methods

def pod_BMSCore
#	pod 'BMSCore', '~> 0.0.17'
    pod 'BMSCore', :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.git', :commit => '77016a327d8907ccb4d22e175b5ce221787731e5'
end

def import_pods_iOS
	platform :ios, '8.0'
    pod_BMSCore
end

def import_pods_watchOS
	platform :watchos, '2.0'
    pod_BMSCore
end



# Targets

target 'BMSAnalytics' do
	import_pods_iOS
end

target 'BMSAnalyticsTests' do
    import_pods_iOS
end

target 'BMSAnalyticsWatchOS' do
	import_pods_watchOS
end

target 'TestAppiOS' do
	import_pods_iOS
end

target 'TestAppWatchOS' do

end

target 'TestAppWatchOS Extension' do
	import_pods_watchOS
end



# Post installer

# The -DDEBUG flag allows Logger to print logs to the console, but only when the app is running in Debug mode
post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name.include? 'BMSCore'
            target.build_configurations.each do |config|
                if config.name == 'Debug'
                    config.build_settings['OTHER_SWIFT_FLAGS'] = '-DDEBUG'
                else
                    config.build_settings['OTHER_SWIFT_FLAGS'] = ''
                end
            end
        end
    end
end
