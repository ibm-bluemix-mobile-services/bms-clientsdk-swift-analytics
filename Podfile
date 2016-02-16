use_frameworks!



def pod_BMSCore
	pod 'BMSCore', '~> 0.0.16'
end

def import_pods_iOS
	platform :ios, '8.0'
    pod_BMSCore
end

def import_pods_watchOS
	platform :watchos, '2.0'
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
	import_pods_watchOS
end

