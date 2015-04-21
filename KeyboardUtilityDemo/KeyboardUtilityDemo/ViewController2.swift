//
//  ViewController2.swift
//  KeyboardUtilityDemo
//
//  Created by Emily Ivie on 4/19/15.
//
//

import UIKit

class ViewController2: UITableViewController, KeyboardUtilityDelegate {

    @IBOutlet weak var field1: UITextField!
    @IBOutlet weak var field2: UITextField!
    @IBOutlet weak var field3: UITextField!
    @IBOutlet weak var field4: UITextField!
    @IBOutlet weak var field5: UITextField!
    
    lazy var keyboardUtility: KeyboardUtility = {
        return KeyboardUtility(delegate: self)
    }()

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        keyboardUtility.start()
    }
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        keyboardUtility.stop()
    }

    var textFields: [UITextField] {
        var textFields = [UITextField]()
        textFields.append(field1)
        textFields.append(field2)
        textFields.append(field3)
        textFields.append(field4)
        textFields.append(field5)
        return textFields
    }
    
    // Table View Controllers handle keyboard/field visibility on their own,
    // so KeyboardUtility will avoid shifting the screen in this case.

}

