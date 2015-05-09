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
        Return all form text fields (needed for processing Next/Done according to tag index)
    
        :returns: an array of UITextField objects
    */
    var textFields: [UITextField] { get } //expects field "tag" indexes to order Next/Done
    
    /**
        Processes form when final field (field not marked "Next") is finished.
    */
    optional func submitForm()
    
    //https://developer.apple.com/library/ios/documentation/UIKit/Reference/UITextFieldDelegate_Protocol/#//apple_ref/occ/intfm/UITextFieldDelegate/
    
    /**
        Asks the delegate if editing should begin in the specified text field.
    
        :param: textField	The text field for which editing is about to begin.
        :returns: true if an editing session should be initiated; otherwise, false to disallow editing.
    */
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
public class KeyboardUtility: NSObject, UITextFieldDelegate, UIScrollViewDelegate {

    public var delegate: KeyboardUtilityDelegate?
    
    /**
        Allows a UITableViewController to use other keyboard utilities without using the keyboard shift (since table view has its own built-in version)
    */
    public var dontShiftForKeyboard = false
    /**
        Amount of space between field bottom and keyboard.
    */
    public var keyboardPadding: CGFloat = 0
    
    /**
        Amount of time to delay shifting window.
    */
    public var animationDelay: NSTimeInterval = 0.2
    
    // calculated at keyboard display or field edit:
    private weak var topController: UIViewController?
    private var currentField: UITextField?
    private var keyboardTop: CGFloat?
    private var isTableView = false
    
    // some placement values to save so things go back to normal when keyboard closed
    private var onloadOrigin: CGPoint?
    private var startingOrigin: CGPoint?
    private var offsetY: CGFloat {
        if topController?.view == nil || startingOrigin == nil { return 0 }
        return startingOrigin!.y - topController!.view.frame.origin.y
    }
    private var offsetX: CGFloat {
        if topController?.view == nil || startingOrigin == nil { return 0 }
        return startingOrigin!.x - topController!.view.frame.origin.x
    }
    private var scrollViewOriginalValues = [(UIView, CGPoint, UIEdgeInsets)]()
    
    // short-term storage to correct for bad apple autoscroll (use KBScrollView for better results)
    private var scrollViewLastSetValues = [(UIView, CGPoint, UIEdgeInsets)]()
    
    // track if keyboard utility is on
    private var isRunning = false
    
    init(delegate myDelegate:KeyboardUtilityDelegate) {
        self.delegate = myDelegate
    }
    
    //MARK: Listeners
    /**
        Begins listening for keyboard show/hide events and registers for UITextField events.
    */
    public func start() {
        isRunning = true
        
        topController = topViewController()
        onloadOrigin = topController?.view.frame.origin
        
        registerForKeyboardNotifications()
        setTextFieldDelegates()
    }
    
    /**
        Stops listening to keyboard show/hide events.
    */
    public func stop() {
        isRunning = false
        deregisterFromKeyboardNotifications()
    }
    
    /**
        Sets up keyboard event listeners for show/hide
    */
    private func registerForKeyboardNotifications() {
        if dontShiftForKeyboard {
            return
        }
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "keyboardWillBeShown:", name: UIKeyboardDidShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "keyboardWillBeHidden:", name: UIKeyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: "keyboardWasHidden:", name: UIKeyboardDidHideNotification, object: nil)
    }
    
    /**
        Removes keyboard event listeners for show/hide
    */
    private func deregisterFromKeyboardNotifications() {
        if dontShiftForKeyboard {
            return
        }
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIKeyboardDidHideNotification, object: nil)
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
        Saves initial positioning data for returning to that state when keyboard is closed.
        Allows KeyboardUtilityDelegate control in textFieldShouldBeginEditing()
    */
    public func textFieldShouldBeginEditing(textField:UITextField) -> Bool {
        //do this before keyboard is opened or anything else is called:
        saveInitialValues(fromView: textField as UIView)
        
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
            let priorCurrentField = (currentField != nil)
            currentField = textField
            if priorCurrentField {
                animateWindowShift()
            } // else leave to keyboard opener
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
        let view = topController?.view
        if textField.returnKeyType == .Next {
            var next = view?.viewWithTag(textField.tag + 1) as UIResponder?
            if next == nil {
                // try looping back up to field #1
                next = view?.viewWithTag(1) as UIResponder?
            }
            next?.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            delegate?.submitForm?()
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
            if currentField != nil {
                animateWindowShift()
            }
        }
    }

    /**
        Triggered by listener to keyboard events.
        Restores positioning to state before keyboard opened.
    */
    internal func keyboardWillBeHidden (notification: NSNotification) {
        restoreInitialValues()
        currentField = nil
    }
    
    /**
        Triggered by listener to keyboard events.
        Restores positioning to state before keyboard opened.
    */
    internal func keyboardWasHidden (notification: NSNotification) {
        restoreInitialScrollableValues(isFinal: true) // scroll views are stubborn: force them to be the right value
        currentField = nil
    }
    
    /**
        Animates the window sliding up to look nicer. Also forces any scroll views we didn't fix to behave properly.
    */
    private func animateWindowShift() {
        if dontShiftForKeyboard {
            return
        }
        // Reset all the base scroll view values or we will start seeing black bars of unknown source:
        for values in scrollViewOriginalValues {
            setScrollableValues(values)
        }
        //there is a bit of a lag where a black bar below top view appears before keyboard does, so teeny delay helps:
        UIView.animateWithDuration(animationDelay, animations: { [weak self]() in
            self?.scrollViewLastSetValues = [] //reset
            self?.shiftWindowUp()
        }, completion: { [weak self](finished) in
            // wrestle positoning control from Apple for scroll views. Better solution: use KBScrollView class and this won't be called.
            for values in self!.scrollViewLastSetValues {
                self?.setScrollableValues(values)
            }
        })
    }
    
    /**
        Moves the main window up to keep the field being edited above the keyboard.
        If this is called when shifting between fields (like with Next), then it only moves
          the field up/down the minimum amount required to keep it above the keyboard.
    */
    private func shiftWindowUp() {
        if currentField == nil || topController?.view == nil || keyboardTop == nil { return }
        // calculate necessary height adjustment (minus scroll adjustments):
        var fieldHeight = currentField!.bounds.height + keyboardPadding
        var lastView = currentField as UIView?
        var bottom = fieldHeight
        while let view = lastView {
            bottom += view.frame.origin.y
            if let scrollableView = view as? UITableView ?? view as? UIScrollView {
                // note: we've already accounted for frame origin y above
                // now we just need to make sure field is within visible scroll area
                // and adjust bottom to account for scrolled area
                var savedInset = scrollableView.contentInset
                var savedOffset = scrollableView.contentOffset
                let scrollTopY = savedOffset.y + savedInset.top
                let scrollBottomY = scrollTopY + scrollableView.bounds.height - savedInset.top
                let overage: CGFloat = {
                    if bottom - fieldHeight < scrollTopY {
                        // content above current top
                        return (bottom - fieldHeight) - scrollTopY
                    } else if bottom > scrollBottomY {
                        // content below current bottom
                        return bottom - scrollBottomY
                    }
                    return CGFloat(0)
                }()
                if overage != 0 {
                    savedOffset.y += overage
                    savedInset.top -= overage
                }
                // because scroll happens automatically on UITextField selection, decide if we need to set values now or AFTER autoscroll (the wrong scroll) happens:
                if doesntNeedForcedPositioning(view) {
                    setScrollableValues((view: view, offset: savedOffset, inset: savedInset), animated: true)
                } else {
                    //the painful route of repeatedly forcing offset/inset
                    scrollViewLastSetValues.append((scrollableView, savedOffset, savedInset))
                }
                bottom -= savedOffset.y
            }
            if view == topController?.view {
                break
            }
            lastView = view.superview
        }
        // now, move main frame up if necessary:
        let distanceToKeyboardTop = topController!.view.bounds.height - keyboardTop!
        var newOffset = distanceToKeyboardTop - bottom
        if newOffset != 0 {
            // don't go too far though, or we will see a black bar of nothingness:
            topController!.view.frame.origin.y = min(startingOrigin?.y ?? 0, topController!.view.frame.origin.y + newOffset)
        }
    }
    
    //MARK: Scrolling Corrections
    
    /**
        Because some scroll views might be in one field's hierarchy but not another's, this allows us to add any new scroll views that might have showed up between "Next" fields.
        
        :param: scrollView      The view to add if it is not already in the list
    */
    private func addUniqueToScrollOriginals(view: UIView) {
        for (existingView, offset, inset) in scrollViewOriginalValues {
            if existingView == view {
                return
            }
        }
        if let scrollableView = view as? UITableView ?? view as? UIScrollView  {
            scrollViewOriginalValues.append((scrollableView, scrollableView.contentOffset, scrollableView.contentInset))
        }
    }
    
    /**
        Saves original placement state of any views that might be altered
    
        :param: fromView    the initial view to begin looking in (goes up the hierarchy, so start with the field if possible)
    */
    private func saveInitialValues(fromView: UIView? = nil) {
        if startingOrigin == nil {
            startingOrigin = topController?.view.frame.origin
        }
        var view = fromView
        while view != nil {
            if let scrollableView = view as? UITableView ?? view as? UIScrollView {
                addUniqueToScrollOriginals(scrollableView)
            }
            if view == topController?.view {
                break
            }
            view = view?.superview
        }
    }
    
    /**
        Restores original placement state of any views that might have been altered
    */
    private func restoreInitialValues() {
        // reset top frame offset to saved value:
        if startingOrigin != nil && topController != nil {
            topController!.view.frame.origin = startingOrigin!
            startingOrigin = nil
        }
        restoreInitialScrollableValues()
    }
    
    /**
        Restores just the saved scroll views' placement.
        This runs twice if we aren't using our subclassed scroll elements to disable autoscrolling.
        
        :param: isFinal    If true, erases the list of saved positioning values when done
    */
    private func restoreInitialScrollableValues(isFinal: Bool = false) {
        // reset scroll views to saved values:
        var runTwice = false
        for values in scrollViewOriginalValues {
            setScrollableValues(values, animated: true)
            if !doesntNeedForcedPositioning(values.0) {
                runTwice = true
            }
        }
        if !runTwice || isFinal {
            scrollViewOriginalValues = []
        }
    }
    
    
    /**
        Checks to see if the view is one of our subclassed scroll elements to disable autoscrolling.
        
        :param: view    the scrollable view
    */
    private func doesntNeedForcedPositioning(view: UIView) -> Bool {
        return view is KBScrollView || view is KBTableView
    }
    
    /**
        Stops all offset-related autoscrolling animations on the element in question
        
        :param: view    the scrollable view
    */
    private func stopScroll(view: UIView) {
        if let scrollableView = view as? UITableView ?? view as? UIScrollView  {
            var offset = scrollableView.contentOffset
            offset.x -= 1.0; offset.y -= 1.0
            scrollableView.setContentOffset(offset, animated: false)
            offset.x += 1.0; offset.y += 1.0
            scrollableView.setContentOffset(offset, animated: false)
        }
    }
    
    /**
        Sets the inset/offset values of a scrollable element if they have changed.
        Stops any existing autoscrolling animations if this is an autoscrolling element.
        
        :param: values      a tuple of view, offset, and inset
        :param: animated    true if the offset should be set to animate its changed value
    */
    private func setScrollableValues(values: (view: UIView, offset: CGPoint, inset: UIEdgeInsets), var animated: Bool = false) {
        // reset scroll views to saved values:
        if let scrollableView = values.view as? UITableView ?? values.view as? UIScrollView  {
            if !doesntNeedForcedPositioning(scrollableView) {
                stopScroll(scrollableView)
                animated = false
            }
            if scrollableView.contentInset.top != values.inset.top || scrollableView.contentInset.bottom != values.inset.bottom {
                scrollableView.contentInset = values.inset
                scrollableView.scrollIndicatorInsets = values.inset
            }
            if scrollableView.contentOffset.y != values.offset.y {
                scrollableView.setContentOffset(values.offset, animated: animated)
            }
        }
    }
    
    //MARK: Top ViewController
    
    /**
        Locates the top-most view controller that is under the tab/nav controllers
        
        :param: topController   (optional) view controller to start looking under, defaults to window's rootViewController
        :returns: an (optional) view controller
    */
    private func topViewController(_ topController: UIViewController? = nil) -> UIViewController? {
        let controller: UIViewController? = {
            if let controller = topController ?? UIApplication.sharedApplication().keyWindow?.rootViewController {
                return controller
            } else if let window = UIApplication.sharedApplication().delegate?.window {
                //this is only called if window.makeKeyAndVisible() didn't happen...?
                return window?.rootViewController
            }
            return nil
        }()
        if let tabController = controller as? UITabBarController, let nextController = tabController.selectedViewController {
            return topViewController(nextController)
        } else if let navController = controller as? UINavigationController, let nextController = navController.visibleViewController {
            return topViewController(nextController)
        } else if let nextController = controller?.presentedViewController {
            return topViewController(nextController)
        }
        return controller
    }
}

//MARK: Subclasses Disabling Autoscroll

/**
    A UIScrollView with disabled autoscroll behavior
*/
class KBScrollView: UIScrollView {
    // Stops scroll view from trying to autoscroll on keyboard events
    override func scrollRectToVisible(rect: CGRect, animated: Bool) {
        //nothing
    }
}

/**
    A UITableView with (mostly) disabled autoscroll behavior
*/
class KBTableView: UITableView {
    // Stops scroll view from trying to autoscroll on keyboard events
    override func scrollToRowAtIndexPath(indexPath: NSIndexPath, atScrollPosition scrollPosition: UITableViewScrollPosition, animated: Bool) {
        //nothing
    }
    override func scrollToNearestSelectedRowAtScrollPosition(scrollPosition: UITableViewScrollPosition, animated: Bool) {
        //nothing
    }
    override func scrollRectToVisible(rect: CGRect, animated: Bool) {
        //nothing
    }
}