//
//  ReviewManager.swift
//  Vialer
//
//  Created by Chris Kontos on 22/05/2020.
//  Copyright © 2020 VoIPGRID. All rights reserved.
//

import StoreKit

@available(iOS 10.3, *)
enum ReviewManager {
    static let reviewWorthyActionCount = "ReviewWorthyActionCount"
    static let lastReviewRequestAppVersion = "LastReviewRequestAppVersion"
    static let minimumReviewWorthyActionCount = 3

    /// Ask from user to rate/review the app after minimumReviewWorthyActionCount.
    static func requestReviewIfAppropriate() {
      let defaults = UserDefaults.standard
      let bundle = Bundle.main

      var actionCount = defaults.integer(forKey: reviewWorthyActionCount)
      actionCount += 1
      defaults.set(actionCount, forKey: reviewWorthyActionCount)

      guard actionCount >= minimumReviewWorthyActionCount else {
        return
      }

      let bundleVersionKey = kCFBundleVersionKey as String
      let currentVersion = bundle.object(forInfoDictionaryKey: bundleVersionKey) as? String
      let lastVersion = defaults.string(forKey: lastReviewRequestAppVersion)

      guard lastVersion == nil || lastVersion != currentVersion else {
        return
      }

      SKStoreReviewController.requestReview()

      defaults.set(0, forKey: reviewWorthyActionCount)
      defaults.set(currentVersion, forKey: lastReviewRequestAppVersion)
    }
}
