//
//  KeyboardUtility.swift
//
//  Copyright 2015 Emily Ivie

//  Licensed under The MIT License
//  For full copyright and license information, please see the LICENSE.txt
//  Redistributions of files must retain the above copyright notice.


import UIKit

//MARK: KeyboardUtilityDelegate Protocol
/**
    Delegate Protocol for implementing KeyboardUtility
    
    Required: properties view and textFields
*/
@objc public protocol KeyboardUtilityDelegate{

//NOTE: @objc required to use optional, and then I can't use any swift-specific types (like Bool? or custom enums, sigh)

    /**
        Return a UIView so utility can locate the top-level UIView (needed for moving page elements)
    
        :returns: self for UIView or self.view for UIViewController
    */
    var view: UIView! { get }
    /**
        Return all form text fields (needed for processing Next/Done according to tag index)
    
        :returns: an array of UITextField objects
    */
    var textFields: [UITextField] { get } //expects field "tag" indexes to order Next/Done
    /**
        Asks the delegate if editing should begin in the specified text field.
    
        :param: textField	The text field for which editing is about to begin.
        :returns: true if an editing session should be initiated; otherwise, false to disallow editing.
    */
    /**
        Processes form when final field (field not marked "Next") is finished.
    */
    func submitForm()
    
    //https://developer.apple.com/library/ios/documentation/UIKit/Reference/UITextFieldDelegate_Protocol/#//apple_ref/occ/intfm/UITextFieldDelegate/
    
    optional func textFieldShouldBeginEditing(textField:UITextField) -> Bool
    /**
        Tells the delegate that editing began for the specified text field.
        (Redirects UITextFieldDelegate back to KeyboardUtilityDelegate so it can share use of this function)
    
        :param: textField	The text field for which an editing session began.
    */
    optional func textFieldDidBeginEditing(textField:UITextField)
    /**
        Asks the delegate if editing should stop in the specified text field.
        VALIDATE FIELD VALUES HERE.
    
        :param: textField	The text field for which editing is about to end.
        :returns: true if editing should stop; otherwise, false if the editing session should continue
    */
    optional func textFieldShouldEndEditing(textField:UITextField) -> Bool
    /**
        Tells the delegate that editing stopped for the specified text field.
        (Redirects UITextFieldDelegate back to KeyboardUtilityDelegate so it can share use of this function)
    
        :param: textField	The text field for which editing ended.
    */
    optional func textFieldDidEndEditing(textField:UITextField)
    /**
        Asks the delegate if the specified text should be changed.
    
        :param: textField       The text field containing the text.
        :param: range           The range of characters to be replaced
        :param: string          The replacement string.
        :returns: true if the specified text range should be replaced; otherwise, false to keep the old text.
    */
    optional func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool
    /**
        Asks the delegate if the text field’s current contents should be removed.
    
        :param: textField       The text field containing the text.
        :returns: true if the text field’s contents should be cleared; otherwise, false.
    */
    optional func textFieldShouldClear(textField:UITextField) -> Bool
    /**
        Asks the delegate if the text field should process the pressing of the return button.
        Overrides/blocks KeyboardUtility from handling textFieldShouldReturn()
    
        :param: textField       The text field whose return button was pressed.
        :returns: true if the text field should implement its default behavior for the return button; otherwise, false.
    */
    optional func textFieldShouldReturnInstead(textField:UITextField) -> Bool
    /**
        Asks the delegate if the text field should process the pressing of the return button.
        (Redirects UITextFieldDelegate back to KeyboardUtilityDelegate so it can share use of this function)
    
        :param: textField       The text field whose return button was pressed.
        :returns: true if the text field should implement its default behavior for the return button; otherwise, false.
    */
    optional func textFieldShouldReturn(textField:UITextField) -> Bool
}


//MARK: KeyboardUtility Class
/**
    Extension to UIView/Controller to better manage text field/keyboard things.
    Automates next/done based on tag index.
    Moves text fields up when keyboard is shown, so they stay visible.
    
    - init(delegate: self)
    - start(): call *AFTER* view has been added to view hierarchy
    - stop(): lets go of all the keyboard tracking listeners
*/
public class KeyboardUtility: NSObject, UITextFieldDelegate {

    public var delegate: KeyboardUtilityDelegate?
    
    /**
        Amount of space between field bottom and keyboard.
    */
    public var keyboardPadding: CGFloat = 0
    
    //calculated at keyboard display or field edit:
    private var topView: UIView?
    private var currentField: UITextField?
    private var keyboardTop: CGFloat?
    private var isTableView = false
    
    private var didStart = false
    
    private var startingOrigin: CGPoint?
    private var offsetY: CGFloat {
        if topView == nil || startingOrigin == nil { return 0 }
        return startingOrigin!.y - topView!.frame.origin.y
    }
    private var offsetX: CGFloat {
        if topView == nil || startingOrigin == nil { return 0 }
        return startingOrigin!.x - topView!.frame.origin.x
    }
    

    init(delegate myDelegate:KeyboardUtilityDelegate) {
        self.delegate = myDelegate
    }
    
    //MARK: initializing listeners
    /**
        Begins listening for keyboard show/hide events and registers for UITextField events.
    */
    public func start() {
        didStart = true
        registerForKeyboardNotifications()
        setTextFieldDelegates()
    }
    
    /**
        Stops listening to keyboard show/hide events.
    */
    public func stop() {
        didStart = false
        deregisterFromKeyboardNotifications()
    }
    
    /**
        Sets up keyboard event listeners for show/hide
    */
    private func registerForKeyboardNotifications(){
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "keyboardWillBeShown:", name: UIKeyboardDidShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    
    /**
        Removes keyboard event listeners for show/hide
    */
    private func deregisterFromKeyboardNotifications(){
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    //MARK: UITextFieldDelegate implementation
    
    /**
        Sets up text field delegate to be self, for every text field sent from KeyboardUtilityDelegate
    */
    private func setTextFieldDelegates() {
        if let textFields = delegate?.textFields{
            for textField in textFields {
                textField.delegate = self
            }
        }
    }

    /**
        DELEGATE FUNCTION Triggered by listener to text field events.
        Allows KeyboardUtilityDelegate control in textFieldShouldBeginEditing()
    */
    public func textFieldShouldBeginEditing(textField:UITextField) -> Bool {
        if let result = delegate?.textFieldShouldBeginEditing?(textField) {
            return result
        }
        return true
    }
    
    /**
        DELEGATE FUNCTION Triggered by listener to text field events.
        Tracks field being edited and calls a second shiftWindowUp() - in addition to the one in 
          the keyboard event listeners - to always keep current text field above keyboard.
        Allows KeyboardUtilityDelegate control in textFieldDidBeginEditing()
    */
    public func textFieldDidBeginEditing(textField: UITextField) {
        if currentField != textField {
            currentField = textField
            //there is a bit of a lag where a black bar appears before keyboard does, so teeny delay helps:
            UIView.animateWithDuration(0.1, animations: { [weak self]() in
                self?.shiftWindowUp()
            })
        }
        delegate?.textFieldDidBeginEditing?(textField)
    }
    
    /**
        DELEGATE FUNCTION Triggered by listener to text field events.
        Allows KeyboardUtilityDelegate control in textFieldShouldEndEditing()
    */
    public func textFieldShouldEndEditing(textField:UITextField) -> Bool {
        if let result = delegate?.textFieldShouldEndEditing?(textField) {
            return result
        }
        return true
    }
    
    /**
        DELEGATE FUNCTION Triggered by listener to text field events.
        Allows KeyboardUtilityDelegate control in textFieldDidEndEditing()
    */
    public func textFieldDidEndEditing(textField:UITextField) {
        delegate?.textFieldDidEndEditing?(textField)
    }
    
    /**
        DELEGATE FUNCTION Triggered by listener to text field events.
        Allows KeyboardUtilityDelegate control in textField()
    */
    public func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if let result = delegate?.textField?(textField, shouldChangeCharactersInRange: range, replacementString: string) {
            return result
        }
        return true
    }
    
    /**
        DELEGATE FUNCTION Triggered by listener to text field events.
        Allows KeyboardUtilityDelegate control in textFieldShouldClear()
    */
    public func textFieldShouldClear(textField:UITextField) -> Bool {
        if let result = delegate?.textFieldShouldClear?(textField) {
            return result
        }
        return true
    }
    
    /**
        DELEGATE FUNCTION Triggered by listener to text field events.
        Handles Next/Done behavior on fields according to tag index.
        Allows KeyboardUtilityDelegate control in textFieldShouldReturn() and textFieldShouldReturnInstead()
    */
    public func textFieldShouldReturn(textField:UITextField) -> Bool {
        var finalResult = true
        if let result = delegate?.textFieldShouldReturnInstead?(textField) {
            // instead of KeyboardUtility:
            return result
        }
        if let result = delegate?.textFieldShouldReturn?(textField) {
            // in addition to KeyboardUtility (could run validation here):
            finalResult = result
        }
        let view = delegate?.view
        if textField.returnKeyType == .Next {
            var next = view?.viewWithTag(textField.tag + 1) as UIResponder?
            if next == nil {
                // try looping back up to field #1
                next = view?.viewWithTag(1) as UIResponder?
            }
            next?.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            delegate?.submitForm()
        }
        return finalResult
    }

    //MARK: Keyboard show/hide calculations
    
    /**
        Triggered by listener to keyboard events.
        Sets keyboard size values for later calculations.
    */
    internal func keyboardWillBeShown (notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let keyboardSize = userInfo[UIKeyboardFrameBeginUserInfoKey]?.CGRectValue().size
            var keyboardHeight = CGFloat(keyboardSize?.height ?? 0)
            keyboardTop = keyboardHeight + keyboardPadding
           //there is a bit of a lag where a black bar appears before keyboard does, so teeny delay helps:
            UIView.animateWithDuration(0.1, animations: { [weak self]() in
                self?.shiftWindowUp()
            })
        }
    }

    /**
        Triggered by listener to keyboard events.
    */
    internal func keyboardWillBeHidden (notification: NSNotification) {
        if keyboardTop != nil {
            shiftWindowDown()
        }
    }
    
    /**
        Moves the main window up to keep the field being edited above the keyboard.
        If this is called when shifting between fields (like with Next), then it only moves
          the field up/down the minimum amount required to keep it above the keyboard.
    */
    private func shiftWindowUp() {
        initTopView()
        if currentField == nil || topView == nil || keyboardTop == nil { return }
        if startingOrigin == nil {
            startingOrigin = topView!.frame.origin
        }
        let distanceToKeyboardTop = topView!.frame.height - keyboardTop!
        var newOffset = distanceToKeyboardTop - getCurrentFieldAbsoluteBottom(currentField!)
        if isTableView {
            // table view manages this itself
            return
        }
        if offsetY != 0 && newOffset != 0 {
            // changing field being edited, window already shifted up for keyboard, so just add the difference:
            newOffset = min(0, newOffset - (-1 * offsetY))
        }
        if newOffset < 0 {
            topView!.frame = CGRectOffset(topView!.frame, 0, newOffset)
        }
    }
    
    /**
        Moves the main window down (called when keyboard is hidden).
        Uses the value set in shiftWindowUp() to determine how to move back to zero.
    */
    private func shiftWindowDown() {
        if topView == nil || startingOrigin == nil { return }
        topView!.frame = CGRectOffset(topView!.frame, offsetX, offsetY)
    }
    
    /**
        Locates top-level view through window (or delegate's view as a fallback), sets a property to hold that value.
    */
    private func initTopView() {
        if topView != nil { return }
        if topView == nil {
            var view = delegate?.view
            while view != nil {
                if view is UITableView {
                    isTableView = true
                    // table view does its own keyboard screen shift, so needs special handling
                }
                topView = view
                view = topView?.superview
            }
        }
    }
    
    /**
        :param: currentField   The field where typing is currently located
        :returns: Y Location of bottom edge of field
    */
    private func getCurrentFieldAbsoluteBottom(currentField: UITextField) -> CGFloat {
        if topView == nil {
            return 0
        }
        var bottom = currentField.frame.size.height
        var lastView = currentField as UIView?
        while let view = lastView {
            bottom += view.frame.origin.y
            lastView = view.superview
            if lastView == topView! {
                break
            }
        }
        return bottom
    }

}