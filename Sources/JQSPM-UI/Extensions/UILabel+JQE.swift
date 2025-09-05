//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2024/10/17.
//

import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if canImport(UIKit)

// 定义关联对象的键
struct LabelAssociatedKeys {
    nonisolated(unsafe) static var actionHandler: UnsafeRawPointer = UnsafeRawPointer(bitPattern: "actionHandler".hashValue)!
}

public extension UILabel{

    /// 转化富文本：设置文本行距
    /// - Parameter spacing: 行距
    func jq_coverToParagraph(_ spacing:CGFloat){

        var mutableAttributeString:NSMutableAttributedString!
        if attributedText == nil {
            mutableAttributeString = NSMutableAttributedString(attributedString: NSAttributedString(string: text ?? ""))
        }else{
            mutableAttributeString = NSMutableAttributedString(attributedString: attributedText!)
        }

        let paraph = NSMutableParagraphStyle()
        paraph.lineSpacing = spacing

        //样式属性集合
        let attributes = [NSAttributedString.Key.font:font,
                          NSAttributedString.Key.paragraphStyle: paraph]

        mutableAttributeString.addAttributes(attributes as [NSAttributedString.Key : Any], range: NSRange(location: 0, length: text!.count))
        attributedText = mutableAttributeString
    }


    /// 富文本:字体
    /// - Parameter font: 字体
    func jq_coverToFont(_ font:UIFont){
        var mutableAttributeString:NSMutableAttributedString!
        if attributedText == nil {
            mutableAttributeString = NSMutableAttributedString(attributedString: NSAttributedString(string: text ?? ""))
        }else{
            mutableAttributeString = NSMutableAttributedString(attributedString: attributedText!)
        }

        //样式属性集合
        let attributes = [NSAttributedString.Key.font:font]

        mutableAttributeString.addAttributes(attributes as [NSAttributedString.Key : Any], range: NSRange(location: 0, length: text!.count))
        attributedText = mutableAttributeString
    }

    /// 给文本添加阴影效果
    /// - Parameters:
    ///   - radius: 阴影半径
    ///   - size: 大小
    ///   - shadowColor: 阴影颜色
    func jq_fontShadow(radius:CGFloat = 1.0,size:CGSize = CGSize(width: 1, height: 1),shadowColor:UIColor){
        let attribute = NSMutableAttributedString(string: self.text ?? "")
        let shadow  = NSShadow()
        shadow.shadowBlurRadius = radius
        shadow.shadowOffset = size
        shadow.shadowColor = UIColor.black
        attribute.addAttribute(.shadow, value: shadow, range: NSRange(location: 0, length: self.text?.count ?? 0))
        attributedText = attribute
    }


    /// 获取行数，和每行类容 【推荐】
    /// - Returns: count为行数，item为每行类容
    func jq_linesOfString() -> [String] {
        var strings: [String] = []
        guard let text = text,
              let font = font else { return [] }
        let attstr = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.font: font])

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        attstr.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, text.count))

        let frameSetter = CTFramesetterCreateWithAttributedString(attstr as CFAttributedString)

        let path = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width: frame.size.width, height: 110))

        let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, 0), path, nil)

        if let lines = CTFrameGetLines(frame) as? [CTLine] {
            lines.forEach({
                let linerange = CTLineGetStringRange($0)
                let range = NSMakeRange(linerange.location, linerange.length)
                let string = (text as NSString).substring(with: range)
                strings.append(string)
            })
        }
        return strings
    }


    /// 处理富文本中，URL的点击事件
    func tapURLAction(_ handler: @escaping(URL)->Void){
        let uITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapGesAction))
        self.addGestureRecognizer(uITapGestureRecognizer)
        self.isUserInteractionEnabled = true
        objc_setAssociatedObject(self, &LabelAssociatedKeys.actionHandler,handler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }


    @objc private func tapGesAction(_ gesture:UITapGestureRecognizer){

        guard let attributedText = self.attributedText,
              let gestureView = gesture.view as? UILabel
        else { return }

        // 创建 NSLayoutManager 来处理文本布局
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        let textStorage = NSTextStorage(attributedString: attributedText)

        // 配置文本容器
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = 0
        textContainer.lineBreakMode = self.lineBreakMode

        // 计算点击位置
        let locationOfTouchInLabel = gesture.location(in: gestureView)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(
            x: (gestureView.bounds.width - textBoundingBox.width) * 0.5 - textBoundingBox.origin.x,
            y: (gestureView.bounds.height - textBoundingBox.height) * 0.5 - textBoundingBox.origin.y
        )
        let locationOfTouchInTextContainer = CGPoint(
            x: locationOfTouchInLabel.x - textContainerOffset.x,
            y: locationOfTouchInLabel.y - textContainerOffset.y
        )

        // 找到点击的字符索引
        let indexOfCharacter = layoutManager.characterIndex(
            for: locationOfTouchInTextContainer,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )

        // 检查该位置是否有链接属性
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.link, in: range, options: []) { value, range, _ in
            if indexOfCharacter >= range.location && indexOfCharacter < NSMaxRange(range),
               let url = value as? URL,let handler = objc_getAssociatedObject(self, &LabelAssociatedKeys.actionHandler) as? (URL)->Void{
                    handler(url)
            }
        }
    }
}
#endif
