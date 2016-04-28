Vialer
======
Vialer is a VoIP client which utilizes the [VoIPGRID](https://voipgrid.nl) VoIPGRID platform. Up until version 3.0 it's main purpose is to provide an easy interface for the "Two step Calling" function of the platform. This feature enables the user of the app to dial a phone number as if you were "at the office". The receiver sees the "office" number as the calling number (CLI). Using the app, the user can also:
- Adjust it's availability
- See call statistics
- See and adjust dialplans

Starting from Version 3.0 the app also acts as a VoIP softphone, enabling the user to make and receive phone calls using SIP but only when connected to Wi-Fi of 4G.

## Usage
1. Clone the [project's source](https://github.com/VoIPGRID/vialer-ios)
2. Use [Cocoapods](https://guides.cocoapods.org/using/getting-started.html) to install the required libraries
3. Run XCode and start one of the targets

## Technical implementation
The features provided by the app until v3.0 use the platforms API.

Starting with v3.0 the VoIP functionality is provided by using PJSIP. We have wrapped PJSIP into a [cocoapod](https://github.com/VoIPGRID/Vialer-pjsip-iOS) which in turn is used by a [pod](https://github.com/VoIPGRID/VialerSIPLib-iOS) which provides all the SIP functionality.

On an outgoing call the app registers it self with VoIPGRID's sip proxy and after the call has ended the registration is removed. We have deliberately chosen for this registering/deregistering process to avoid "dangling" registrations on the proxy when the phone goes out of proper internet coverage.

On an incoming call, the phone is notified through a silent push notification(APNS). On this notification the internet connection quality is checked and when sufficient a registration with the sip proxy is attempted. When the registration is successful the sip proxy connects with the app and the user is presented with a local notification drawing attention to the incoming call.

To be able to sent the push notifications a piece of "middleware" software has been developed. This middleware is responsible for storing APNS tokens sent to it through a registration process initiated by the app. On an incoming call, the VoIPGRID platform contacts the middleware which will sent the push notification to the correct phone/app. When the conditions for accepting a call have been met, the app responds to the middleware which in turn gives the "OK" back to the VoIPGRID platform. This triggers the sip proxy to contact the app.

## Prerequisites
To be able to use the application you will need an account from one of the VoIPGRID partners

## USED LIBRARIES
The app uses the following 3th party libraries:
- [AFNetworking](https://github.com/AFNetworking/AFNetworking)
- [CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack)
- [HTCopyableLabel](https://github.com/hoteltonight/HTCopyableLabel)
- [MMDrawerController](https://github.com/mutualmobile/MMDrawerController)
- [PBWebViewController](https://github.com/kmikael/PBWebViewController)
- [PJSIP](http://www.pjsip.org)
- [Reachability](https://github.com/tonymillion/Reachability)
- [SSKeychain](https://github.com/soffes/SSKeychain)
- [SVProgressHUD](https://github.com/SVProgressHUD/SVProgressHUD)
