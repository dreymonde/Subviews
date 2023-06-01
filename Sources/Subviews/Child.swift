import UIKit

public protocol AddsChildrenViewControllers: Enclosing, SuperviewContainer {
}

extension UIViewController: SuperviewContainer {
    public static var defaultSuperview: (UIViewController) -> UIView {
        return \.view
    }
}

extension AddsChildrenViewControllers where Self: UIViewController {
    public typealias Child<Superview: UIView, ViewController: UIViewController> = AnyChild<Self, Superview, ViewController>
}

public extension AddsChildrenViewControllers {
    func Children(@EnclosedBuilder _ builder: () -> [Enclosed]) {
        enclose(builder)
    }
}

@propertyWrapper
public struct AnyChild<EnclosingSelf: AddsChildrenViewControllers & UIViewController, Superview: UIView, ViewController: UIViewController>: Enclosed {

    public static subscript(
      _enclosingInstance enclosing: EnclosingSelf,
      wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, ViewController>,
      storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> ViewController {
        get {
            guard let stored = enclosing[keyPath: storageKeyPath].creatable.resolve(with: enclosing) else {
                fatalError("Trying to access child \(wrappedKeyPath) before assigned")
            }
            return stored
        }
        set {
            let behavior = enclosing[keyPath: storageKeyPath].onReplace
            enclosing[keyPath: storageKeyPath]._replace(with: newValue, parent: enclosing, behavior: behavior)
        }
    }
    
    public mutating func _replace(with newChild: ViewController, parent: any AddsChildrenViewControllers, behavior: ChildReplaceBehavior) {
        if let oldVc = creatable.stored {
            behavior.old(oldVc)
        }
        creatable = .init(newChild)
        deepResolveEnclosing(parent)
        behavior.new(newChild)
    }
    
    public func resolveEnclosing(_ enclosing: Any) {
        guard let enclosing = enclosing as? EnclosingSelf else {
            return
        }
        
        guard let created = creatable.resolve(with: enclosing) else {
            return
        }
        
        let superview = resolveSuperview(enclosing)
        enclosing.addChild(created)
        superview.addSubview(created.view)
        configure(created, enclosing)
        created.didMove(toParent: enclosing)
    }
    
    private var creatable: Creatable<ViewController, EnclosingSelf>
        
    public var wrappedProperties: [Any] {
        creatable.stored.map { [$0] } ?? []
    }

    public var wrappedValue: ViewController {
      get { fatalError("called wrappedValue getter") }
      set { fatalError("called wrappedValue setter") }
    }
    
    public var projectedValue: Self {
        get { self }
        set { self = newValue }
    }
    
    private let resolveSuperview: (EnclosingSelf) -> Superview
    private let configure: (ViewController, EnclosingSelf) -> ()
    public let onReplace: ChildReplaceBehavior

    @_disfavoredOverload
    public init(
        wrappedValue: ViewController,
        superview: @escaping (EnclosingSelf) -> Superview,
        onReplace: ChildReplaceBehavior = .remove,
        _ viewLayoutOptions: ViewLayoutOption,
        _ configure: @escaping (ViewController, EnclosingSelf) -> () = { _,_ in }
    ) {
        self.creatable = Creatable(wrappedValue)
        self.resolveSuperview = superview
        self.onReplace = onReplace
        self.configure = { val, encl in
            viewLayoutOptions.layout(val._viewForLayout)
            configure(val, encl)
        }
    }
    
    @_disfavoredOverload
    public init(
        wrappedValue: ViewController,
        superview: @escaping (EnclosingSelf) -> Superview,
        onReplace: ChildReplaceBehavior = .remove,
        _ configure: @escaping (ViewController, EnclosingSelf) -> () = { _,_ in }
    ) {
        self.init(wrappedValue: wrappedValue, superview: superview, onReplace: onReplace, [], configure)
    }
    
//    public init(
//        wrappedValue: ViewController,
//        superview: @escaping (EnclosingSelf) -> Superview,
//        onReplace: ChildReplaceBehavior = .remove,
//        _ viewLayoutOptions: ViewLayoutOption...
//    ) {
//        self.init(wrappedValue: wrappedValue, superview: superview, onReplace: onReplace, viewLayoutOptions, { _,_ in })
//    }
    
    public init(
        wrappedValue: ViewController,
        superview: @escaping (EnclosingSelf) -> Superview,
        onReplace: ChildReplaceBehavior = .remove,
        _ viewLayoutOptions: ViewLayoutOption,
        _ configure: @escaping (ViewController) -> ()
    ) {
        self.init(wrappedValue: wrappedValue, superview: superview, onReplace: onReplace, viewLayoutOptions, { val,_ in configure(val) })
    }
    
    public init(
        wrappedValue: ViewController,
        superview: @escaping (EnclosingSelf) -> Superview,
        onReplace: ChildReplaceBehavior = .remove,
        _ configure: @escaping (ViewController) -> ()
    ) {
        self.init(wrappedValue: wrappedValue, superview: superview, onReplace: onReplace, [], { val,_ in configure(val) })
    }
    
    // MARK: `nil` / unresolved inits
    
    @_disfavoredOverload
    public init(
        wrappedValue: ((EnclosingSelf) -> ViewController)? = nil,
        superview: @escaping (EnclosingSelf) -> Superview,
        onReplace: ChildReplaceBehavior = .remove,
        _ viewLayoutOptions: ViewLayoutOption,
        _ configure: @escaping (ViewController, EnclosingSelf) -> () = { _,_ in }
    ) {
        self.creatable = Creatable(create: wrappedValue)
        self.resolveSuperview = superview
        self.onReplace = onReplace
        self.configure = { val, encl in
            viewLayoutOptions.layout(val._viewForLayout)
            configure(val, encl)
        }
    }
        
    @_disfavoredOverload
    public init(
        wrappedValue: ((EnclosingSelf) -> ViewController)? = nil,
        superview: @escaping (EnclosingSelf) -> Superview,
        onReplace: ChildReplaceBehavior = .remove,
        _ configure: @escaping (ViewController, EnclosingSelf) -> () = { _,_ in }
    ) {
        self.init(wrappedValue: wrappedValue, superview: superview, onReplace: onReplace, [], configure)
    }
    
//    public init(
//        wrappedValue: ((EnclosingSelf) -> ViewController)? = nil,
//        superview: @escaping (EnclosingSelf) -> Superview,
//        onReplace: ChildReplaceBehavior = .remove,
//        _ viewLayoutOptions: ViewLayoutOption...
//    ) {
//        self.init(wrappedValue: wrappedValue, superview: superview, onReplace: onReplace, viewLayoutOptions, { _,_ in })
//    }
    
    public init(
        wrappedValue: ((EnclosingSelf) -> ViewController)? = nil,
        superview: @escaping (EnclosingSelf) -> Superview,
        onReplace: ChildReplaceBehavior = .remove,
        _ viewLayoutOptions: ViewLayoutOption,
        _ configure: @escaping (ViewController) -> ()
    ) {
        self.init(wrappedValue: wrappedValue, superview: superview, onReplace: onReplace, viewLayoutOptions, { val,_ in configure(val) })
    }
    
    public init(
        wrappedValue: ((EnclosingSelf) -> ViewController)? = nil,
        superview: @escaping (EnclosingSelf) -> Superview,
        onReplace: ChildReplaceBehavior = .remove,
        _ configure: @escaping (ViewController) -> ()
    ) {
        self.init(wrappedValue: wrappedValue, superview: superview, onReplace: onReplace, [], { val,_ in configure(val) })
    }
}

// MARK: - Default Superview extensions

extension AnyChild where Superview == UIView {
    @_disfavoredOverload
    public init(
        wrappedValue: ViewController,
        onReplace: ChildReplaceBehavior = .remove,
        _ viewLayoutOptions: ViewLayoutOption,
        _ configure: @escaping (ViewController, EnclosingSelf) -> () = { _,_ in }
    ) {
        self.init(wrappedValue: wrappedValue, superview: EnclosingSelf.defaultSuperview, onReplace: onReplace, viewLayoutOptions, configure)
    }
    
    @_disfavoredOverload
    public init(
        wrappedValue: ViewController,
        onReplace: ChildReplaceBehavior = .remove,
        _ configure: @escaping (ViewController, EnclosingSelf) -> () = { _,_ in }
    ) {
        self.init(wrappedValue: wrappedValue, superview: EnclosingSelf.defaultSuperview, onReplace: onReplace, configure)
    }
    
//    public init(
//        wrappedValue: ViewController,
//        onReplace: ChildReplaceBehavior = .remove,
//        _ viewLayoutOptions: ViewLayoutOption...
//    ) {
//        self.init(wrappedValue: wrappedValue, superview: EnclosingSelf.defaultSuperview, onReplace: onReplace, viewLayoutOptions, { _,_ in })
//    }
    
    public init(
        wrappedValue: ViewController,
        onReplace: ChildReplaceBehavior = .remove,
        _ viewLayoutOptions: ViewLayoutOption,
        _ configure: @escaping (ViewController) -> ()
    ) {
        self.init(wrappedValue: wrappedValue, superview: EnclosingSelf.defaultSuperview, onReplace: onReplace, viewLayoutOptions, { val,_ in configure(val) })
    }
    
    public init(
        wrappedValue: ViewController,
        onReplace: ChildReplaceBehavior = .remove,
        _ configure: @escaping (ViewController) -> ()
    ) {
        self.init(wrappedValue: wrappedValue, superview: EnclosingSelf.defaultSuperview, onReplace: onReplace, configure)
    }
    
    // MARK: `nil` / unresolved inits
    
    @_disfavoredOverload
    public init(
        wrappedValue: ((EnclosingSelf) -> ViewController)? = nil,
        onReplace: ChildReplaceBehavior = .remove,
        _ viewLayoutOptions: ViewLayoutOption,
        _ configure: @escaping (ViewController, EnclosingSelf) -> () = { _,_ in }
    ) {
        self.init(wrappedValue: wrappedValue, superview: EnclosingSelf.defaultSuperview, onReplace: onReplace, viewLayoutOptions, configure)
    }
    
    @_disfavoredOverload
    public init(
        wrappedValue: ((EnclosingSelf) -> ViewController)? = nil,
        onReplace: ChildReplaceBehavior = .remove,
        _ configure: @escaping (ViewController, EnclosingSelf) -> () = { _,_ in }
    ) {
        self.init(wrappedValue: wrappedValue, superview: EnclosingSelf.defaultSuperview, onReplace: onReplace, configure)
    }
    
//    public init(
//        wrappedValue: ((EnclosingSelf) -> ViewController)? = nil,
//        onReplace: ChildReplaceBehavior = .remove,
//        _ viewLayoutOptions: ViewLayoutOption...
//    ) {
//        self.init(wrappedValue: wrappedValue, superview: EnclosingSelf.defaultSuperview, onReplace: onReplace, viewLayoutOptions, { _,_ in })
//    }
    
    public init(
        wrappedValue: ((EnclosingSelf) -> ViewController)? = nil,
        onReplace: ChildReplaceBehavior = .remove,
        _ viewLayoutOptions: ViewLayoutOption,
        _ configure: @escaping (ViewController) -> ()
    ) {
        self.init(wrappedValue: wrappedValue, superview: EnclosingSelf.defaultSuperview, onReplace: onReplace, viewLayoutOptions, { val,_ in configure(val) })
    }
    
    public init(
        wrappedValue: ((EnclosingSelf) -> ViewController)? = nil,
        onReplace: ChildReplaceBehavior = .remove,
        _ configure: @escaping (ViewController) -> ()
    ) {
        self.init(wrappedValue: wrappedValue, superview: EnclosingSelf.defaultSuperview, onReplace: onReplace, configure)
    }
}

public struct ChildReplaceBehavior {
    let new: (UIViewController) -> Void
    let old: (UIViewController) -> Void
    
    public init(new: @escaping (UIViewController) -> Void, old: @escaping (UIViewController) -> Void) {
        self.new = new
        self.old = old
    }
    
    public static let overlay = ChildReplaceBehavior { (_) in } old: { _ in }

    public static let remove = ChildReplaceBehavior { (_) in
        
    } old: { oldVc in
        oldVc.willMove(toParent: nil)
        oldVc.removeFromParent()
        oldVc.view.removeFromSuperview()
    }

    public static let hide = ChildReplaceBehavior { newVc in
        newVc.view.isHidden = false
    } old: { oldVc in
        oldVc.view.isHidden = true
    }
    
    public static let _removeAndFadeIn = ChildReplaceBehavior { newVc in
        newVc.view.alpha = 0.0
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            newVc.view.alpha = 1.0
        }
    } old: { oldVc in
        ChildReplaceBehavior.remove.old(oldVc)
    }
    
    public static let _fadeOutAndFadeIn = ChildReplaceBehavior { newVc in
        newVc.view.alpha = 0.0
        UIView.animate(withDuration: 0.33, delay: 0.4, options: .curveEaseInOut) {
            newVc.view.alpha = 1.0
        }
    } old: { oldVc in
        UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseInOut) {
            oldVc.view.alpha = 0.0
        } completion: { _ in
            ChildReplaceBehavior.remove.old(oldVc)
        }
    }

    public static let _crossFade = ChildReplaceBehavior { newVc in
        newVc.view.alpha = 0.0
        UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseInOut) {
            newVc.view.alpha = 1.0
        }
    } old: { oldVc in
        UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseInOut) {
            oldVc.view.alpha = 0.0
        } completion: { _ in
            ChildReplaceBehavior.remove.old(oldVc)
        }
    }
}
