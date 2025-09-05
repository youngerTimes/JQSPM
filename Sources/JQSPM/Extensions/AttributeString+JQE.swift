//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2024/11/15.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

extension NSMutableAttributedString:JQFisherCompatible{}

public extension JQFisher where Base:NSMutableAttributedString{

}

public extension NSAttributedString{

    /// 将HTML转化为富文本
    static func jq_convertHtml(_ html: String) -> NSAttributedString? {
        guard let data = html.data(using: .unicode) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
        } catch {
            return nil
        }
    }
}
