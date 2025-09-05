//
//  UIFont+JQExtension.swift
//  JQTools
//
//  Created by 无故事王国 on 2021/1/20.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif


#if canImport(UIKit)
public extension UIFont{

}


//================================================================================
extension UILabel {
    func fontMetrics() {
        let font = self.font ?? UIFont.preferredFont(forTextStyle: .body)
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        let scaledFont = fontMetrics.scaledFont(for: font)
        self.font = scaledFont
        self.adjustsFontForContentSizeCategory = true
    }
}

extension UIButton {
    func fontMetrics() {
        let font =  self.titleLabel?.font ?? UIFont.preferredFont(forTextStyle: .body)
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        let scaledFont = fontMetrics.scaledFont(for: font)
        self.titleLabel?.font = scaledFont
        self.titleLabel?.adjustsFontForContentSizeCategory = true
    }
}

extension UITextField {
    func fontMetrics() {
        let font = self.font ?? UIFont.preferredFont(forTextStyle: .body)
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        let scaledFont = fontMetrics.scaledFont(for: font)
        self.font = scaledFont
        self.adjustsFontForContentSizeCategory = true
    }
}


extension UITextView {
    func fontMetrics() {
        let font = self.font ?? UIFont.preferredFont(forTextStyle: .body)
        let fontMetrics = UIFontMetrics(forTextStyle: .body)
        let scaledFont = fontMetrics.scaledFont(for: font)
        self.font = scaledFont
        self.adjustsFontForContentSizeCategory = true
    }
}
#endif
