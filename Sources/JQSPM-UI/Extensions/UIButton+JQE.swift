//
//  UIButton+Extension.swift
//  JQTools
//
//  Created by 杨锴 on 2020/3/15.
//
#if canImport(UIKit)
import UIKit

// 定义关联对象的键
struct AssociatedKeys {
    nonisolated(unsafe) static var actionHandler: UnsafeRawPointer = UnsafeRawPointer(bitPattern: "actionHandler".hashValue)!
    nonisolated(unsafe) static var backgroundColorDictionary: UnsafeRawPointer = UnsafeRawPointer(bitPattern: "backgroundColorDictionary".hashValue)!
}

public extension UIButton{
    enum ButtonOriginType {
        case ImgDefault
        case ImgRight
        case ImgTop
        case ImgBottom
    }

    /// 按钮设置图片方向
    func jq_buttonType(_ type:ButtonOriginType,padding:CGFloat){
        if type == .ImgDefault{
            self.imageEdgeInsets = UIEdgeInsets(top: 0, left: -0.5 * padding, bottom: 0, right: 0.5 * padding)
            self.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0.5 * padding, bottom: 0, right: -0.5 * padding)
        }

        if  type == .ImgRight {
            let imageW = self.imageView?.image?.size.width
            let titleW = self.titleLabel?.frame.size.width
            let imageOffset = titleW! + 0.5 * padding
            let titleOffset = imageW! + 0.5 * padding
            self.imageEdgeInsets = UIEdgeInsets(top: 0, left: imageOffset, bottom: 0, right: -imageOffset)
            self.titleEdgeInsets = UIEdgeInsets(top: 0,left: -titleOffset,bottom: 0,right: titleOffset)
        }

        if  type == .ImgTop {
            let imageW = self.imageView?.frame.size.width
            let imageH = self.imageView?.frame.size.height
            let titleIntrinsicContentSizeW = self.titleLabel?.intrinsicContentSize.width
            let titleIntrinsicContentSizeH = self.titleLabel?.intrinsicContentSize.height
            self.imageEdgeInsets = UIEdgeInsets(top: -titleIntrinsicContentSizeH! - padding,left: 0,bottom: 0,right: -titleIntrinsicContentSizeW!)
            self.titleEdgeInsets = UIEdgeInsets(top: 0,left: -imageW!,bottom: -imageH! - padding,right: 0)
        }

        if  type == .ImgBottom {
            let imageW = self.imageView?.frame.size.width
            let imageH = self.imageView?.frame.size.height
            let titleIntrinsicContentSizeW = self.titleLabel?.intrinsicContentSize.width
            let titleIntrinsicContentSizeH = self.titleLabel?.intrinsicContentSize.height
            self.imageEdgeInsets = UIEdgeInsets(top: titleIntrinsicContentSizeH! + padding,left: 0,bottom: 0,right: -titleIntrinsicContentSizeW!)
            self.titleEdgeInsets = UIEdgeInsets(top: 0,left: -imageW!,bottom: -imageH! + padding,right: 0)
        }
    }

    /// 开启定时器
    /// - Parameters:
    ///   - t: 倒计时时间 默认59秒
    ///   - defultTitle: 默认标题
    func jq_openCountDown(_ t:Int = 59,defultTitle:String = "获取验证码",sendingClouse:(()->Void)? = nil,completeClouse:(()->Void)? = nil){
        var time = t //倒计时时间
        let queue = DispatchQueue.global()
        let timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
        timer.schedule(wallDeadline: DispatchWallTime.now(), repeating: .seconds(1));
        timer.setEventHandler(handler: {
            if time <= 0 {
                timer.cancel()
                DispatchQueue.main.async(execute: {
                    completeClouse?()
                    self.setTitle(defultTitle, for: .normal)
                    self.isUserInteractionEnabled = true
                });
            }else {
                DispatchQueue.main.async(execute: {
                    sendingClouse?()
                    self.setTitle("\(time)s后可重新获取", for: .normal)
                    self.isUserInteractionEnabled = false
                });
            }
            time -= 1
        });
        timer.resume()
    }

    /// 重新绘制颜色
    func jq_tintColor(_ color:UIColor){
        var tinImage = self.imageView?.image
        if #available(iOS 13.0, *) {
            tinImage = self.imageView?.image?.withTintColor(color)
        } else {
            tinImage = self.imageView?.image?.jq_imageWithTintColor(color: color)
        }

        if tinImage != nil{
            setImage(tinImage, for: .normal)
        }
    }

    /// 设置GIF动态图
    /// - Parameters:
    ///   - name: 动态名称
    ///   - duration: 持续时间
    func jq_gif(name:String,duration:TimeInterval = 0.1){
        let gifImageUrl = Bundle.main.url(forResource: name, withExtension: nil)

        let gifSource = CGImageSourceCreateWithURL( gifImageUrl! as CFURL, nil)
        let gifcount = CGImageSourceGetCount(gifSource!)
        var images = [UIImage]()
        for i in 0..<gifcount{
            let imageRef = CGImageSourceCreateImageAtIndex(gifSource!, i, nil)
            let image = UIImage(cgImage: imageRef!)
            images.append(image)
        }
        setImage(UIImage.animatedImage(with: images, duration: duration), for: .normal)
    }

    /// 添加等待指示器
    func jq_startLoading(color:UIColor,offset:Double = 5) {
        // 创建活动指示器
        if #available(iOS 13.0, *) {
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.color = color
            spinner.startAnimating()
            spinner.tag = 1202

            // 添加到按钮上
            self.addSubview(spinner)

            spinner.translatesAutoresizingMaskIntoConstraints = false

            if let titleLabel = self.titleLabel{
                NSLayoutConstraint.activate([
                    spinner.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor,constant: offset)
                ])
            }
            // 禁用按钮
            self.isEnabled = false
        } else {
            // Fallback on earlier versions
        }

    }

    ///停止等待指示器
    func jq_stopLoading() {
        viewWithTag(1202)?.removeFromSuperview()
        // 启用按钮
        self.isEnabled = true
    }
}

public extension UIButton {
    /// 添加闭包形式的点击事件
    func click(_ handler: @escaping (UIButton)->Void) {
        // 存储闭包
        objc_setAssociatedObject(
            self,
            &AssociatedKeys.actionHandler,
            handler,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        // 添加目标动作
        addTarget(self, action: #selector(handleAction), for: .touchUpInside)
    }

    // 处理点击事件的方法
    @objc private func handleAction() {
        // 获取存储的闭包并执行
        if let handler = objc_getAssociatedObject(
            self,
            &AssociatedKeys.actionHandler
        ) as? (UIButton)->Void {
            handler(self)
        }
    }
}

public extension UIButton{
    func setBackgroundColor(_ color:UIColor,for:UIControl.State){


    }
}
#endif
