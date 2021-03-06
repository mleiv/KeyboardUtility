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
        keyboardUtility.dontShiftForKeyboard = true
        //it is recommended that you disable keyboard shifting for UITableViewControllers, as they have their own autoscroll that interferes with KeyboardUtility. If you do want to override that, I recommend subclassing you UITableView element (inside the storyboard) to KBTableView, which blocks some of the autoscrolling behavior
        keyboardUtility.start()
    }
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        keyboardUtility.stop()
    }

    var textFields: [UITextField] {
        return [
            field1,
            field2,
            field3,
            field4,
            field5,
        ]
    }
    
    // Table View Controllers handle keyboard/field visibility on their own,
    // so KeyboardUtility will avoid shifting the screen in this case.

}

