//
//  ColorsConfiguration.swift
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import Foundation

protocol ColorsConfigurationProtocol {
    func colorForKey(_ key: ColorsConfiguration.Colors) -> UIColor
}

@objc class ColorsConfiguration: NSObject, ColorsConfigurationProtocol {

    fileprivate struct PrimaryColors: Decodable {
        var PrimaryBrandColor: [Double]
        var SecondaryBrandColor: [Double]
        var BlackColor: [Double]
        var WhiteColor: [Double]
        var AppleDefaultOffWhite: [Double]
        var WhiteColorWith05Alpha: [Double]
    }

    fileprivate struct TintColors: Decodable {
        var BackgroundGradientStartColor: [Double]
        var BackgroundGradientEndColor: [Double]
        var NumberPadButtonPressedColor: String
        var LogInViewControllerButtonBorderColor: String
        var LogInViewControllerButtonBackgroundColorForPressedState: String
        var ActivateSIPAccountViewControllerButtonBorderColor: String
        var ActivateSIPAccountViewControllerButtonBackgroundColorForPressedState: String
        var NumberPadButtonTextColor: String
        var TabBarBackgroundColor: String
        var TabBarTintColor: String
        var NavigationBarTintColor: String
        var ContactsTableSectionIndexColor: String
        var RecentsSegmentedControlTintColor: String
        var SideMenuTintColor: String
        var SideMenuButtonPressedState: String
        var NavigationBarBarTintColor: String
        var SideMenuHeaderBackgroundColor: String
        var AvailabilityTableViewTintColor: String
        var RecentsTableViewTintColor: String
        var ContactSearchBarTintColor: String
        var ContactSearchBarBarTintColor: String
        var LeftDrawerButtonTintColor: String
        var RecentsFilterControlTintColor: String
        var TwoStepScreenInfoBarBackgroundColor: [Double]
        var TwoStepScreenVialerIconColor: String
        var TwoStepScreenBubblingColor: [Double]
        var TwoStepScreenSideAIconColor: [Double]
        var TwoStepScreenSideBIconColor: String
        var TwoStepScreenBackgroundHeaderColor: String
        var ReachabilityBarBackgroundColor: [Double]
//        var WhiteColor: String //orp
    }

    fileprivate struct Keys: Decodable {
        var primaryColors: PrimaryColors
        var tintColors: TintColors

        private enum CodingKeys: String, CodingKey {
            case primaryColors = "Primary colors"
            case tintColors = "Tint colors"
        }
    }

    @objc enum Colors: Int {
        case numberPadButtonPressed
        case logInViewControllerButtonBorder
        case logInViewControllerButtonBackgroundPressedState
        case activateSIPAccountViewControllerButtonBorder
        case activateSIPAccountViewControllerButtonBackgroundPressedState
        case numberPadButtonText
        case tabBarBackground
        case tabBarTint
        case navigationBarTint
        case contactsTableSectionIndex
        case recentsSegmentedControlTint
        case sideMenuTint
        case sideMenuButtonPressedState
        case navigationBarBarTint
        case sideMenuHeaderBackground
        case availabilityTableViewTint
        case recentsTableViewTint
        case contactSearchBarTint
        case contactSearchBarBarTint
        case leftDrawerButtonTint
        case recentsFilterControlTint
        case twoStepScreenInfoBarBackground
        case twoStepScreenVialerIcon
        case twoStepScreenBubbling
        case twoStepScreenSideAIcon
        case twoStepScreenSideBIcon
        case twoStepScreenBackgroundHeader
        case reachabilityBarBackground
        case backgroundGradientStart
        case backgroundGradientEnd
        case whiteColor
    }

    enum GradientKey {
        case start, end
    }

    @objc static let shared = ColorsConfiguration()

    fileprivate let plistUrl: URL = Bundle.main.url(forResource: "Config", withExtension: "plist")!
    fileprivate var colorsConfig: Keys?

    let backgroundGradientAngle: Float = 300

    private override init() {
        do {
            let data = try Data(contentsOf: plistUrl)
            let decoder = PropertyListDecoder()
            colorsConfig = try decoder.decode(Keys.self, from: data)
        } catch {
            print(error)
        }
    }

    func gradientColors(_ gradientColor: GradientKey) -> UIColor {
        if (colorsConfig != nil) {
            let gradientStartColor = arrayToUIColor(colorsConfig!.tintColors.BackgroundGradientStartColor)
            let gradientEndColor = arrayToUIColor(colorsConfig!.tintColors.BackgroundGradientEndColor)

            if gradientColor == GradientKey.start {
                return gradientStartColor
            }
            return gradientEndColor

        }
        return UIColor.black
    }

    @objc func colorForKey(_ key: Colors) -> UIColor {
        var color = UIColor.black
        switch key {
        case .numberPadButtonPressed:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.NumberPadButtonPressedColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .logInViewControllerButtonBorder:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.LogInViewControllerButtonBorderColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .logInViewControllerButtonBackgroundPressedState:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.LogInViewControllerButtonBackgroundColorForPressedState
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .activateSIPAccountViewControllerButtonBorder:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.ActivateSIPAccountViewControllerButtonBorderColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .activateSIPAccountViewControllerButtonBackgroundPressedState:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.ActivateSIPAccountViewControllerButtonBackgroundColorForPressedState
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .numberPadButtonText:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.NumberPadButtonTextColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .tabBarBackground:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.TabBarBackgroundColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .tabBarTint:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.TabBarTintColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .navigationBarTint:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.NavigationBarTintColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .contactsTableSectionIndex:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.ContactsTableSectionIndexColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .recentsSegmentedControlTint:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.RecentsSegmentedControlTintColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .sideMenuTint:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.SideMenuTintColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .sideMenuButtonPressedState:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.SideMenuButtonPressedState
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .navigationBarBarTint:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.NavigationBarBarTintColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .sideMenuHeaderBackground:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.SideMenuHeaderBackgroundColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .availabilityTableViewTint:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.AvailabilityTableViewTintColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .recentsTableViewTint:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.RecentsTableViewTintColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .contactSearchBarTint:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.ContactSearchBarTintColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .contactSearchBarBarTint:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.ContactSearchBarBarTintColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .leftDrawerButtonTint:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.LeftDrawerButtonTintColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .recentsFilterControlTint:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.RecentsFilterControlTintColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .twoStepScreenInfoBarBackground:
            if colorsConfig != nil {
                color = arrayToUIColor(colorsConfig!.tintColors.TwoStepScreenInfoBarBackgroundColor)
            }
            break
        case .twoStepScreenVialerIcon:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.TwoStepScreenVialerIconColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .twoStepScreenBubbling:
            if colorsConfig != nil {
                color = arrayToUIColor(colorsConfig!.tintColors.TwoStepScreenBubblingColor)
            }
            break
        case .twoStepScreenSideAIcon:
            if colorsConfig != nil {
                color = arrayToUIColor(colorsConfig!.tintColors.TwoStepScreenSideAIconColor)
            }
            break
        case .twoStepScreenSideBIcon:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.TwoStepScreenSideBIconColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .twoStepScreenBackgroundHeader:
            if colorsConfig != nil {
                let linkedTo = colorsConfig!.tintColors.TwoStepScreenBackgroundHeaderColor
                color = arrayToUIColor(stringToPrimaryColor(linkedTo))
            }
            break
        case .backgroundGradientStart:
            if colorsConfig != nil {
                color = arrayToUIColor(colorsConfig!.tintColors.BackgroundGradientStartColor)
            }
            break
        case .backgroundGradientEnd:
            if colorsConfig != nil {
                color = arrayToUIColor(colorsConfig!.tintColors.BackgroundGradientEndColor)
            }
            break
        case .reachabilityBarBackground:
            if colorsConfig != nil {
                color = arrayToUIColor(colorsConfig!.tintColors.ReachabilityBarBackgroundColor)
            }
            break
        case .whiteColor: fallthrough
        default:
            if colorsConfig != nil {
                color = arrayToUIColor(colorsConfig!.primaryColors.WhiteColor)
            }
            break
        }
        return color
    }

    fileprivate func stringToPrimaryColor(_ tintColor: String) -> [Double] {
        switch tintColor {
        case "PrimaryBrandColor":
            return colorsConfig!.primaryColors.PrimaryBrandColor
        case "SecondaryBrandColor":
            return colorsConfig!.primaryColors.SecondaryBrandColor
        case "BlackColor":
            return colorsConfig!.primaryColors.BlackColor
        case "WhiteColor":
            return colorsConfig!.primaryColors.WhiteColor
        case "AppleDefaultOffWhite":
            return colorsConfig!.primaryColors.AppleDefaultOffWhite
        case "WhiteColorWith05Alpha":
            return colorsConfig!.primaryColors.WhiteColorWith05Alpha
        default:
            return colorsConfig!.primaryColors.PrimaryBrandColor
        }
    }

    fileprivate func arrayToUIColor(_ colors: [Double]) -> UIColor {
        if colors.count < 3 {
            return UIColor.black
        }

        var alpha: CGFloat = 1
        if colors.count == 4 {
            alpha = CGFloat(colors[3])
        }

        return UIColor(
            red: CGFloat(colors[0] / 255),
            green: CGFloat(colors[1] / 255),
            blue: CGFloat(colors[2] / 255),
            alpha: alpha
        )
    }


}
