//
//  AvailabilityModel.swift
//  Vialer
//
//  Created by Chris Kontos on 15/10/2018.
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

let AvailabilityModelDescription = "availabilityDescription"
let AvailabilityModelPhoneNumber = "availabilityPhoneNumber"
let AvailabilityModelSelected = "availabilitySelected"
let AvailabilityModelDestinationType = "availabilityType"
let AvailabilityModelPhoneNumberKey = "phonenumber"
let AvailabilityModelId = "availabilityId"

private let AvailabilityModelFixedDestinationsKey = "fixeddestinations"
private let AvailabilityModelPhoneaccountsKey = "phoneaccounts"
private let AvailabilityModelDescriptionKey = "description"
private let AvailabilityModelInternalNumbersKey = "internal_number"
private let AvailabilityModelResourceUriKey = "resource_uri"
private let AvailabilityModelSelectedUserDestinationKey = "selecteduserdestination"
private let AvailabilityModelSelectedUserDestinationPhoneaccountKey = "phoneaccount"
private let AvailabilityModelSelectedUserDestinationFixedKey = "fixeddestination"
private let AvailabilityModelSelectedUserDestinationIdKey = "id"
private let AvailabilityModelLastFetchKey = "AvailabilityModelLastFetchKey"
private let AvailabilityModelAvailabilityKey = "AvailabilityModelAvailabilityKey"

private let AvailabilityModelFetchInterval: TimeInterval = 10 // number of seconds between fetching of availability. Last value used:3600

@objc class AvailabilityModel: NSObject {
    var availabilityOptions: NSArray = []
    private var availabilityResourceUri = ""
    
    lazy private var voipgridRequestOperationManager: VoIPGRIDRequestOperationManager = {
        let url = URL(string: Configuration.init().url(forKey: ConfigurationVoIPGRIDBaseURLString))
        return VoIPGRIDRequestOperationManager(baseURL: url)
    }()
   
    func getUserDestinations(_ completion: @escaping (_ localizedErrorString: String?) -> Void) {
        voipgridRequestOperationManager.userDestinations(completion: { operation, responseData, error in
            // Check if error happened.
            if error != nil {
                let localizedStringError = NSLocalizedString("Error getting the availability options", comment: "")
                completion(localizedStringError)
                return
            }
            // Successful fetch of user destinations.
            if let unwrappedResponseData = responseData as? [String: Any]{
                if let unwrappedResponseDataObjects = unwrappedResponseData["objects"] as? NSArray {
                    if let unwrappedUserDestinations = unwrappedResponseDataObjects[0] as? NSDictionary {
                            self.userDestinations(toArray: unwrappedUserDestinations)
                    }
                }
            }
            completion(nil)
        })
    }
    
    func userDestinations(toArray userDestinations: NSDictionary) {
        let destinations: NSMutableArray = []
        let phoneAccounts = userDestinations[AvailabilityModelPhoneaccountsKey] as? NSArray
        let fixedDestinations = userDestinations[AvailabilityModelFixedDestinationsKey] as? NSArray
        let selectedDestination = userDestinations[AvailabilityModelSelectedUserDestinationKey] as? NSDictionary
        
        var availabilitySelected = 0
        if let phoneAccountDestination = selectedDestination?[AvailabilityModelSelectedUserDestinationPhoneaccountKey], let fixedDestination = selectedDestination?[AvailabilityModelSelectedUserDestinationFixedKey]{
            let strPhoneAccountDestination = String(describing:phoneAccountDestination)
            let strFixedDestination = String(describing:fixedDestination)
            if (strPhoneAccountDestination.isEmpty || strPhoneAccountDestination == "<null>") && (strFixedDestination.isEmpty || strFixedDestination == "<null>") {
                availabilitySelected = 1
            }
        }

        let defaultDict = [AvailabilityModelDescription: NSLocalizedString("Not available", comment: ""),
                           AvailabilityModelPhoneNumberKey: 0,
                           AvailabilityModelSelected: availabilitySelected] as NSDictionary
        destinations.add(defaultDict)
        
        let unwrappedDestinations = createDestinations(phoneAccounts, withDestinationType: AvailabilityModelSelectedUserDestinationPhoneaccountKey, withSelectedDestination: selectedDestination)
        if unwrappedDestinations.count > 0 {
            destinations.addObjects(from: unwrappedDestinations as! [NSDictionary])
        }
            
        let unwrappedFixedDestinations = createDestinations(fixedDestinations, withDestinationType: AvailabilityModelSelectedUserDestinationFixedKey, withSelectedDestination: selectedDestination)
        if unwrappedFixedDestinations.count > 0 {
            destinations.addObjects(from: unwrappedFixedDestinations as! [NSDictionary])
        }
        
        availabilityOptions = destinations
        if let unwrappedSelectedDestination = selectedDestination?[AvailabilityModelResourceUriKey] as? String {
            availabilityResourceUri = unwrappedSelectedDestination
        }
    }
    
    func createDestinations(_ userDestinations: NSArray?, withDestinationType destinationType: String, withSelectedDestination selectedDestination: NSDictionary?) -> NSArray {
        var phoneNumber: NSNumber?
        let destinations: NSMutableArray = []
        if userDestinations?.count != nil {
            if let unwrappedUserDestinations = userDestinations {
                for userDestination in unwrappedUserDestinations {
                    if let unwrappedUserDestination = userDestination as? NSDictionary {
                        var availabilitySelected = 0
                        
                        if (destinationType == AvailabilityModelSelectedUserDestinationFixedKey) {
                            let nsNumberFormatter = NumberFormatter()
                            phoneNumber = nsNumberFormatter.number(from: unwrappedUserDestination[AvailabilityModelPhoneNumberKey] as? String ?? "")
                        } else {
                            phoneNumber = unwrappedUserDestination[AvailabilityModelInternalNumbersKey] as? NSNumber
                        }
                        if let unwrappedSelectedDestination = selectedDestination {
                            // Cast both values to strings. Because of old api code that sent an id as a number and the other as a string.
                            let availabilityDestinationId = String("\(unwrappedUserDestination[AvailabilityModelSelectedUserDestinationIdKey] ?? "")")
                            let selectedDestinationTypeInt = unwrappedSelectedDestination[destinationType]
                            let selectedDestinationType = String("\(selectedDestinationTypeInt ?? "")")
                        
                            if (availabilityDestinationId == selectedDestinationType) {
                                availabilitySelected = 1
                                if let unwrappedAvailabilityDescription = unwrappedUserDestination[AvailabilityModelDescriptionKey] {
                                    _ = storeNewAvialibity(inSUD: [AvailabilityModelPhoneNumberKey: phoneNumber as Any, AvailabilityModelDescription: unwrappedAvailabilityDescription])
                                }
                            }
                        }
                        var destination = NSDictionary()
                        if let aKey = unwrappedUserDestination[AvailabilityModelSelectedUserDestinationIdKey], let aKey1 = unwrappedUserDestination[AvailabilityModelDescriptionKey] {
                            destination = [AvailabilityModelId: aKey,
                                           AvailabilityModelDescription: aKey1,
                                           AvailabilityModelPhoneNumberKey: phoneNumber as Any,
                                           AvailabilityModelSelected: availabilitySelected,
                                           AvailabilityModelDestinationType: destinationType]
                        }
                        destinations.add(destination)
                    }
                }
            }
        }
        return destinations
    }
    
    func saveUserDestination(_ index: Int, withCompletion completion: @escaping (_ localizedErrorString: String?) -> Void) {
        let selectedDict = availabilityOptions[index] as? NSDictionary
        var phoneaccount = ""
        var fixedDestination = ""
        
        if (selectedDict?[AvailabilityModelDestinationType] as? String == AvailabilityModelSelectedUserDestinationPhoneaccountKey) {
            phoneaccount = selectedDict?[AvailabilityModelId] as? String ?? ""
        } else if (selectedDict?[AvailabilityModelDestinationType] as? String == AvailabilityModelSelectedUserDestinationFixedKey) {
            fixedDestination = selectedDict?[AvailabilityModelId] as? String ?? ""
        }
        
        let saveDict = [AvailabilityModelSelectedUserDestinationPhoneaccountKey: phoneaccount, AvailabilityModelSelectedUserDestinationFixedKey: fixedDestination]
        
        voipgridRequestOperationManager.pushSelectedUserDestination(availabilityResourceUri, destinationDict: saveDict, withCompletion: { operation, responseData, error in
            // Check if there was an error.
            if error != nil {
                let error = NSLocalizedString("Saving availability has failed", comment: "")
                completion(error)
            }
            _ = self.storeNewAvialibity(inSUD: selectedDict)
            completion(nil)
        })
    }
    
    @objc func getCurrentAvailability(withBlock completionBlock: @escaping (_ currentAvailability: String?, _ localizedError: String?) -> Void) {
        let currentAvailability = SystemUser.current().currentAvailability
        if currentAvailability?[AvailabilityModelLastFetchKey] == nil || fabs(Float((currentAvailability?[AvailabilityModelLastFetchKey] as? Date)?.timeIntervalSinceNow ?? 0.0)) > Float(AvailabilityModelFetchInterval) {
            getUserDestinations({ localizedErrorString in
                // Error.
                if localizedErrorString != nil {
                    completionBlock(nil, localizedErrorString)
                }
                if let unwrappedAvailabilityOptions = self.availabilityOptions as? [NSDictionary] {
                    for option: NSDictionary? in unwrappedAvailabilityOptions{
                        // Find current selected.
                        if (option?[AvailabilityModelSelected] as? Int == 1) {
                            //Create string and update SUD.
                            let newAvailabilityString = self.storeNewAvialibity(inSUD: option)
                            // Return new string.
                            completionBlock(newAvailabilityString, nil)
                            break
                        }
                    }
                }
            })
        } else {
            let unwrappedExistingKey = currentAvailability?[AvailabilityModelAvailabilityKey] as? String
            completionBlock(unwrappedExistingKey, nil)
        }
    }
    
    func storeNewAvialibity(inSUD option: NSDictionary?) -> String? {
        var newAvailabilityString: String
        if let unwrappedPhoneNumberKey = option?[AvailabilityModelPhoneNumberKey] as? Int {
            if !(unwrappedPhoneNumberKey == 0) {
                var phoneNumber = String(unwrappedPhoneNumberKey)
                if phoneNumber.count > 5 {
                    phoneNumber = "+" + (phoneNumber)
                }
                newAvailabilityString = "\(phoneNumber) / \(option?[AvailabilityModelDescription] ?? "")"
            } else {
                newAvailabilityString = NSLocalizedString("Not available", comment: "")
            }
            
            let currentAvailability = [AvailabilityModelLastFetchKey: Date(), AvailabilityModelAvailabilityKey: newAvailabilityString] as [String : Any]
            SystemUser.current().currentAvailability = currentAvailability
            return newAvailabilityString
        }
        return nil
    }
}
