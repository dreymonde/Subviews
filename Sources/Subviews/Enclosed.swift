public protocol Enclosing { }
extension Enclosing {
    public func resolveAllEnclosedProperties() {
        let mirror = Mirror(reflecting: self)
        mirror.deepResolveEnclosing(self)
    }
}

extension Mirror {
    func deepResolveEnclosing(_ enclosing: Any) {
        for child in children {
            if let enclosed = child.value as? Enclosed {
                enclosed.deepResolveEnclosing(enclosing)
            }
        }
        
        if let parentMirror = superclassMirror, parentMirror.subjectType is Enclosing.Type {
            parentMirror.deepResolveEnclosing(enclosing)
        }
    }
}

public protocol Enclosed {
    func resolveEnclosing(_ enclosing: Any)
    var wrappedProperties: [Any] { get }
}

public extension Enclosed {
    func deepResolveEnclosing(_ enclosing: Any) {
        resolveEnclosing(enclosing)
        for wrapped in wrappedProperties {
            if let enclosed = wrapped as? Enclosed {
                enclosed.deepResolveEnclosing(enclosing)
            }
        }
    }
}

extension Enclosing {
    func enclose(@EnclosedBuilder _ builder: () -> [Enclosed]) {
        let enclosed = builder()
        for subview in enclosed {
            subview.resolveEnclosing(self)
        }
    }
}

#if swift(>=5.4)
@resultBuilder
public enum EnclosedBuilder {
    public typealias Expression = Enclosed
    public typealias Component = [Enclosed]

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
#else
@_functionBuilder
public enum EnclosedBuilder {
    public typealias Expression = Enclosed
    public typealias Component = [Enclosed]

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
#endif
