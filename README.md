SwiftEventDispatcher
====================

SwiftEventDispatcher is a simple Swift class which makes it easy to implement a pub/sub
event listener paradigm.

For example, one might use it while designing an NSUserDefaults wrapper to subscribe a
ViewController to settings updates (rather than propogating the update through calls
from the parent).  For instance:

```swift
class LocalSettings {

    private let localSettings = NSUserDefaults.standardUserDefaults()
    static let sharedInstance = LocalSettings()

    private let eventDispatcher = EventDispatcher()

    func startListening(listener: SettingsDelegate) {
        eventDispatcher.startListening(listener)
    }

    func stopListening(listener: SettingsDelegate) {
        eventDispatcher.stopListening(listener)
    }

    var isNewUser: Bool {
        get {
            return localSettings.boolForKey("isNewUser")
        }
        set {
            let oldValue = isNewUser
            localSettings.setBool(newValue, forKey: "isNewUser")
            localSettings.synchronize()
            eventDispatcher.forEachListener({ [weak self] (listener) in
                if self != nil {
                    (listener as? SettingsDelegate)?.settingsChanged(self!, didChangeIsNewUser: newValue, oldValue: oldValue)
                }
            })
        }
    }
}

protocol SettingsDelegate: class, AnyObject {
    func settingsChanged(_: LocalSettings, didChangeIsNewUser newValue: Bool, oldValue: Bool)
}
```

