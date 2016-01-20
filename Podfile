use_frameworks!



def import_pods_iOS
	platform :ios, '8.0'
#    pod 'BMSCore'
    pod 'BMSCore', :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.git', :branch => 'analytics-removal', :commit => 'fabc67209288630a5eb93778ec61fe8d6031a76a'
end

def import_pods_watchOS
	platform :watchos, '2.0'
#    pod 'BMSCore'
pod 'BMSCore', :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-core.git', :branch => 'analytics-removal', :commit => 'fabc67209288630a5eb93778ec61fe8d6031a76a'
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

