//
//  AEVCopyIntoPasteboardAction.swift
//  YandexMaps
//
//  Created by Alexander Goremykin on 24.05.17.
//  Copyright © 2017 Yandex LLC. All rights reserved.
//

import Foundation
import UIKit

class AEVCopyIntoPasteboardAction: AEVAction {

    // MARK: - Constructors

    init() {
        super.init(name: "Copy Info") { uuid, info, completion in
            var infoString = ""
            infoString += "uuid=\(uuid) "
            infoString += "test_case_id=\(info.identifier) "
            infoString += "start_datetime=\(info.creationTimestamp)"
            UIPasteboard.general.string = infoString

            completion(true)
        }
    }

}
