//
//  AEValidatorStatusBarController.swift
//  YandexMaps
//
//  Created by Alexander Goremykin on 06.06.17.
//  Copyright © 2017 Yandex LLC. All rights reserved.
//

import Foundation

public class AEValidatorStatusBarController {

    // MARK: - Constructors

    public init(container: UIView, controller: AEValidatingController) {
        self.container = container
        self.controller = controller

        controller.addListener(self)

        controller.currentTestCaseInfo.flatMap { info in
            setupStatusViewIfNeeded()
            statusBarView?.title = info.identifier
        }
    }

    deinit {
        controller?.removeListener(self)
    }

    // MARK: - Private Properties

    fileprivate weak var container: UIView?
    fileprivate weak var controller: AEValidatingController?

    fileprivate weak var statusBarView: AEValidatorStatusBarView?

}

extension AEValidatorStatusBarController: AEValidatingControllerListener {

    public func appEventsValidatingController(_ controller: AEValidatingController,
                                              didStartRecordingTestCase info: AEValidatingTestCaseInfo)
    {
        setupStatusViewIfNeeded()
        statusBarView?.title = info.identifier
    }

    public func appEventsValidatingController(_ controller: AEValidatingController,
                                              didStopRecordingTestCase info: AEValidatingTestCaseInfo)
    {

    }

    public func appEventsValidatingController(_ controller: AEValidatingController,
                                              willPerformValidationAction action: AEValidatingAction)
    {
        setupStatusViewIfNeeded()
        statusBarView?.title = "Validating..."
    }

    public func appEventsValidatingController(_ controller: AEValidatingController,
                                              didPerformValidationAction action: AEValidatingAction, successfully: Bool)
    {
        statusBarView?.removeFromSuperview()
    }

}

fileprivate extension AEValidatorStatusBarController {

    fileprivate func setupStatusViewIfNeeded() {
        guard statusBarView == nil, let container = container else { return }

        statusBarView = { (obj: AEValidatorStatusBarView) -> AEValidatorStatusBarView in
            container.addSubview(obj)
            obj.translatesAutoresizingMaskIntoConstraints = false

            [NSLayoutAttribute.top, NSLayoutAttribute.left, NSLayoutAttribute.right].forEach{ attribute in
                container.addConstraint(NSLayoutConstraint(item: obj, attribute: attribute,
                                                           relatedBy: .equal, toItem: container, attribute: attribute,
                                                           multiplier: 1.0, constant: 0.0))
            }

            container.addConstraint(NSLayoutConstraint(item: obj, attribute: .bottom,
                                                       relatedBy: .equal, toItem: container, attribute: .top,
                                                       multiplier: 1.0, constant: 20.0))

            return obj
        }(AEValidatorStatusBarView())
    }

}
