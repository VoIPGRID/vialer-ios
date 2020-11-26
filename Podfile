platform :ios, '11.3'

def default_pods
    source 'https://gitlab.linphone.org/BC/public/podspec.git'
    source 'https://github.com/CocoaPods/Specs.git'
    pod 'AFNetworkActivityLogger'
    pod 'AFNetworking'
    pod 'GoogleAnalytics'
    pod 'Firebase/Core'
    pod 'Firebase/Performance'
    pod 'Firebase/Crashlytics'
    pod 'HTCopyableLabel'
    pod 'le', :git => 'https://github.com/LogentriesCommunity/le_ios.git'
    pod 'MMDrawerController+Storyboard', :git => 'https://github.com/TomSwift/MMDrawerController-Storyboard.git'
    pod 'PBWebViewController'
    pod 'SAMKeychain'
    pod 'SimulatorStatusMagic', :configurations => ['Debug']
    pod 'SPLumberjackLogFormatter', :git => 'https://github.com/VoIPGRID/SPLumberjackLogFormatter.git', :inhibit_warnings => true
    pod 'SVProgressHUD'
     pod 'PhoneLib' ,:git => 'https://github.com/open-voip-alliance/iOSPhoneLib.git', 'branch' => 'develop'
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

target 'ANNAbel' do
    default_pods
end

target 'Vialer Staging' do
    default_pods
end

target 'Voys Staging' do
    default_pods
end

target 'Verbonden Staging' do
  default_pods
end

target 'ANNAbel Staging' do
  default_pods
end

target 'VialerTests' do
    pod 'OCMock'
    pod 'OHHTTPStubs'
    pod 'Firebase'
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

target 'ANNAbelSnapshotUITests' do
    default_pods
end

post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
            config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
            config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'PJ_AUTOCONF=1'
            config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'SV_APP_EXTENSIONS'
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '10.0'
        end
    end
end
