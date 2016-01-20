use_frameworks!



def import_pods_iOS
	platform :ios, '8.0'
#    pod 'BMSCore'
    pod 'BMSCore', :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.git', :branch => 'analytics-removal', :commit => '6a8739762070802a724aea6b11ab54fb6b7dbe5b'
end

def import_pods_watchOS
	platform :watchos, '2.0'
#    pod 'BMSCore'
    pod 'BMSCore', :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.git', :branch => 'analytics-removal', :commit => '6a8739762070802a724aea6b11ab54fb6b7dbe5b'
end



target 'BMSAnalytics' do
	import_pods_iOS
end

target 'BMSAnalyticsTests' do

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

