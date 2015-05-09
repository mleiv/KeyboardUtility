//
//  ViewController1.swift
//  KeyboardUtilityDemo
//
//  Created by Emily Ivie on 4/19/15.
//
//

import UIKit

class ViewController1: UIViewController, KeyboardUtilityDelegate {

    @IBOutlet weak var formLabel: UILabel!
    @IBOutlet weak var formErrorLabel: UILabel!
    @IBOutlet weak var field1: UITextField!
    @IBOutlet weak var field2: UITextField!
    @IBOutlet weak var field3: UITextField!
    @IBOutlet weak var field4: UITextField!
    @IBOutlet weak var field5: UITextField!
    @IBOutlet weak var errorField2Label: UILabel!
    @IBOutlet weak var errorField3Label: UILabel!
    
    // lazy inittialize keyboard utility here:
    lazy var keyboardUtility: KeyboardUtility = {
        return KeyboardUtility(delegate: self)
    }()

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // start keyboard when the view is visible:
        keyboardUtility.start()
    }
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        // stop keyboard when the view is not visible:
        keyboardUtility.stop()
    }

    // require delegate property here:
    var textFields: [UITextField] {
        return [
            field1,
            field2,
            field3,
            field4,
            field5,
        ]
    }
    
    // optional delegate functions here:
    
    func textFieldShouldEndEditing(textField:UITextField) -> Bool {
        // validate the fields here
        if textField == field2 {
            if textField.text.isEmpty {
                errorField2Label.hidden = true
                return true
            } else if let value = textField.text.toInt() {
                errorField2Label.hidden = true
                return true
            } else {
                // error, not a number
                errorField2Label.hidden = false
                return false
            }
        }
        if textField == field3 {
            if textField.text.isEmpty {
                errorField3Label.hidden = true
                return true
            } else if count(textField.text) <= 1 {
                errorField3Label.hidden = true
                return true
            } else {
                // error, too long
                errorField3Label.hidden = false
                return false
            }
        }
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // decide if we are finished with form  here
        if textField == field5 {
            var foundEmptyFields = 0
            for field in textFields {
                if field.text.isEmpty {
                    foundEmptyFields++
                }
            }
            if foundEmptyFields > 0 {
                formErrorLabel.text = "Error: \(foundEmptyFields) Empty Fields"
                formLabel.hidden = true
                formErrorLabel.hidden = false
                return false
            } else {
                formLabel.hidden = false
                formErrorLabel.hidden = true
            }
            //
            // submit form here ...
            //
        }
        return true
    }

}

