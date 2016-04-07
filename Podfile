
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

target 'BMSAnalytics iOS' do
	import_pods_iOS
end

target 'BMSAnalytics watchOS' do
    import_pods_watchOS
end

target 'BMSAnalytics Tests' do
    import_pods_iOS
end

target 'TestApp iOS' do
	import_pods_iOS
end

target 'TestApp watchOS' do

end

target 'TestApp watchOS Extension' do
	import_pods_watchOS
end
