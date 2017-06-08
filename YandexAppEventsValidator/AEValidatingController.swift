//
//  AEValidatingController.swift
//  YandexMaps
//
//  Created by Alexander Goremykin on 24.05.17.
//  Copyright © 2017 Yandex LLC. All rights reserved.
//

import Foundation
import UIKit

public protocol AEValidatingControllerListener: class {

    func appEventsValidatingController(_ controller: AEValidatingController,
                                       didStartRecordingTestCase info: AEValidatingTestCaseInfo)
    func appEventsValidatingController(_ controller: AEValidatingController,
                                       didStopRecordingTestCase info: AEValidatingTestCaseInfo)

    func appEventsValidatingController(_ controller: AEValidatingController,
                                       willPerformValidationAction action: AEValidatingAction)
    func appEventsValidatingController(_ controller: AEValidatingController,
                                       didPerformValidationAction action: AEValidatingAction, successfully: Bool)

}

public protocol AEValidatingControllerEventLogger: class {

    func reportEvent(_ name: String, from controller: AEValidatingController)

}

public class AEValidatingController: NSObject {

    // MARK: - Public Properties

    static let storedTestCaseKey = "ae_validating_controller.stored_test_case_key"

    struct Events {
        static let onStart = "AppEventsValidatorDidStartRecording"
        static let onStop = "AppEventsValidatorDidStopRecording"
    }
    
    public var currentTestCaseInfo: AEValidatingTestCaseInfo? {
        switch state {
        case .recording(let info): return info
        case .completion(let info): return info
        case .completionError(let info): return info
        default: return nil
        }
    }

    // MARK: - Constructors

    public init(uuid: String, testCaseIdentifierPreset: String = "", eventsLogger: AEValidatingControllerEventLogger) {
        self.uuid = uuid
        self.testCaseIdentifierPreset = testCaseIdentifierPreset
        self.eventsLogger = eventsLogger
        super.init()

        addValidatingAction(CopyIntoPasteboardAction())

        if let savedInfo = UserDefaults.standard.object(forKey: type(of: self).storedTestCaseKey) as? [String: Any] {
            AEValidatingTestCaseInfo(dictionary: savedInfo).flatMap { info in
                startRecording(with: info)
            }
        }
    }

    public convenience init(uuid: String, testCaseIdentifierPreset: String = "",
                            validationURL: URL, validationToken: String,
                            eventsLogger: AEValidatingControllerEventLogger)
    {
        self.init(uuid: uuid, testCaseIdentifierPreset: testCaseIdentifierPreset, eventsLogger: eventsLogger)
        addValidatingAction(StartRemoteValidationAction(url: validationURL, token: validationToken))
    }

    // MARK: - Public

    public func addListener(_ listener: AEValidatingControllerListener) {
        listeners = listeners.filter { $0.impl != nil }
        listeners.append(WeakListener(listener))
    }

    public func removeListener(_ listener: AEValidatingControllerListener) {
        listeners = listeners.filter { $0.impl != nil }
        if let index = listeners.index(where: { $0.impl === listener }) {
            listeners.remove(at: index)
        }
    }

    // MARK: -

    public func addValidatingAction(_ action: AEValidatingAction) {
        validatingActions.append(action)
    }

    // MARK: -

    public func start(testCase: String) {
        guard state.isIdle else {
            assert(false)
            return
        }

        let info = AEValidatingTestCaseInfo(identifier: testCase)
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
    fileprivate weak var eventsLogger: AEValidatingControllerEventLogger?
    
    fileprivate var validatingActions: [AEValidatingAction] = []

    fileprivate var state: State = .idle

    fileprivate var listeners: [WeakListener] = []

}

extension AEValidatingController: UIAlertViewDelegate {

    public func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        switch state {
        case .idle: handleSetupTestCaseAlertButtonClick(alertView: alertView, buttonIndex: buttonIndex)
        case .recording: handleCompletionAlertButtonClick(alertView: alertView, buttonIndex: buttonIndex)
        case .completion: handleCompletionAlertButtonClick(alertView: alertView, buttonIndex: buttonIndex)
        case .completionError: handleAlertButtonClickInCompletionErrorState(alertView: alertView, buttonIndex: buttonIndex)
        }
    }

}

fileprivate extension AEValidatingController {

    fileprivate class WeakListener {

        private(set) weak var impl: AEValidatingControllerListener?

        init(_ impl: AEValidatingControllerListener) {
            self.impl = impl
        }

    }

    // MARK: -

    fileprivate func startRecording(with info: AEValidatingTestCaseInfo) {
        guard state.isIdle else {
            assert(false)
            return
        }

        UserDefaults.standard.set(info.toDictionary(), forKey: type(of: self).storedTestCaseKey)
        state = .recording(info: info)
        listeners.forEach { $0.impl?.appEventsValidatingController(self, didStartRecordingTestCase: info) }
        eventsLogger?.reportEvent(Events.onStart, from: self)
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
            eventsLogger?.reportEvent(Events.onStop, from: self)
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
                        $0.impl?.appEventsValidatingController(slf, didPerformValidationAction: targetAction, successfully: true)
                    }
                } else {
                    self?.state = .completionError(info: currentTestCaseInfo)
                    slf.listeners.forEach{
                        $0.impl?.appEventsValidatingController(slf, didPerformValidationAction: targetAction, successfully: false)
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
