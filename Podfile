use_frameworks!


def shared_pod
	pod 'BMSCore', '~> 2.1'
    pod 'BMSAnalyticsAPI', :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics-api.git', :branch => 'development'
end


target 'BMSAnalytics iOS' do
    platform :ios, '9.0'
	shared_pod
end

target 'BMSAnalytics watchOS' do
    platform :watchos, '2.0'
	shared_pod
end

target 'BMSAnalytics Tests' do
    platform :ios, '9.0'
	shared_pod
end

target 'TestApp iOS' do
    platform :ios, '9.0'
	shared_pod
end

target 'TestApp watchOS Extension' do
    platform :watchos, '2.0'
	shared_pod
end
