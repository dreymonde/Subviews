import XCTest
@testable import Subviews
import UIKit

private final class ToggleControl: UIControl { }

private final class Content: Superview {
    let header = UILabel()
    let footer = UILabel()
    let rows: [UIStackView]
    let toggles: [ToggleControl]
    let missingView: UIView? = nil

    init(count: Int) {
        self.rows = (0 ..< count).map({ _ in UIStackView() })
        self.toggles = (0 ..< count).map({ _ in ToggleControl() })
        super.init()
    }
}

private final class PageGrid: Superview {
    let rows: [UIStackView]

    init(rowCount: Int) {
        self.rows = (0 ..< rowCount).map({ _ in UIStackView() })
        super.init()
    }

    @Subview(.pin)
    var grid = _VerticalStack { (self) in
        for row in self.rows {
            row
        }
    }
}

final class StackBuilderTests: XCTestCase {
    func testForLoop() {
        let content = Content(count: 3)
        let stack = _VerticalStack { (self: Content) in
            for row in self.rows {
                row
            }
        }(content)
        XCTAssertEqual(stack.arrangedSubviews, content.rows)
    }

    func testForLoopOverEmptyArray() {
        let content = Content(count: 0)
        let stack = _VerticalStack { (self: Content) in
            for row in self.rows {
                row
            }
        }(content)
        XCTAssertTrue(stack.arrangedSubviews.isEmpty)
    }

    func testForLoopInsideSubview() {
        let pageGrid = PageGrid(rowCount: 4)
        XCTAssertEqual(pageGrid.grid.arrangedSubviews, pageGrid.rows)
        XCTAssertTrue(pageGrid.grid.superview === pageGrid)
    }

    func testArrayExpressionOfStackViews() {
        let content = Content(count: 3)
        let stack = _HorizontalStack { (self: Content) in
            self.rows
        }(content)
        XCTAssertEqual(stack.arrangedSubviews, content.rows)
    }

    func testArrayExpressionOfCustomControls() {
        let content = Content(count: 2)
        let stack = _VerticalStack { (self: Content) in
            self.toggles
        }(content)
        XCTAssertEqual(stack.arrangedSubviews, content.toggles)
    }

    func testSingleViewsMixedWithLoop() {
        let content = Content(count: 2)
        let stack = _VerticalStack { (self: Content) in
            self.header
            for row in self.rows {
                row
            }
            self.missingView
            self.footer
        }(content)
        let expected: [UIView] = [content.header] + content.rows + [content.footer]
        XCTAssertEqual(stack.arrangedSubviews, expected)
    }

    func testSingleViewsMixedWithArrayExpression() {
        let content = Content(count: 2)
        let stack = _VerticalStack { (self: Content) in
            self.header
            self.toggles
            self.footer
        }(content)
        let expected: [UIView] = [content.header] + content.toggles + [content.footer]
        XCTAssertEqual(stack.arrangedSubviews, expected)
    }

    func testAvailabilityCheck() {
        let content = Content(count: 0)
        let stack = _VerticalStack { (self: Content) in
            if #available(iOS 13.0, *) {
                self.header
            }
        }(content)
        XCTAssertEqual(stack.arrangedSubviews, [content.header])
    }
}
