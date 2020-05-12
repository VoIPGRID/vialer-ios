//
//  AvailabilityModel.swift
//  Vialer
//
//  Created by Chris Kontos on 24/04/2019.
//  Copyright © 2019 VoIPGRID. All rights reserved.
//

let AvailabilityModelSelected = "availabilitySelected"
let AvailabilityModelDestinationType = "availabilityType"
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
private let AvailabilityModelFetchInterval: TimeInterval = 5 // number of seconds between fetching of availability

@objc class AvailabilityModel: NSObject {
    @objc var availabilityOptions: NSArray = []
    private var availabilityResourceUri = ""
    
    lazy private var voipgridRequestOperationManager: VoIPGRIDRequestOperationManager = {
        let url = URL(string: UrlsConfiguration.shared.apiUrl())
        return VoIPGRIDRequestOperationManager(baseURL: url)
    }()
    
    @objc func getUserDestinations(_ completion: @escaping (_ localizedErrorString: String?) -> Void) {
        voipgridRequestOperationManager.userDestinations(completion: { operation, responseData, error in
            let localizedStringError = NSLocalizedString("Error getting the availability options", comment: "")
            if error != nil {
                completion(localizedStringError)
            } else {
                if let unwrappedResponseData = responseData as? [String: Any]{
                    if let unwrappedResponseDataObjects = unwrappedResponseData["objects"] as? NSArray {
                        if let unwrappedUserDestinations = unwrappedResponseDataObjects[0] as? NSDictionary {
                            self.userDestinations(toArray: unwrappedUserDestinations)
                            completion(nil)
                        }
                    }
                }
            }
        })
    }
    
    @objc func userDestinations(toArray userDestinations: NSDictionary) {
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
        
        let defaultDict = [SystemUserAvailabilityDescriptionKey: NSLocalizedString("Not available", comment: ""),
                           SystemUserAvailabilityPhoneNumberKey: 0,
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
    
    @objc func createDestinations(_ userDestinations: NSArray?, withDestinationType destinationType: String, withSelectedDestination selectedDestination: NSDictionary?) -> NSArray {
        var phoneNumber: NSNumber?
        let destinations: NSMutableArray = []

        if let unwrappedUserDestinations = userDestinations {
            if unwrappedUserDestinations.count != 0 {
                for userDestination in unwrappedUserDestinations {
                    if let unwrappedUserDestination = userDestination as? NSDictionary {
                        var availabilitySelected = 0
                        
                        if (destinationType == AvailabilityModelSelectedUserDestinationFixedKey) {
                            let numberFormatter = NumberFormatter()
                            phoneNumber = numberFormatter.number(from: unwrappedUserDestination[SystemUserAvailabilityPhoneNumberKey] as? String ?? "")
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
                                if let unwrappedAvailabilityModelDescription = unwrappedUserDestination[AvailabilityModelDescriptionKey]{
                                    SystemUser.current().storeNewAvailability(inSUD: [
                                        SystemUserAvailabilityPhoneNumberKey: phoneNumber as Any,
                                        SystemUserAvailabilityDescriptionKey: unwrappedAvailabilityModelDescription
                                        ])
                                }
                            }
                        }
                    
                        let destination = [
                            AvailabilityModelId: unwrappedUserDestination[AvailabilityModelSelectedUserDestinationIdKey],
                            SystemUserAvailabilityDescriptionKey: unwrappedUserDestination[AvailabilityModelDescriptionKey],
                            SystemUserAvailabilityPhoneNumberKey: phoneNumber,
                            AvailabilityModelSelected: availabilitySelected,
                            AvailabilityModelDestinationType: destinationType
                        ]
                        destinations.add(destination)
                    }
                }
            }
        }
        return destinations
    }
    
    @objc func saveUserDestination(_ index: Int, withCompletion completion: @escaping (_ localizedErrorString: String?) -> Void) {
        let selectedDict = availabilityOptions[index] as? NSDictionary
        var phoneaccount = ""
        var fixedDestination = ""
        
        if (selectedDict?[AvailabilityModelDestinationType] as? String == AvailabilityModelSelectedUserDestinationPhoneaccountKey) {
            phoneaccount = selectedDict?[AvailabilityModelId] as? String ?? ""
        } else if (selectedDict?[AvailabilityModelDestinationType] as? String == AvailabilityModelSelectedUserDestinationFixedKey) {
            fixedDestination = selectedDict?[AvailabilityModelId] as? String ?? ""
        }
        
        let saveDict = [
            AvailabilityModelSelectedUserDestinationPhoneaccountKey: phoneaccount,
            AvailabilityModelSelectedUserDestinationFixedKey: fixedDestination
        ]
        
        voipgridRequestOperationManager.pushSelectedUserDestination(availabilityResourceUri, destinationDict: saveDict, withCompletion: { operation, responseData, error in
            if error != nil {
                let error = NSLocalizedString("Saving availability has failed", comment: "")
                completion(error)
            }
            SystemUser.current().storeNewAvailability(inSUD: selectedDict as? [AnyHashable : Any])
            completion(nil)
        })
    }
    
    @objc func getCurrentAvailability(withBlock completionBlock: @escaping (_ currentAvailability: String?, _ localizedError: String?) -> Void) {
        let currentAvailability = SystemUser.current().currentAvailability
        // Check no availability or outdated.
        if ((currentAvailability?[SystemUserAvailabilityLastFetchKey]) == nil) || abs(Float((currentAvailability?[SystemUserAvailabilityLastFetchKey] as? Date)?.timeIntervalSinceNow ?? 0.0)) > Float(AvailabilityModelFetchInterval) {
            // Fetch new info.
            getUserDestinations({ localizedErrorString in
                if localizedErrorString != nil {
                    completionBlock(nil, localizedErrorString)
                }
                
                if let unwrappedAvailabilityOptions = self.availabilityOptions as? [NSDictionary] {
                    for option: NSDictionary? in unwrappedAvailabilityOptions {
                        // Find current selected.
                        if (option?[AvailabilityModelSelected] as? Int == 1) {
                            //Create string and update SUD.
                            let newAvailabilityString = SystemUser.current().storeNewAvailability(inSUD: option as? [AnyHashable : Any])
                            // Return new string.
                            completionBlock(newAvailabilityString, nil)
                            break
                        }
                    }
                }
            })
        } else {
            // Return existing key.
            if let currentAvailabilityKeyString = currentAvailability?[SystemUserAvailabilityAvailabilityKey] as? String {
                completionBlock(currentAvailabilityKeyString, nil)
            }
        }
    }
}
