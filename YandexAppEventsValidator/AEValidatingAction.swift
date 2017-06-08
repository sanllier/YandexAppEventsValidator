//
//  AEValidatingAction.swift
//  YandexAppEventsValidator
//
//  Created by Alexander Goremykin on 07.06.17.
//
//

import Foundation

public class AEValidatingAction {

    // MARK: - Public Nested

    public typealias Completion = (_ success: Bool) -> Void
    public typealias Block = (_ uuid: String, _ info: AEValidatingTestCaseInfo, _ completion: @escaping Completion) -> Void

    // MARK: - Public Properties

    public let name: String

    // MARK: - Constructors

    public init(name: String, block: @escaping Block) {
        self.name = name
        self.block = block
    }

    init(name: String) {
        self.name = name
    }

    // MARK: - Internal Methods

    func run(uuid: String, info: AEValidatingTestCaseInfo, completion: @escaping Completion) {
        block?(uuid, info, completion)
    }

    // MARK: - Private Properties

    var block: Block?

}
