import UIKit

open class ParentViewController: UIViewController, AddsSubviews, AddsChildrenViewControllers {
    open override func viewDidLoad() {
        super.viewDidLoad()
        resolveSubviewsAndChildren()
    }
    
    private func resolveSubviewsAndChildren() {
        resolveAllEnclosedProperties()
    }
}
