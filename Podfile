
use_frameworks!



# Methods

def import_pods
    pod 'BMSCore', :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.git', :commit => '8c1126dcfa88cf82e6eac3e4ea6e40dc9d1fa293'
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
