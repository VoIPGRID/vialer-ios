source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/VoIPGRID/PrivatePodSpecs-iOS.git'

platform :ios, '9.0'
# Uncomment this line if you're using Swift
# use_frameworks!

def default_pods
    pod 'AFNetworkActivityLogger'
    pod 'AFNetworking'
    pod 'Google/Analytics', '~> 1.0.7'
    pod 'HTCopyableLabel'
    pod 'MMDrawerController+Storyboard', :git => 'https://github.com/TomSwift/MMDrawerController-Storyboard.git'
    pod 'PBWebViewController'
    pod 'Reachability'
    pod 'SSKeychain'
    pod 'SimulatorStatusMagic', :configurations => ['Debug']
    pod 'SVProgressHUD'
    pod 'VialerSIPLib-iOS'
end

target 'Vialer' do
    default_pods
end

target 'Voys' do
    default_pods
end

target 'VialerTests' do
    pod 'CocoaLumberjack'
    pod 'OCMock'
    pod 'OHHTTPStubs'
end

post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
            config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
            config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PJ_AUTOCONF=1'
        end
    end
end
