//
//  ViewController.swift
//  SecureApp
//
//  Created by Pawel Szymanski on 26/03/2021.
//

import UIKit

class ViewController: UIViewController {
    private let secretIdentifier = "##[SECRET:secureApp.secretIdentifier]##"
    
    @IBOutlet var secretLabelFromCode: UILabel!
    @IBOutlet var secretLabelFromSecretsPlist: UILabel!
    @IBOutlet var secretLabelFromInfoPlist: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLabelFromCode()
        setupLabelFromSecretsPlist()
        setupLabelFromInfoPlist()
    }
}

private extension ViewController {
    func setupLabelFromCode() {
        secretLabelFromCode.text = secretIdentifier
    }
    
    func setupLabelFromSecretsPlist() {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let secretValue = NSDictionary(contentsOfFile: path)?.value(forKey: "AnalyticsKey") as? String else {
            fatalError("We really need to get content from Secrets.plist")
        }
        secretLabelFromSecretsPlist.text = secretValue
    }
    
    func setupLabelFromInfoPlist() {
        guard let secretValue = Bundle.main.object(forInfoDictionaryKey: "ApiToken") as? String else {
            fatalError("We really need to get ApiToken from project's Info.plist")
        }
        secretLabelFromInfoPlist.text = secretValue
    }
}

