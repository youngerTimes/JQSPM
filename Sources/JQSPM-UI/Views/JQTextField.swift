//
//  JQTextField.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/12/1.
//

import UIKit

public class JQTextField: UITextField {

    //限制输入长度
    public var maxLength:Int = 0

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        // 添加编辑改变事件监听
        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }

    // 文本改变时的回调方法
    @objc private func textDidChange() {
        // 当设置了最大长度且当前文本长度超过最大长度时
        guard maxLength > 0, let text = text, text.count > maxLength else {
            return
        }

        // 截取最大长度内的文本
        let endIndex = text.index(text.startIndex, offsetBy: maxLength)
        self.text = String(text[..<endIndex])
    }
}
