# KeyboardUtility
A swift protocol utility which moves screen content out from under the keyboard, and iterates through "Next" fields using the Tag attribute.

## Using This Utility

1. Add the KeyboardUtility.swift file to your project.

2. After you have wired up all your text fields to your View Controller, change it to implement the **KeyboardUtilityDelegate** protocol.

```swift
class MyViewController: UIViewController, KeyboardUtilityDelegate {
...
}
```

3. Add the required protocol property **textFields**.

```swift    
var textFields: [UITextField] {
  var textFields = [UITextField]()
  // include any text fields to be managed:
  textFields.append(field1)
  textFields.append(field2)
  return textFields
}
```

4. Back in the storyboard, update your textfields **Tag** attribute to use sequential numbers 1...999.

![Example of Step 4 Tag field](/KeyboardUtilityDemo/KeyboardUtilityDemo/Images.xcassets/KeyboardUtility_Readme_Tag.imageset/KeyboardUtility_Readme_Tag.png?raw=true)

5. Update your textfields ReturnKey attribute to use "Next," until the last field (where you can choose between "Done" or "Go" or "Join" or whatever is most appropriate to indicate the completion of the form).

![Example of Step 5 ReturnKey field](/KeyboardUtilityDemo/KeyboardUtilityDemo/Images.xcassets/KeyboardUtility_Readme_ReturnKey.imageset/KeyboardUtility_Readme_ReturnKey.png?raw=true)

6. In your View Controller, add the optional protocol function *textFieldShouldReturn()* to process the finished form.

```swift    
func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == field999 {
            // validate form here
            //
            // submit form here ...
            //
        }
        return true
    }
```

That's it! You should now have an easily navigable form where the field you are editing is always visible.

![Example Image](/KeyboardUtilityDemo/KeyboardUtilityDemo/Images.xcassets/KeyboardUtility_Readme_Example.imageset/KeyboardUtility_Readme_Example.png?raw=true)

## UIScrollView and UITableViewController
Because iOS scrollable elements have their own auto-scrolling UITextField behavior, it can appear to jerk as KeyboardUtility and iOS wrestle for control of the window placement. To correct for this, I've included two subclasses, KBScrollView and KBTableView, that help minimize the conflict. However, in the case of UITableViewController, I was unsatisfied with the results and do not recommend using KeyboardUtility's window shifting behavior when a UITableViewController is present. If you would like to use the other functionality in KeyboardUtility, set the public property **dontshiftForKeyboard** to **true**.

## Demo Project
Look at the KeyboardUtilityDemo project for several examples of KeyboardUtility used with forms, table views, and scroll views.
