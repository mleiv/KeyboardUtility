//
//  ViewController3.swift
//  KeyboardUtilityDemo
//
//  Created by Emily Ivie on 5/8/15.
//
//

import UIKit

class ViewController3: UIViewController, KeyboardUtilityDelegate {

    @IBOutlet weak var field1: UITextField!
    @IBOutlet weak var field2: UITextField!
    @IBOutlet weak var field3: UITextField!
    @IBOutlet weak var field4: UITextField!
    @IBOutlet weak var field5: UITextField!
    @IBOutlet weak var field6: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    
    lazy var keyboardUtility: KeyboardUtility = {
        return KeyboardUtility(delegate: self)
    }()

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        keyboardUtility.start()
        //If you are using KeyboardUtility with a scroll view, I recommend subclassing your UIScrollView element (inside the storyboard) to KBScrollView, which blocks some of the autoscrolling behavior
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    var textFields: [UITextField] {
        return [
            field1,
            field2,
            field3,
            field4,
            field5,
            field6,
        ]
    }
    
    // Table View Controllers handle keyboard/field visibility on their own,
    // so KeyboardUtility will avoid shifting the screen in this case.

}
