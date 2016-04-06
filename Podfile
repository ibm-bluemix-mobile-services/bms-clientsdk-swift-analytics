
use_frameworks!



# Methods

def import_pods
    pod 'BMSCore', '~> 0.0.45'
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
