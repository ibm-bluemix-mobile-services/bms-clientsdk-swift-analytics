use_frameworks!



def import_pods_iOS
	platform :ios, '8.0'
#    pod 'BMSCore'
    pod 'BMSCore', :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.git', :branch => 'analytics-removal', :commit => 'a6c90ae44eb910f53a316dfa79337f142a1eb3dc'
end

def import_pods_watchOS
	platform :watchos, '2.0'
#    pod 'BMSCore'
    pod 'BMSCore', :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.git', :branch => 'analytics-removal', :commit => 'a6c90ae44eb910f53a316dfa79337f142a1eb3dc'
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

