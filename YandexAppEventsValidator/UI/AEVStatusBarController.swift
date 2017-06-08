//
//  AEVStatusBarController.swift
//  YandexMaps
//
//  Created by Alexander Goremykin on 06.06.17.
//  Copyright © 2017 Yandex LLC. All rights reserved.
//

import Foundation

public class AEVStatusBarController {

    // MARK: - Constructors

    public init(container: UIView, controller: AEVController) {
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
    fileprivate weak var controller: AEVController?

    fileprivate weak var statusBarView: AEVStatusBarView?

}

extension AEVStatusBarController: AEVControllerListener {

    public func appEventsValidatingController(_ controller: AEVController,
                                              didStartRecordingTestCase info: AEVTestCaseInfo)
    {
        setupStatusViewIfNeeded()
        statusBarView?.title = info.identifier
    }

    public func appEventsValidatingController(_ controller: AEVController,
                                              didStopRecordingTestCase info: AEVTestCaseInfo)
    {

    }

    public func appEventsValidatingController(_ controller: AEVController,
                                              willPerformValidationAction action: AEVAction)
    {
        setupStatusViewIfNeeded()
        statusBarView?.title = "Validating..."
    }

    public func appEventsValidatingController(_ controller: AEVController,
                                              didPerformValidationAction action: AEVAction, success: Bool)
    {
        statusBarView?.removeFromSuperview()
    }

}

fileprivate extension AEVStatusBarController {

    fileprivate func setupStatusViewIfNeeded() {
        guard statusBarView == nil, let container = container else { return }

        statusBarView = { (obj: AEVStatusBarView) -> AEVStatusBarView in
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
        }(AEVStatusBarView())
    }

}
