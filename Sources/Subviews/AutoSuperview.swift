import UIKit

open class Superview: UIView, AddsSubviews {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.resolveSubviews()
    }
    
    public init() {
        super.init(frame: .zero)
        self.resolveSubviews()
    }
    
    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func resolveSubviews() {
        resolveAllEnclosedProperties()
    }
}
