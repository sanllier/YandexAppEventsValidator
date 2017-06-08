//
//  ViewController.swift
//  YandexAppEventsValidatorTestApp
//
//  Created by Alexander Goremykin on 07.06.17.
//
//

import UIKit
import YandexAppEventsValidator

class ViewController: UIViewController {

    var aeValidatingController: AEVController!
    var aeValidationBarController: AEVStatusBarController!
    let button = UIButton()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        aeValidatingController = AEVController(
            uuid: "uuid",
            testCaseIdentifierPreset: "prefix_",
            validationURL: URL(string: "http://www.yandex.ru")!,
            validationToken: "token",
            eventsLogger: self
        )

        aeValidatingController.addListener(self)
    }

    deinit {
        aeValidatingController.removeListener(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(button)
        button.frame = CGRect(x: 0.0, y: 100.0, width: UIScreen.main.bounds.width, height: 100.0)
        button.backgroundColor = .green
        button.setTitle("START", for: .normal)
        button.titleLabel?.textColor = .black

        button.addTarget(self, action: #selector(handleButtonTap(_:)), for: .touchUpInside)

        aeValidationBarController = AEVStatusBarController(container: view, controller: aeValidatingController)
    }

    func handleButtonTap(_ sender: UIButton) {
        if aeValidatingController.currentTestCaseInfo == nil {
            aeValidatingController.startWithAlertPrompt()
        } else {
            aeValidatingController.stopWithAlertPrompt()
        }
    }

}

extension ViewController: AEVControllerListener {

    func appEventsValidatingController(_ controller: AEVController,
                                       didStartRecordingTestCase info: AEVTestCaseInfo)
    {
        button.backgroundColor = .red
        button.setTitle("STOP", for: .normal)
    }

    func appEventsValidatingController(_ controller: AEVController,
                                       didStopRecordingTestCase info: AEVTestCaseInfo)
    {
        button.backgroundColor = .green
        button.setTitle("START", for: .normal)
    }

    func appEventsValidatingController(_ controller: AEVController,
                                       willPerformValidationAction action: AEVAction)
    {

    }

    func appEventsValidatingController(_ controller: AEVController,
                                       didPerformValidationAction action: AEVAction, success: Bool)
    {

    }

}

extension ViewController: AEVControllerEventLogger {

    func reportEvent(_ name: String, parameters: [AnyHashable : Any]) {
        print("[EVENT LOGGER] \(name) \(parameters)")
    }

}
