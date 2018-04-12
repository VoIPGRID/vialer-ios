platform :ios, '9.0'
# Uncomment this line if you're using Swift
# use_frameworks!

def default_pods
    pod 'AFNetworkActivityLogger', '~> 2.0'
    pod 'AFNetworking/NSURLSession', '~> 2.6'
    pod 'GoogleAnalytics'
    pod 'HTCopyableLabel'
    pod 'le', :git => 'https://github.com/LogentriesCommunity/le_ios.git'
    pod 'MMDrawerController+Storyboard', :git => 'https://github.com/TomSwift/MMDrawerController-Storyboard.git'
    pod 'PBWebViewController'
    pod 'SAMKeychain'
    pod 'SimulatorStatusMagic', :configurations => ['Debug']
    pod 'SPLumberjackLogFormatter', :git => 'https://github.com/VoIPGRID/SPLumberjackLogFormatter.git'
    pod 'SVProgressHUD'
    pod 'VialerSIPLib'
end


target 'Vialer' do
    default_pods
end
target 'Voys' do
    default_pods
end
target 'Verbonden' do
    default_pods
end
target 'Acceptatie' do
    default_pods
end
target 'Acceptatie Voys' do
    default_pods
end

target 'VialerTests' do
    pod 'OCMock'
    pod 'OHHTTPStubs'
end

target 'VialerSnapshotUITests' do
    default_pods
end
target 'VoysSnapshotUITests' do
    default_pods
end
target 'VerbondenSnapshotUITests' do
    default_pods
end

post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
            config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
            config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PJ_AUTOCONF=1'
            config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'SV_APP_EXTENSIONS'
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
        end
    end
end
