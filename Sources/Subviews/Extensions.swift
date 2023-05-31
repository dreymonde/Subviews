import UIKit

public protocol _EnclosedConfigurable: AnyObject { }
extension UIView: _EnclosedConfigurable { }

extension _EnclosedConfigurable {
    public func _withSelf<EnclosingSelf>(_ configure: @escaping (Self, EnclosingSelf) -> Void) -> ((EnclosingSelf) -> Self) {
        return { enclosing in
            configure(self, enclosing)
            return self
        }
    }
}
