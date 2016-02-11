
use_frameworks!


def pod_BMSCore
    pod 'BMSCore', :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.git', :branch => 'analytics-removal', :commit => '611d4681d96ef04108ba51f34572f24e022c1df4'
end


def import_pods_iOS
	platform :ios, '8.0'
#    pod 'BMSCore'
    pod_BMSCore
end

def import_pods_watchOS
	platform :watchos, '2.0'
#    pod 'BMSCore'
    pod_BMSCore
end



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
	
end

