//
//  StartRemoteValidationAction.swift
//  YandexMaps
//
//  Created by Alexander Goremykin on 24.05.17.
//  Copyright © 2017 Yandex LLC. All rights reserved.
//

import Foundation

class StartRemoteValidationAction: AEValidatingAction {

    // MARK: - Constructors

    init(url: URL, token: String) {
        self.url = url
        self.token = token
        super.init(name: "Start Validation")

        block = { [weak self] uuid, info, completion in
            DispatchQueue.global(qos: .background).async {
                sleep(10)

                DispatchQueue.main.async {
                    self?.runValidation(for: uuid, info: info, completion: completion)
                }
            }
        }
    }

    // MARK: - Private Methods

    fileprivate func runValidation(for uuid: String, info: AEValidatingTestCaseInfo, completion: @escaping Completion) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let parameters = ["uuid": uuid,
                          "test_case_id": info.identifier,
                          "start_datetime": info.creationTimestamp,
                          "delay": "0sec",
                          "token": token]
        let parametersString = parameters.map{ (key, value) in return "\(key)=\(value)" }.reduce("", { $0.0 + "&" + $0.1 })
        request.httpBody = parametersString.data(using: .utf8)

        let task = session.dataTask(with: request){ data, response, error in
            completion(error == nil)
        }

        task.resume()
    }

    // MARK: - Private Propetties

    fileprivate let url: URL
    fileprivate let token: String

    fileprivate let session = URLSession(configuration: .default, delegate: nil, delegateQueue: .main)

}
