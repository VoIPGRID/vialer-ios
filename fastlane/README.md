fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios beta
```
fastlane ios beta
```
Upload beta to Testflight
### ios screenshot
```
fastlane ios screenshot
```
Create Screenshots without uploading
### ios upload_screenshots
```
fastlane ios upload_screenshots
```
Upload Screenshots to the iTunes Connect store
### ios sync_development_certs
```
fastlane ios sync_development_certs
```
Synchronize DEVELOPMENT certificates with itunes connect
### ios sync_adhoc_certs
```
fastlane ios sync_adhoc_certs
```
Synchronize ADHOC certificates with itunes connect
### ios sync_appstore_certs
```
fastlane ios sync_appstore_certs
```
Synchronize APPSTORE certificates with itunes connect
### ios add_device
```
fastlane ios add_device
```


----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
