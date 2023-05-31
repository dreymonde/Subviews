import XCTest
@testable import Subviews
import UIKit

final class ViewA: AutoSuperview {
    let title = "Aaaa"
    
    @Subview(.pin)
    var label = UILabel()
    
    @Subview(.pin)
    var button = { (self) in UILabel() }
}

final class BoldLabel: AutoSuperview {
    let boldText: String
    
    init(boldText: String) {
        self.boldText = boldText
        super.init()
    }
    
    @Subview(.pin, {
        $0.text = $1.boldText
    })
    private var label = UILabel()
}

final class BoldStack: AutoSuperview {
    let line1: String
    let line2: String
    
    @Subview(.pin, {
        $0.axis = .vertical
    })
    var stack = UIStackView()
    
    @ArrangedSubview(of: \.stack)
    var line1Label = { BoldLabel(boldText: $0.line1) }
    
    @ArrangedSubview(of: \.stack)
    var line2Label = { BoldLabel(boldText: $0.line2) }
        
    init(line1: String, line2: String) {
        self.line1 = line1
        self.line2 = line2
        super.init()
    }
}

final class SubviewsTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let viewA = ViewA()
        XCTAssertEqual(viewA.subviews.count, 2)
    }
}
