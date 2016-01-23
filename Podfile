use_frameworks!



def import_pods_iOS
	platform :ios, '8.0'
#    pod 'BMSCore'
    pod 'BMSCore', :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.git', :branch => 'analytics-removal', :commit => '685a300e3252b26f2f63641b35e929608a06d949'
end

def import_pods_watchOS
	platform :watchos, '2.0'
#    pod 'BMSCore'
    pod 'BMSCore', :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.git', :branch => 'analytics-removal', :commit => '685a300e3252b26f2f63641b35e929608a06d949'
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

