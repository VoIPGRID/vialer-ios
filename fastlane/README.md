fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

## Choose your installation method:

<table width="100%" >
<tr>
<th width="33%"><a href="http://brew.sh">Homebrew</a></td>
<th width="33%">Installer Script</td>
<th width="33%">Rubygems</td>
</tr>
<tr>
<td width="33%" align="center">macOS</td>
<td width="33%" align="center">macOS</td>
<td width="33%" align="center">macOS or Linux with Ruby 2.0.0 or above</td>
</tr>
<tr>
<td width="33%"><code>brew cask install fastlane</code></td>
<td width="33%"><a href="https://download.fastlane.tools">Download the zip file</a>. Then double click on the <code>install</code> script (or run it in a terminal window).</td>
<td width="33%"><code>sudo gem install fastlane -NV</code></td>
</tr>
</table>

# Available Actions
## iOS
### ios prebuild
```
fastlane ios prebuild
```

### ios upload_beta
```
fastlane ios upload_beta
```
Deploy to iTunes Connect
### ios screenshot
```
fastlane ios screenshot
```
Create Screenshots
### ios upload_screenshots
```
fastlane ios upload_screenshots
```
Upload Screenshots
### ios match_development
```
fastlane ios match_development
```
Match Development
### ios match_adhoc
```
fastlane ios match_adhoc
```
Match Adhoc
### ios match_appstore
```
fastlane ios match_appstore
```
Match Appstore
### ios add_device
```
fastlane ios add_device
```

### ios refresh_profiles
```
fastlane ios refresh_profiles
```


----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
