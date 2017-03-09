import Foundation

public class UIBaseObject: UIView, EventProtocol {
    private let baseObject = BaseObject()
    
    public func on(eventName:String, callback: EventCallback) -> String {
        return baseObject.on(eventName, callback: callback)
    }
    
    public func once(eventName:String, callback: EventCallback) -> String {
        return baseObject.once(eventName, callback: callback)
    }
    
    public func off(listenId: String) {
        baseObject.off(listenId)
    }
    
    public func trigger(eventName:String) {
        baseObject.trigger(eventName)
        Logger.logDebug("[\(eventName)] triggered", scope: logIdentifier())
    }
    
    public func trigger(eventName:String, userInfo: [NSObject : AnyObject]?) {
        baseObject.trigger(eventName, userInfo: userInfo)
        Logger.logDebug("[\(eventName)] triggered with \(userInfo)", scope: logIdentifier())
    }
    
    public func listenTo<T: EventProtocol>(contextObject: T, eventName: String, callback: EventCallback) -> String {
        return baseObject.listenTo(contextObject, eventName: eventName, callback: callback)
    }

    public func listenToOnce<T : EventProtocol>(contextObject: T, eventName: String, callback: EventCallback) -> String {
        return baseObject.listenToOnce(contextObject, eventName: eventName, callback: callback)
    }
    
    public func stopListening() {
        baseObject.stopListening()
    }
    
    public func stopListening(listenId: String) {
        baseObject.stopListening(listenId)
    }
    
    public func getEventContextObject() -> BaseObject {
        return baseObject
    }

    private func logIdentifier() -> String {
        if let plugin = self as? Plugin {
            return plugin.pluginName
        }
        return "\(self.dynamicType)"
    }
    
    public func render() {}
}

extension UIBaseObject {
    public func trigger(event: Event) {
        trigger(event.rawValue)
    }

    public func trigger(event: Event, userInfo: EventUserInfo) {
        trigger(event.rawValue, userInfo: userInfo)
    }
}
