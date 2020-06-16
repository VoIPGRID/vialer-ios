//
//  SubmitFeedbackController.swift
//  Vialer
//
//  Created by Jeremy Norman on 15/06/2020.
//  Copyright © 2020 VoIPGRID. All rights reserved.
//

import Foundation
import UIKit

class SubmitFeedbackController: UIViewController, UITextViewDelegate, NSURLConnectionDataDelegate {
    @IBOutlet weak var feedbackContainer: UITextView!
    @IBOutlet weak var submitButton: UIButton!
    
    @IBAction func submitButtonPressed(_ sender: Any) {
        guard let user = SystemUser.current() else { return }
        submitButton.isEnabled = false

        let query: [String: Any] = [
            "message" : feedbackContainer.text ?? "",
            "user"    : [
                "id" : user.uuid,
                "email_address" : user.username,
                "given_name" : user.firstName,
                "family_name" : user.lastName,
            ],
            "application" : [
                "id" : Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String,
                "version" : AppInfo.currentAppVersion(),
                "os" : "ios",
                "os_version" : UIDevice.current.systemVersion,
                "device_info" : UIDevice.current.modelName
            ]
        ]

        let request = URLRequest.postJson(url: "https://feedback.spindle.dev/v1/feedback/app", json: query)

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in

            self.submitButton.isEnabled = true

            if let error = error {
                VialerLogError("Error took place \(error)")
                DispatchQueue.main.async {
                    self.present(self.createErrorAlert(), animated: true, completion: nil)
                }
                return
            }

            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.present(self.createCompletionAlert(), animated: true, completion: nil)
                }
            }
        }

        task.resume()
    }

    func textViewDidChange(_ textView: UITextView) {
        submitButton.isEnabled = !textView.text.isEmpty
    }

    func createErrorAlert() -> UIAlertController {
        let alert = UIAlertController(title: NSLocalizedString("Unable to submit feedback at this time", comment: ""), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
        }))
        return alert
    }

    func createCompletionAlert() -> UIAlertController {
        let alert = UIAlertController(title: NSLocalizedString("Feedback Submitted!", comment: ""), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        return alert
    }

}

extension URLRequest {

    static func postJson(url: String, json: Any) -> URLRequest {
        guard let url = URL(string: url) else { fatalError() }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: json)
        return request
    }

}