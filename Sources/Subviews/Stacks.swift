import UIKit

internal class TouchTransparentStackView: UIStackView {
    override open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let subview = super.hitTest(point, with: event)
        return subview !== self ? subview : nil
    }
}

internal final class HorizontalStackView: TouchTransparentStackView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.axis = .horizontal
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

internal final class VerticalStackView: TouchTransparentStackView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.axis = .vertical
    }
    
    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Specialized / Enclosed

public func _StackView<EnclosingSelf: AddsSubviews, Stack: UIStackView>(
    _ stackViewType: Stack.Type,
    @StackBuilder _ subviews: @escaping (EnclosingSelf) -> [UIView]
//    setup: @escaping (UIStackView) -> Void
) -> (EnclosingSelf) -> UIStackView {
    return { (self) in
        let stack = Stack(frame: .zero)
        let resolved = subviews(self)
        for subview in resolved {
            stack.addArrangedSubview(subview)
        }
//        setup(stack)
        return stack
    }
}

public func _VerticalStack<EnclosingSelf: AddsSubviews>(
    @StackBuilder _ subviews: @escaping (_ `self`: EnclosingSelf) -> [UIView]
) -> (EnclosingSelf) -> UIStackView {
    _StackView(VerticalStackView.self, subviews)
}

//fileprivate func _VerticalStack<EnclosingSelf: AddsSubviews>(
//    @StackBuilder _ subviews: @escaping (EnclosingSelf) -> [UIView],
//    setup: @escaping (UIStackView) -> Void
//) -> (EnclosingSelf) -> UIStackView {
//    StackView(VerticalStackView.self, subviews, setup: setup)
//}

public func _HorizontalStack<EnclosingSelf: AddsSubviews>(
    @StackBuilder _ subviews: @escaping (_ `self`: EnclosingSelf) -> [UIView]
) -> (EnclosingSelf) -> UIStackView {
    _StackView(HorizontalStackView.self, subviews)
}

//fileprivate func _HorizontalStack<EnclosingSelf: AddsSubviews>(
//    @StackBuilder _ subviews: @escaping (EnclosingSelf) -> [UIView],
//    setup: @escaping (UIStackView) -> Void
//) -> (EnclosingSelf) -> UIStackView {
//    StackView(HorizontalStackView.self, subviews, setup: setup)
//}

@resultBuilder
public enum StackBuilder {
    public typealias Expression = UIView

    public typealias Component = [UIView]

    public static func buildExpression(_ expression: Expression) -> Component {
        [expression]
    }

    public static func buildExpression(_ expression: Expression?) -> Component {
        expression.map({ [$0] }) ?? []
    }

    public static func buildBlock(_ children: Component...) -> Component {
        children.flatMap({ $0 })
    }

    public static func buildOptional(_ children: Component?) -> Component {
        children ?? []
    }

    public static func buildBlock(_ component: Component) -> Component {
        component
    }

    public static func buildEither(first child: Component) -> Component {
        child
    }

    public static func buildEither(second child: Component) -> Component {
        child
    }
}
