//
//  AEVController.swift
//  YandexMaps
//
//  Created by Alexander Goremykin on 24.05.17.
//  Copyright © 2017 Yandex LLC. All rights reserved.
//

import Foundation
import UIKit

public protocol AEVControllerListener: class {

    func appEventsValidatingController(_ controller: AEVController, didStartRecordingTestCase info: AEVTestCaseInfo)
    func appEventsValidatingController(_ controller: AEVController, didStopRecordingTestCase info: AEVTestCaseInfo)

    func appEventsValidatingController(_ controller: AEVController, willPerformValidationAction action: AEVAction)
    func appEventsValidatingController(_ controller: AEVController, didPerformValidationAction action: AEVAction, success: Bool)

}

public protocol AEVControllerEventLogger: class {

    func reportEvent(_ name: String, parameters: [AnyHashable: Any])

}

public class AEVController: NSObject {

    // MARK: - Public Properties

    static let storedTestCaseKey = "ae_validating_controller.stored_test_case_key"

    struct Events {
        static let onStart = "application.start-test-case-record"
        static let onStop = "application.end-test-case-record"

        struct Parameters {
            static let testCaseId = "test_case_id"
            static let testCaseStartDatetime = "start_datetime"
        }
    }

    public var currentTestCaseInfo: AEVTestCaseInfo? {
        switch state {
        case .recording(let info): return info
        case .completion(let info): return info
        case .completionError(let info): return info
        default: return nil
        }
    }

    // MARK: - Constructors

    public init(uuid: String, testCaseIdentifierPreset: String = "", eventsLogger: AEVControllerEventLogger) {
        self.uuid = uuid
        self.testCaseIdentifierPreset = testCaseIdentifierPreset
        self.eventsLogger = eventsLogger

        super.init()

        addValidatingAction(AEVCopyIntoPasteboardAction())

        if let savedInfo = UserDefaults.standard.object(forKey: type(of: self).storedTestCaseKey) as? [String: Any] {
            AEVTestCaseInfo(dictionary: savedInfo).flatMap { info in
                startRecording(with: info)
            }
        }
    }

    public convenience init(uuid: String, testCaseIdentifierPreset: String = "",
                            validationURL: URL, validationToken: String,
                            eventsLogger: AEVControllerEventLogger)
    {
        self.init(uuid: uuid, testCaseIdentifierPreset: testCaseIdentifierPreset, eventsLogger: eventsLogger)
        addValidatingAction(AEVStartRemoteValidationAction(url: validationURL, token: validationToken))
    }

    // MARK: - Public

    public func addListener(_ listener: AEVControllerListener) {
        listeners = listeners.filter { $0.impl != nil }
        listeners.append(WeakListener(listener))
    }

    public func removeListener(_ listener: AEVControllerListener) {
        listeners = listeners.filter { $0.impl != nil }
        if let index = listeners.index(where: { $0.impl === listener }) {
            listeners.remove(at: index)
        }
    }

    // MARK: -

    public func addValidatingAction(_ action: AEVAction) {
        validatingActions.append(action)
    }

    // MARK: -

    public func start(testCase: String) {
        guard state.isIdle else {
            assert(false)
            return
        }

        let info = AEVTestCaseInfo(identifier: testCase)
        startRecording(with: info)
    }

    public func startWithAlertPrompt() {
        guard state.isIdle else {
            assert(false)
            return
        }

        if state.isCompletion {
            showCompletionStillRunningAlert()
        } else {
            let alert = UIAlertView(title: "Test Case", message: "Enter test case identifier", delegate: self,
                                    cancelButtonTitle: "Run", otherButtonTitles: "Close")
            alert.alertViewStyle = .plainTextInput
            alert.textField(at: 0)?.text = testCaseIdentifierPreset
            alert.show()
        }
    }

    public func stopWithAlertPrompt() {
        if state.isCompletion {
            showCompletionStillRunningAlert()
            return
        }

        guard state.isRecording else {
            assert(false)
            return
        }

        showCompletionAlert()
    }

    // MARK: - Private Properties

    fileprivate let uuid: String
    fileprivate let testCaseIdentifierPreset: String
    fileprivate weak var eventsLogger: AEVControllerEventLogger?
    
    fileprivate var validatingActions: [AEVAction] = []

    fileprivate var state: State = .idle

    fileprivate var listeners: [WeakListener] = []

}

extension AEVController: UIAlertViewDelegate {

    public func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        switch state {
        case .idle: handleSetupTestCaseAlertButtonClick(alertView: alertView, buttonIndex: buttonIndex)
        case .recording: handleCompletionAlertButtonClick(alertView: alertView, buttonIndex: buttonIndex)
        case .completion: handleCompletionAlertButtonClick(alertView: alertView, buttonIndex: buttonIndex)
        case .completionError: handleAlertButtonClickInCompletionErrorState(alertView: alertView, buttonIndex: buttonIndex)
        }
    }

}

fileprivate extension AEVController {

    fileprivate class WeakListener {

        private(set) weak var impl: AEVControllerListener?

        init(_ impl: AEVControllerListener) {
            self.impl = impl
        }

    }

    // MARK: -

    fileprivate func startRecording(with info: AEVTestCaseInfo) {
        guard state.isIdle else {
            assert(false)
            return
        }

        UserDefaults.standard.set(info.toDictionary(), forKey: type(of: self).storedTestCaseKey)
        state = .recording(info: info)
        listeners.forEach { $0.impl?.appEventsValidatingController(self, didStartRecordingTestCase: info) }
        eventsLogger?.reportEvent(
            Events.onStart,
            parameters: [
                Events.Parameters.testCaseId: info.identifier,
                Events.Parameters.testCaseStartDatetime: info.creationTimestamp
            ]
        )
    }

    fileprivate func resetState() {
        state = .idle
        UserDefaults.standard.removeObject(forKey: type(of: self).storedTestCaseKey)
    }

    // MARK: -

    fileprivate func handleSetupTestCaseAlertButtonClick(alertView: UIAlertView, buttonIndex: Int) {
        guard state.isIdle else {
            assert(false)
            return
        }

        if buttonIndex == 0 {
            if let text = alertView.textField(at: 0)?.text, !text.isEmpty && text != testCaseIdentifierPreset {
                start(testCase: text)
            }
        } else if buttonIndex == 1 {
            return
        } else {
            assert(false)
        }
    }

    fileprivate func handleCompletionAlertButtonClick(alertView: UIAlertView, buttonIndex: Int) {
        guard let currentTestCaseInfo = currentTestCaseInfo, state.isRecording || state.isCompletion else {
            assert(false)
            return
        }

        if buttonIndex >= validatingActions.count {
            if state.isCompletion {
                resetState()
            }

            return
        }

        if state.isRecording {
            listeners.forEach { $0.impl?.appEventsValidatingController(self, didStopRecordingTestCase: currentTestCaseInfo) }
            eventsLogger?.reportEvent(
                Events.onStop,
                parameters: [
                    Events.Parameters.testCaseId: currentTestCaseInfo.identifier,
                    Events.Parameters.testCaseStartDatetime: currentTestCaseInfo.creationTimestamp
                ]
            )
        }

        let targetAction = validatingActions[buttonIndex]

        listeners.forEach{ $0.impl?.appEventsValidatingController(self, willPerformValidationAction: targetAction) }

        state = .completion(info: currentTestCaseInfo)
        targetAction.run(
            uuid: uuid,
            info: currentTestCaseInfo,
            completion: { [weak self] success in
                guard let slf = self else { return }

                if success {
                    slf.resetState()
                    slf.listeners.forEach{
                        $0.impl?.appEventsValidatingController(slf, didPerformValidationAction: targetAction, success: true)
                    }
                } else {
                    self?.state = .completionError(info: currentTestCaseInfo)
                    slf.listeners.forEach{
                        $0.impl?.appEventsValidatingController(slf, didPerformValidationAction: targetAction, success: false)
                    }

                    let alert: UIAlertView
                    alert = UIAlertView(title: "Test Case", message: "Completion Error", delegate: self,
                                        cancelButtonTitle: "Retry", otherButtonTitles: "Close")
                    alert.show()
                }
            }
        )
    }

    fileprivate func handleAlertButtonClickInCompletionErrorState(alertView: UIAlertView, buttonIndex: Int) {
        guard let currentTestCaseInfo = currentTestCaseInfo, state.isCompletionError else {
            assert(false)
            return
        }

        if buttonIndex == 0 {
            state = .completion(info: currentTestCaseInfo)
            showCompletionAlert()
        } else if buttonIndex == 1 {
            resetState()
        } else {
            assert(false)
        }
    }

    // MARK: -

    fileprivate func showCompletionAlert() {
        let alert = UIAlertView(title: "Test Case", message: "Completion Option", delegate: self, cancelButtonTitle: nil)
        validatingActions.forEach {
            alert.addButton(withTitle: $0.name)
        }

        alert.addButton(withTitle: "Cancel")
        alert.cancelButtonIndex = alert.numberOfButtons - 1

        alert.show()
    }

    fileprivate func showCompletionStillRunningAlert() {
        UIAlertView(title: "Test Case", message: "Completion Still Running",
                    delegate: nil, cancelButtonTitle: "Close").show()
    }

}
