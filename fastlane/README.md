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
### ios build_using_development
```
fastlane ios build_using_development
```
Build App using development certificate for Appcenter
### ios upload_to_appcenter
```
fastlane ios upload_to_appcenter
```
Upload to Appcenter
### ios build_release
```
fastlane ios build_release
```
build a app store release version
### ios upload_to_itunesconnect
```
fastlane ios upload_to_itunesconnect
```
Upload to iTunesConnect

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
