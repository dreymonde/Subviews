import UIKit

public typealias ParentViewController = AutoParentViewController

open class AutoParentViewController: UIViewController, AddsSubviews, AddsChildrenViewControllers {
    open override func viewDidLoad() {
        super.viewDidLoad()
        resolveSubviewsAndChildren()
    }
    
    private func resolveSubviewsAndChildren() {
        resolveAllEnclosedProperties()
    }
}
