
use_frameworks!



# Methods

def import_pods
    pod 'BMSCore', :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.git', :commit => '5028457f95b93ee16c894e9cec6f7371f4afd413'
end

def import_pods_iOS
	platform :ios, '8.0'
    import_pods
end

def import_pods_watchOS
	platform :watchos, '2.0'
    import_pods
end



# Targets

target 'MFPAnalytics' do
	import_pods_iOS
end

target 'MFPAnalyticsTests' do
    import_pods_iOS
end

target 'MFPAnalyticsWatchOS' do
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
