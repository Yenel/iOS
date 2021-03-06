import UIKit

struct CornerStyle: Codable {
    typealias Radiux = CGFloat
    let radius: Radiux
}

// MARK: - Constant

extension CornerStyle {

    static var roundCornerStyle: CornerStyle { CornerStyle(radius: 8) }
}

// MARK: - UI Applier

extension CornerStyle {
     
    @discardableResult
    func applied(on view: UIView) -> UIView {
        apply(style: self)(view)
    }
}

@discardableResult
fileprivate func apply(style: CornerStyle) -> (UIView) -> UIView {
    return { view in
        view.layer.cornerRadius = style.radius
        return view
    }
}
