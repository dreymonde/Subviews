import UIKit

public protocol ViewLayoutParent {
    func addSubview(_ view: UIView)
}

extension UIView: ViewLayoutParent { }

extension ViewLayoutParent {
    public func addSubview<Subview: UIView>(_ view: Subview, _ viewLayoutOptions: ViewLayoutOption = [], configure: (Subview) -> () = { _ in }) {
        addSubview(view)
        viewLayoutOptions.layout(view)
        configure(view)
    }
}

public protocol ViewLayoutSupporting: AnyObject {
    var _viewForLayout: UIView { get }
}

extension UIView: ViewLayoutSupporting {
    public var _viewForLayout: UIView { self }
}

extension UIViewController: ViewLayoutSupporting {
    public var _viewForLayout: UIView { self.view }
}

public struct ViewLayoutOption: ExpressibleByArrayLiteral {
    
    // MARK: Internals
    
    public init(layout: @escaping (UIView) -> Void) {
        self.layout = layout
    }
    
    public init(arrayLiteral elements: ViewLayoutOption...) {
        self.layout = { (subview) in
            for element in elements { element.layout(subview) }
        }
    }
    
    public static func withSuperview(_ layout: @escaping (UIView, _ superview: UIView) -> Void) -> ViewLayoutOption {
        ViewLayoutOption {
            guard let superview = $0.superview else {
                return
            }
            layout($0, superview)
        }
    }
    
    public typealias ArrayLiteralElement = ViewLayoutOption
    
    public var layout: (UIView) -> ()
        
    // MARK: Public Quick Layout Options
    
    // MARK: Center
    
    public static var alignCenter: Self {
        Self { $0.anchors.center.align() }
    }
    public static var alignCenterX: Self {
        Self { $0.anchors.centerX.align() }
    }
    public static var alignCenterY: Self {
        Self { $0.anchors.centerY.align() }
    }
    
    // MARK: Center Functions
    
    public static func alignCenter(offset: CGSize) -> ViewLayoutOption {
        ViewLayoutOption {
            $0.anchors.centerX.align(offset: offset.width)
            $0.anchors.centerY.align(offset: offset.height)
        }
    }
    public static func alignCenterX(offset: CGFloat) -> ViewLayoutOption {
        ViewLayoutOption { $0.anchors.centerX.align(offset: offset) }
    }
    public static func alignCenterY(offset: CGFloat) -> ViewLayoutOption {
        ViewLayoutOption { $0.anchors.centerY.align(offset: offset) }
    }
    
    // MARK: Size Functions
    
    public static func size(_ size: CGSize) -> ViewLayoutOption {
        ViewLayoutOption { $0.anchors.size.equal(size) }
    }
    public static func height(_ height: CGFloat) -> ViewLayoutOption {
        ViewLayoutOption { $0.anchors.height.equal(height) }
    }
    public static func width(_ width: CGFloat) -> ViewLayoutOption {
        ViewLayoutOption { $0.anchors.width.equal(width) }
    }
    public static func aspectRatio(_ widthToHeight: CGFloat) -> ViewLayoutOption {
        ViewLayoutOption { $0.anchors.width.equal($0.anchors.height.multiplied(by: widthToHeight)) }
    }
    public static var aspectRatioSquare: ViewLayoutOption {
        .aspectRatio(1)
    }
    
    public static func relativeSize(_ relativeSize: CGSize) -> ViewLayoutOption {
        .withSuperview {
            $0.anchors.height.equal($1.anchors.height.multiplied(by: relativeSize.height))
            $0.anchors.width.equal($1.anchors.width.multiplied(by: relativeSize.width))
        }
    }
    public static func relativeHeight(_ relativeHeight: CGFloat) -> ViewLayoutOption {
        .withSuperview { view, superview in
            view.anchors.height.equal(superview.anchors.height.multiplied(by: relativeHeight))
        }
    }
    public static func relativeWidth(_ relativeWidth: CGFloat) -> ViewLayoutOption {
        .withSuperview { view, superview in
            view.anchors.width.equal(superview.anchors.width.multiplied(by: relativeWidth))
        }
    }
    
    // MARK: Pin
    
    public static var pin: Self { Self { $0.anchors.edges.pin() } }
    public static var pinHorizontally: Self {
        Self { $0.anchors.horizontalEdges.pin() }
    }
    public static var pinVertically: Self {
        Self { $0.anchors.verticalEdges.pin() }
    }
    internal static func pinEdge<Axis>(_ edge: KeyPath<LayoutAnchors<UIView>, Anchor<AnchorType.Edge, Axis>>, inset: CGFloat = 0) -> Self {
        return Self { $0.anchors[keyPath: edge].pin(inset: inset) }
    }
    public static var pinBottom: Self { Self.pinEdge(\.bottom) }
    public static var pinTop: Self { Self.pinEdge(\.top) }
    public static var pinLeading: Self { Self.pinEdge(\.leading) }
    public static var pinTrailing: Self { Self.pinEdge(\.trailing) }
    
    // MARK: Pin Functions
    
    public static func pin(insets: UIEdgeInsets) -> ViewLayoutOption {
        ViewLayoutOption { $0.anchors.edges.pin(insets: insets) }
    }
    public static func pin(inset: CGFloat) -> ViewLayoutOption {
        .pin(insets: .init(top: inset, left: inset, bottom: inset, right: inset))
    }
    
    public static func pinHorizontally(insets: HorizontalInsets) -> ViewLayoutOption {
        ViewLayoutOption { $0.anchors.horizontalEdges.pin(insets: .init(horizontal: insets)) }
    }
    public static func pinVertically(insets: VerticalInsets) -> ViewLayoutOption {
        ViewLayoutOption { $0.anchors.verticalEdges.pin(insets: .init(vertical: insets)) }
    }
    
    public static func pinBottom(inset: CGFloat) -> ViewLayoutOption {
        .pinEdge(\.bottom, inset: inset)
    }
    public static func pinTop(inset: CGFloat) -> ViewLayoutOption {
        .pinEdge(\.top, inset: inset)
    }
    public static func pinLeading(inset: CGFloat) -> ViewLayoutOption {
        .pinEdge(\.leading, inset: inset)
    }
    public static func pinTrailing(inset: CGFloat) -> ViewLayoutOption {
        .pinEdge(\.trailing, inset: inset)
    }
    
    // MARK: Margins Pin
    
    public static var marginsPin: Self {
        Self { $0.anchors.edges.marginsPin() }
    }
    public static var marginsPinHorizontally: Self {
        Self { $0.anchors.horizontalEdges.marginsPin() }
    }
    public static var marginsPinVertically: Self {
        Self { $0.anchors.verticalEdges.marginsPin() }
    }
    internal static func marginsPinEdge<Axis>(_ edge: KeyPath<LayoutAnchors<UIView>, Anchor<AnchorType.Edge, Axis>>, inset: CGFloat = 0) -> Self {
        return Self { $0.anchors[keyPath: edge].marginsPin(inset: inset) }
    }
    public static var marginsPinBottom: Self { Self.marginsPinEdge(\.bottom) }
    public static var marginsPinTop: Self { Self.marginsPinEdge(\.top) }
    public static var marginsPinLeading: Self { Self.marginsPinEdge(\.leading) }
    public static var marginsPinTrailing: Self { Self.marginsPinEdge(\.trailing) }
    
    // MARK: Margins Pin Functions
    
    public static func marginsPin(insets: UIEdgeInsets) -> ViewLayoutOption {
        ViewLayoutOption { $0.anchors.edges.marginsPin(insets: insets) }
    }
    public static func marginsPin(inset: CGFloat) -> ViewLayoutOption {
        .marginsPin(insets: .init(top: inset, left: inset, bottom: inset, right: inset))
    }
    
    public static func marginsPinHorizontally(insets: HorizontalInsets) -> ViewLayoutOption {
        ViewLayoutOption { $0.anchors.horizontalEdges.marginsPin(insets: .init(horizontal: insets)) }
    }
    public static func marginsPinVertically(insets: VerticalInsets) -> ViewLayoutOption {
        ViewLayoutOption { $0.anchors.verticalEdges.marginsPin(insets: .init(vertical: insets)) }
    }
    
    public static func marginsPinBottom(inset: CGFloat) -> ViewLayoutOption {
        .marginsPinEdge(\.bottom, inset: inset)
    }
    public static func marginsPinTop(inset: CGFloat) -> ViewLayoutOption {
        .marginsPinEdge(\.top, inset: inset)
    }
    public static func marginsPinLeading(inset: CGFloat) -> ViewLayoutOption {
        .marginsPinEdge(\.leading, inset: inset)
    }
    public static func marginsPinTrailing(inset: CGFloat) -> ViewLayoutOption {
        .marginsPinEdge(\.trailing, inset: inset)
    }
    
    // MARK: Safe Area Pin
    
    public static var safeAreaPin: Self {
        Self { $0.anchors.edges.safeAreaPin() }
    }
    public static var safeAreaPinHorizontally: Self {
        Self { $0.anchors.horizontalEdges.safeAreaPin() }
    }
    public static var safeAreaPinVertically: Self {
        Self { $0.anchors.verticalEdges.safeAreaPin() }
    }
    internal static func safeAreaPinEdge<Axis>(_ edge: KeyPath<LayoutAnchors<UIView>, Anchor<AnchorType.Edge, Axis>>, inset: CGFloat = 0) -> Self {
        return Self { $0.anchors[keyPath: edge].safeAreaPin(inset: inset) }
    }
    public static var safeAreaPinBottom: Self { Self.safeAreaPinEdge(\.bottom) }
    public static var safeAreaPinTop: Self { Self.safeAreaPinEdge(\.top) }
    public static var safeAreaPinLeading: Self { Self.safeAreaPinEdge(\.leading) }
    public static var safeAreaPinTrailing: Self { Self.safeAreaPinEdge(\.trailing) }
    
    // MARK: Safe Area Pin Functions
    
    public static func safeAreaPin(insets: UIEdgeInsets) -> ViewLayoutOption {
        ViewLayoutOption { $0.anchors.edges.safeAreaPin(insets: insets) }
    }
    public static func safeAreaPin(inset: CGFloat) -> ViewLayoutOption {
        .safeAreaPin(insets: .init(top: inset, left: inset, bottom: inset, right: inset))
    }
    
    public static func safeAreaPinHorizontally(insets: HorizontalInsets) -> ViewLayoutOption {
        ViewLayoutOption { $0.anchors.horizontalEdges.safeAreaPin(insets: .init(horizontal: insets)) }
    }
    public static func safeAreaPinVertically(insets: VerticalInsets) -> ViewLayoutOption {
        ViewLayoutOption { $0.anchors.verticalEdges.safeAreaPin(insets: .init(vertical: insets)) }
    }
    
    public static func safeAreaPinBottom(inset: CGFloat) -> ViewLayoutOption {
        .safeAreaPinEdge(\.bottom, inset: inset)
    }
    public static func safeAreaPinTop(inset: CGFloat) -> ViewLayoutOption {
        .safeAreaPinEdge(\.top, inset: inset)
    }
    public static func safeAreaPinLeading(inset: CGFloat) -> ViewLayoutOption {
        .safeAreaPinEdge(\.leading, inset: inset)
    }
    public static func safeAreaPinTrailing(inset: CGFloat) -> ViewLayoutOption {
        .safeAreaPinEdge(\.trailing, inset: inset)
    }
    
    // MARK: Readable Content Guide Pin
    
    public static var readableContentPin: Self {
        Self { $0.anchors.edges.readableContentPin() }
    }
    public static var readableContentPinHorizontally: Self {
        Self { $0.anchors.horizontalEdges.readableContentPin() }
    }
    public static var readableContentPinVertically: Self {
        Self { $0.anchors.verticalEdges.readableContentPin() }
    }
    internal static func readableContentPinEdge<Axis>(_ edge: KeyPath<LayoutAnchors<UIView>, Anchor<AnchorType.Edge, Axis>>, inset: CGFloat = 0) -> Self {
        return Self { $0.anchors[keyPath: edge].readableContentPin(inset: inset) }
    }
    public static var readableContentPinBottom: Self { Self.readableContentPinEdge(\.bottom) }
    public static var readableContentPinTop: Self { Self.readableContentPinEdge(\.top) }
    public static var readableContentPinLeading: Self { Self.readableContentPinEdge(\.leading) }
    public static var readableContentPinTrailing: Self { Self.readableContentPinEdge(\.trailing) }
    
    // MARK: Readable Content Guide Pin Functions
    
    public static func readableContentPin(insets: UIEdgeInsets) -> ViewLayoutOption {
        ViewLayoutOption { $0.anchors.edges.readableContentPin(insets: insets) }
    }
    public static func readableContentPin(inset: CGFloat) -> ViewLayoutOption {
        .readableContentPin(insets: .init(top: inset, left: inset, bottom: inset, right: inset))
    }
    
    public static func readableContentPinHorizontally(insets: HorizontalInsets) -> ViewLayoutOption {
        ViewLayoutOption { $0.anchors.horizontalEdges.readableContentPin(insets: .init(horizontal: insets)) }
    }
    public static func readableContentPinVertically(insets: VerticalInsets) -> ViewLayoutOption {
        ViewLayoutOption { $0.anchors.verticalEdges.readableContentPin(insets: .init(vertical: insets)) }
    }
    
    public static func readableContentPinBottom(inset: CGFloat) -> ViewLayoutOption {
        .readableContentPinEdge(\.bottom, inset: inset)
    }
    public static func readableContentPinTop(inset: CGFloat) -> ViewLayoutOption {
        .readableContentPinEdge(\.top, inset: inset)
    }
    public static func readableContentPinLeading(inset: CGFloat) -> ViewLayoutOption {
        .readableContentPinEdge(\.leading, inset: inset)
    }
    public static func readableContentPinTrailing(inset: CGFloat) -> ViewLayoutOption {
        .readableContentPinEdge(\.trailing, inset: inset)
    }
}

public struct VerticalInsets: Hashable {
    public var top: CGFloat
    public var bottom: CGFloat
    
    public init(top: CGFloat, bottom: CGFloat) {
        self.top = top
        self.bottom = bottom
    }
    
    public static func all(_ inset: CGFloat) -> VerticalInsets {
        VerticalInsets(top: inset, bottom: inset)
    }
    
    public static let zero = VerticalInsets(top: 0, bottom: 0)
}

public struct HorizontalInsets: Hashable {
    public var left: CGFloat
    public var right: CGFloat
    
    public init(left: CGFloat, right: CGFloat) {
        self.left = left
        self.right = right
    }
    
    public static func all(_ inset: CGFloat) -> HorizontalInsets {
        HorizontalInsets(left: inset, right: inset)
    }
    
    public static let zero = HorizontalInsets(left: 0, right: 0)
}

extension UIEdgeInsets {
    public init(vertical: VerticalInsets, horizontal: HorizontalInsets) {
        self.init(top: vertical.top, left: horizontal.left, bottom: vertical.bottom, right: horizontal.right)
    }
    
    public init(vertical: VerticalInsets) {
        self.init(vertical: vertical, horizontal: .zero)
    }
    
    public init(horizontal: HorizontalInsets) {
        self.init(vertical: .zero, horizontal: horizontal)
    }
}

/*
 
// Center:
.alignCenter(offset:)
.alignCenterX(offset:)
.alignCenterY(offset:)
 
// Size:
.size(_ size:)
.height(_ height:)
.width(_ width:)
.aspectRatio(_ widthToHeight:)
.aspectRatioSquare
.relativeSize(_ relativeSize:)
.relativeHeight(_ relativeHeight:)
.relativeWidth(_ relativeWidth:)
 
// Edges Pin:
.pin(insets:)
.pin(inset:)
.pinHorizontally(insets:)
.pinVertically(insets:)
.pinBottom(inset:)
.pinTop(inset:)
.pinLeading(inset:)
.pinTrailing(inset:)
 
// Margins Pin:
.marginsPin(insets:)
.marginsPin(inset:)
.marginsPinHorizontally(insets:)
.marginsPinVertically(insets:)
.marginsPinBottom(inset:)
.marginsPinTop(inset:)
.marginsPinLeading(inset:)
.marginsPinTrailing(inset:)
 
// Safe Area Pin:
.safeAreaPin(insets:)
.safeAreaPin(inset:)
.safeAreaPinHorizontally(insets:)
.safeAreaPinVertically(insets:)
.safeAreaPinBottom(inset:)
.safeAreaPinTop(inset:)
.safeAreaPinLeading(inset:)
.safeAreaPinTrailing(inset:)
 
// Readable Content Guide Pin:
.readableContentPin(insets:)
.readableContentPin(inset:)
.readableContentPinHorizontally(insets:)
.readableContentPinVertically(insets:)
.readableContentPinBottom(inset:)
.readableContentPinTop(inset:)
.readableContentPinLeading(inset:)
.readableContentPinTrailing(inset:)

extension ViewLayoutOption {
    static func halfHeight() -> ViewLayoutOption {
        ViewLayoutOption { view in
            guard let superview = view.superview else {
                return
            }
            
            NSLayoutConstraint.activate([
                view.heightAnchor.constraint(equalTo: superview.heightAnchor, multiplier: 0.5)
            ])
        }
    }
    
    static func halfWidth() -> ViewLayoutOption {
        ViewLayoutOption.withSuperview { view, superview in
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalTo: superview.widthAnchor, multiplier: 0.5)
            ])
        }
    }
}
 
*/
