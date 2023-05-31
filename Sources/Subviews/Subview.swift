import UIKit

public protocol SuperviewContainer {
    static var defaultSuperview: (Self) -> UIView { get }
}

public protocol AddsSubviews: Enclosing, SuperviewContainer {
    typealias Subview<Superview: UIView, View: UIView> = AnySubview<Self, Superview, View>
    typealias ArrangedSubview<Stack: UIStackView, View: UIView> = AnyArrangedSubview<Self, Stack, View>
}

public extension AddsSubviews {
    func Subviews(@EnclosedBuilder _ builder: () -> [Enclosed]) {
        enclose(builder)
    }
}

extension UIView: SuperviewContainer {
    public static var defaultSuperview: (UIView) -> UIView {
        return \.self
    }
}

@propertyWrapper
public struct AnySubview<EnclosingSelf: AddsSubviews, Superview: UIView, View: UIView>: Enclosed {

    public static subscript(
      _enclosingInstance enclosing: EnclosingSelf,
      wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, View>,
      storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> View {
        get {
            guard let stored = enclosing[keyPath: storageKeyPath].creatable.resolve(with: enclosing) else {
                fatalError("Trying to access subview \(wrappedKeyPath) before assigned")
            }
            return stored
        }
        set {
            let behavior = enclosing[keyPath: storageKeyPath].onReplace
            enclosing[keyPath: storageKeyPath]._replace(with: newValue, parent: enclosing, behavior: behavior)
        }
    }
    
    public mutating func _replace(with newSubview: View, parent: any AddsSubviews, behavior: SubviewReplaceBehavior) {
        if let oldVc = creatable.stored {
            behavior.old(oldVc)
        }
        creatable = .init(newSubview)
        deepResolveEnclosing(parent)
        behavior.new(newSubview)
    }
    
    public func resolveEnclosing(_ enclosing: Any) {
        guard let enclosing = enclosing as? EnclosingSelf else {
            return
        }
        
        guard let created = creatable.resolve(with: enclosing) else {
            return
        }
        
        let superview = resolveSuperview(enclosing)
        superview.addSubview(created)
        configure(created, enclosing)
    }
    
    private var creatable: Creatable<View, EnclosingSelf>

    public var wrappedProperties: [Any] {
        creatable.stored.map { [$0] } ?? []
    }

    public var wrappedValue: View {
      get { fatalError("called wrappedValue getter") }
      set { fatalError("called wrappedValue setter") }
    }
    
    public var projectedValue: AnySubview<EnclosingSelf, Superview, View> {
        get { self }
        set { self = newValue }
    }
    
    internal let resolveSuperview: (EnclosingSelf) -> Superview
    internal let configure: (View, EnclosingSelf) -> ()
    public private(set) var onReplace: SubviewReplaceBehavior

    @_disfavoredOverload
    public init(
        wrappedValue: View,
        of superview: @escaping (EnclosingSelf) -> Superview,
        onReplace: SubviewReplaceBehavior = .remove,
        _ viewLayoutOptions: ViewLayoutOption,
        _ configure: @escaping (View, EnclosingSelf) -> () = { _,_ in }
    ) {
        self.creatable = .init(wrappedValue)
        self.resolveSuperview = superview
        self.onReplace = onReplace
        self.configure = { val, encl in
            viewLayoutOptions.layout(val)
            configure(val, encl)
        }
    }
    
    @_disfavoredOverload
    public init(
        wrappedValue: View,
        of superview: @escaping (EnclosingSelf) -> Superview,
        onReplace: SubviewReplaceBehavior = .remove,
        _ configure: @escaping (View, EnclosingSelf) -> () = { _,_ in }
    ) {
        self.init(wrappedValue: wrappedValue, of: superview, onReplace: onReplace, [], configure)
    }
    
    public init(
        wrappedValue: View,
        of superview: @escaping (EnclosingSelf) -> Superview,
        onReplace: SubviewReplaceBehavior = .remove,
        _ viewLayoutOptions: ViewLayoutOption,
        _ configure: @escaping (View) -> ()
    ) {
        self.init(wrappedValue: wrappedValue, of: superview, onReplace: onReplace, viewLayoutOptions, { val,_ in configure(val) })
    }
    
    public init(
        wrappedValue: View,
        of superview: @escaping (EnclosingSelf) -> Superview,
        onReplace: SubviewReplaceBehavior = .remove,
        _ configure: @escaping (View) -> ()
    ) {
        self.init(wrappedValue: wrappedValue, of: superview, onReplace: onReplace, [], { val,_ in configure(val) })
    }
    
    // MARK: `nil` / unresolved inits
    
    @_disfavoredOverload
    public init(
        wrappedValue: ((EnclosingSelf) -> View)? = nil,
        of superview: @escaping (EnclosingSelf) -> Superview,
        onReplace: SubviewReplaceBehavior = .remove,
        _ viewLayoutOptions: ViewLayoutOption,
        _ configure: @escaping (View, EnclosingSelf) -> () = { _,_ in }
    ) {
        self.creatable = Creatable(create: wrappedValue)
        self.resolveSuperview = superview
        self.onReplace = onReplace
        self.configure = { val, encl in
            viewLayoutOptions.layout(val)
            configure(val, encl)
        }
    }
    
    @_disfavoredOverload
    public init(
        wrappedValue: ((EnclosingSelf) -> View)? = nil,
        of superview: @escaping (EnclosingSelf) -> Superview,
        onReplace: SubviewReplaceBehavior = .remove,
        _ configure: @escaping (View, EnclosingSelf) -> () = { _,_ in }
    ) {
        self.init(wrappedValue: wrappedValue, of: superview, onReplace: onReplace, [], configure)
    }
    
    public init(
        wrappedValue: ((EnclosingSelf) -> View)? = nil,
        of superview: @escaping (EnclosingSelf) -> Superview,
        onReplace: SubviewReplaceBehavior = .remove,
        _ viewLayoutOptions: ViewLayoutOption,
        _ configure: @escaping (View) -> ()
    ) {
        self.init(wrappedValue: wrappedValue, of: superview, onReplace: onReplace, viewLayoutOptions, { val,_ in configure(val) })
    }
    
    public init(
        wrappedValue: ((EnclosingSelf) -> View)? = nil,
        of superview: @escaping (EnclosingSelf) -> Superview,
        onReplace: SubviewReplaceBehavior = .remove,
        _ configure: @escaping (View) -> ()
    ) {
        self.init(wrappedValue: wrappedValue, of: superview, onReplace: onReplace, [], { val,_ in configure(val) })
    }
}

extension AnySubview where Superview == UIView {
    @_disfavoredOverload
    public init(
        wrappedValue: View,
        onReplace: SubviewReplaceBehavior = .remove,
        _ viewLayoutOptions: ViewLayoutOption,
        _ configure: @escaping (View, EnclosingSelf) -> () = { _,_ in }
    ) {
        self.init(wrappedValue: wrappedValue, of: EnclosingSelf.defaultSuperview, onReplace: onReplace, viewLayoutOptions, configure)
    }
    
    @_disfavoredOverload
    public init(
        wrappedValue: View,
        onReplace: SubviewReplaceBehavior = .remove,
        _ configure: @escaping (View, EnclosingSelf) -> () = { _,_ in }
    ) {
        self.init(wrappedValue: wrappedValue, of: EnclosingSelf.defaultSuperview, onReplace: onReplace, configure)
    }
    
    public init(
        wrappedValue: View,
        onReplace: SubviewReplaceBehavior = .remove,
        _ viewLayoutOptions: ViewLayoutOption,
        _ configure: @escaping (View) -> ()
    ) {
        self.init(wrappedValue: wrappedValue, of: EnclosingSelf.defaultSuperview, onReplace: onReplace, viewLayoutOptions, { val,_ in configure(val) })
    }
    
    public init(
        wrappedValue: View,
        onReplace: SubviewReplaceBehavior = .remove,
        _ configure: @escaping (View) -> ()
    ) {
        self.init(wrappedValue: wrappedValue, of: EnclosingSelf.defaultSuperview, onReplace: onReplace, configure)
    }
    
    // MARK: `nil` / unresolved inits
    
    @_disfavoredOverload
    public init(
        wrappedValue: ((EnclosingSelf) -> View)? = nil,
        onReplace: SubviewReplaceBehavior = .remove,
        _ viewLayoutOptions: ViewLayoutOption,
        _ configure: @escaping (View, EnclosingSelf) -> () = { _,_ in }
    ) {
        self.init(wrappedValue: wrappedValue, of: EnclosingSelf.defaultSuperview, onReplace: onReplace, viewLayoutOptions, configure)
    }
    
    @_disfavoredOverload
    public init(
        wrappedValue: ((EnclosingSelf) -> View)? = nil,
        onReplace: SubviewReplaceBehavior = .remove,
        _ configure: @escaping (View, EnclosingSelf) -> () = { _,_ in }
    ) {
        self.init(wrappedValue: wrappedValue, of: EnclosingSelf.defaultSuperview, onReplace: onReplace, configure)
    }
    
    public init(
        wrappedValue: ((EnclosingSelf) -> View)? = nil,
        onReplace: SubviewReplaceBehavior = .remove,
        _ viewLayoutOptions: ViewLayoutOption,
        _ configure: @escaping (View) -> ()
    ) {
        self.init(wrappedValue: wrappedValue, of: EnclosingSelf.defaultSuperview, onReplace: onReplace, viewLayoutOptions, { val,_ in configure(val) })
    }
    
    public init(
        wrappedValue: ((EnclosingSelf) -> View)? = nil,
        onReplace: SubviewReplaceBehavior = .remove,
        _ configure: @escaping (View) -> ()
    ) {
        self.init(wrappedValue: wrappedValue, of: EnclosingSelf.defaultSuperview, onReplace: onReplace, configure)
    }
}

@propertyWrapper
public struct AnyArrangedSubview<EnclosingSelf: AddsSubviews, Superview: UIStackView, View: UIView>: Enclosed {

    public static subscript(
      _enclosingInstance enclosing: EnclosingSelf,
      wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, View>,
      storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Self>
    ) -> View {
        get {
            guard let stored = enclosing[keyPath: storageKeyPath].creatable.resolve(with: enclosing) else {
                fatalError("Trying to access subview \(wrappedKeyPath) before assigned")
            }
            return stored
        }
        set {
            
        }
    }
    
    public func resolveEnclosing(_ enclosing: Any) {
        guard let enclosing = enclosing as? EnclosingSelf else {
            return
        }
        
        guard let created = creatable.resolve(with: enclosing) else {
            return
        }
        
        let superview = resolveSuperview(enclosing)
        superview.addArrangedSubview(created)
        configure(created, enclosing)
    }
    
    private var creatable: Creatable<View, EnclosingSelf>

    public var wrappedProperties: [Any] {
        creatable.stored.map { [$0] } ?? []
    }

    public var wrappedValue: View {
      get { fatalError("called wrappedValue getter") }
      set { fatalError("called wrappedValue setter") }
    }
    
    public let resolveSuperview: (EnclosingSelf) -> Superview
    public let configure: (View, EnclosingSelf) -> ()

    @_disfavoredOverload
    public init(
        wrappedValue: View,
        of superview: @escaping (EnclosingSelf) -> Superview,
        _ configure: @escaping (View, EnclosingSelf) -> () = { _,_ in }
    ) {
        self.creatable = Creatable(wrappedValue)
        self.resolveSuperview = superview
        self.configure = configure
    }
    
    public init(
        wrappedValue: View,
        of superview: @escaping (EnclosingSelf) -> Superview,
        _ configure: @escaping (View) -> () = { _ in }
    ) {
        self.init(wrappedValue: wrappedValue, of: superview, { val,_ in configure(val) })
    }
    
    // MARK: `nil` / unresolved inits

    @_disfavoredOverload
    public init(
        wrappedValue: ((EnclosingSelf) -> View)? = nil,
        of superview: @escaping (EnclosingSelf) -> Superview,
        _ configure: @escaping (View, EnclosingSelf) -> () = { _,_ in }
    ) {
        self.creatable = Creatable(create: wrappedValue)
        self.resolveSuperview = superview
        self.configure = configure
    }
    
    public init(
        wrappedValue: ((EnclosingSelf) -> View)? = nil,
        of superview: @escaping (EnclosingSelf) -> Superview,
        _ configure: @escaping (View) -> () = { _ in }
    ) {
        self.init(wrappedValue: wrappedValue, of: superview, { val,_ in configure(val) })
    }
}

public struct SubviewReplaceBehavior {
    let new: (UIView) -> Void
    let old: (UIView) -> Void
    
    public init(new: @escaping (UIView) -> Void, old: @escaping (UIView) -> Void) {
        self.new = new
        self.old = old
    }
    
    public static let overlay = SubviewReplaceBehavior { (_) in } old: { _ in }

    public static let remove = SubviewReplaceBehavior { (_) in
        
    } old: { oldView in
        oldView.removeFromSuperview()
    }

    public static let hide = SubviewReplaceBehavior { newView in
        newView.isHidden = false
    } old: { oldView in
        oldView.isHidden = true
    }
    
    public static let _removeAndFadeIn = SubviewReplaceBehavior { newVc in
        newVc.alpha = 0.0
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            newVc.alpha = 1.0
        }
    } old: { oldVc in
        SubviewReplaceBehavior.remove.old(oldVc)
    }
    
    public static let _fadeOutAndFadeIn = SubviewReplaceBehavior { newVc in
        newVc.alpha = 0.0
        UIView.animate(withDuration: 0.33, delay: 0.4, options: .curveEaseInOut) {
            newVc.alpha = 1.0
        }
    } old: { oldVc in
        UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseInOut) {
            oldVc.alpha = 0.0
        } completion: { _ in
            SubviewReplaceBehavior.remove.old(oldVc)
        }
    }
    
    public static let _crossFade = SubviewReplaceBehavior { newVc in
        newVc.alpha = 0.0
        UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseInOut) {
            newVc.alpha = 1.0
        }
    } old: { oldVc in
        UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseInOut) {
            oldVc.alpha = 0.0
        } completion: { _ in
            SubviewReplaceBehavior.remove.old(oldVc)
        }
    }
}
