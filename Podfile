
use_frameworks!


def pod_BMSCore
    pod 'BMSCore', :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.git', :branch => 'analytics-removal', :commit => 'beac4faa17b4805c59667bfeca79222b4f01a6c7'
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
	
end

target 'TestAppWatchOS' do
	
end

target 'TestAppWatchOS Extension' do
	
end

