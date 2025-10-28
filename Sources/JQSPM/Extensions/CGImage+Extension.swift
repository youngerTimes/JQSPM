//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2024/12/17.
//

#if os(iOS)
import UIKit
#else
import AppKit
#endif

extension CGImage{
    func jq_rotated(byDegrees degrees: CGFloat) -> CGImage? {
        let radians = degrees * .pi / 180
        let transform = CGAffineTransform(rotationAngle: radians)

        var rect = CGRect(origin: .zero, size: CGSize(width: self.width, height: self.height))
        rect = rect.applying(transform)

        let colorSpace = self.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = self.bitmapInfo

        guard let context = CGContext(data: nil,
                                      width: Int(rect.width),
                                      height: Int(rect.height),
                                      bitsPerComponent: self.bitsPerComponent,
                                      bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }

        context.translateBy(x: rect.width / 2, y: rect.height / 2)
        context.rotate(by: radians)
        context.translateBy(x: -CGFloat(self.width) / 2, y: -CGFloat(self.height) / 2)

        context.draw(self, in: CGRect(x: 0, y: 0, width: CGFloat(self.width), height: CGFloat(self.height)))

        return context.makeImage()
    }
}
