//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/11/26.
//

import Foundation
import UIKit

public enum LLImageAlignment: Int {
    case left = 0
    case top
    case bottom
    case right
    case rightBottm
    case rightTop
}

public class LLButton: UIButton {

    public var imageAlignment: LLImageAlignment = .left
    public var spaceBetweenTitleAndImage: CGFloat = 0
    public var imageOffset:Double = 0

    public override func layoutSubviews() {
        super.layoutSubviews()

        let space: CGFloat = self.spaceBetweenTitleAndImage

        let titleW: CGFloat = self.titleLabel?.bounds.width ?? 0
        let titleH: CGFloat = self.titleLabel?.bounds.height ?? 0

        let imageW: CGFloat = self.imageView?.bounds.width ?? 0
        let imageH: CGFloat = self.imageView?.bounds.height ?? 0

        let btnCenterX: CGFloat = self.bounds.width / 2
        let imageCenterX: CGFloat = btnCenterX - titleW / 2
        let titleCenterX = btnCenterX + imageW / 2

        switch self.imageAlignment {
        case .top:
            titleEdgeInsets = UIEdgeInsets(top: imageH / 2 + space / 2, left: -(titleCenterX - btnCenterX), bottom: -(imageH/2 + space/2), right: titleCenterX-btnCenterX)
            imageEdgeInsets = UIEdgeInsets(top: -(titleH / 2 + space / 2), left: btnCenterX - imageCenterX, bottom: titleH / 2 + space / 2, right: -(btnCenterX - imageCenterX));
        case .left:
            titleEdgeInsets = UIEdgeInsets(top: 0, left: space / 2, bottom: 0, right: -space / 2);
            imageEdgeInsets = UIEdgeInsets(top: 0, left: -space / 2, bottom: 0, right: space);
        case .bottom:
            titleEdgeInsets = UIEdgeInsets(top: -(imageH / 2 + space / 2), left: -(titleCenterX - btnCenterX), bottom: imageH / 2 + space / 2, right: titleCenterX - btnCenterX);
            imageEdgeInsets = UIEdgeInsets(top: titleH / 2 + space / 2, left: btnCenterX - imageCenterX,bottom: -(titleH / 2 + space / 2), right: -(btnCenterX - imageCenterX));
        case .right:
            titleEdgeInsets = UIEdgeInsets(top: 0, left: -(imageW + space / 2), bottom: 0, right: imageW + space / 2);
            imageEdgeInsets = UIEdgeInsets(top: 0, left: titleW + space / 2, bottom: imageOffset, right: -(titleW + space / 2));
        case .rightBottm:
            titleEdgeInsets = UIEdgeInsets(top: 0, left: -(imageW + space / 2), bottom: 0, right: imageW + space / 2);
            imageEdgeInsets = UIEdgeInsets(top: 0, left: titleW + space / 2, bottom: -(titleH/2), right: -(titleW + space / 2));
        case .rightTop:
            titleEdgeInsets = UIEdgeInsets(top: 0, left: -(imageW + space / 2), bottom: 0, right: imageW + space / 2);
            imageEdgeInsets = UIEdgeInsets(top: 0, left: titleW + space / 2, bottom: (titleH/2), right: -(titleW + space / 2));
        }
    }
}
