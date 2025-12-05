//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2025/11/19.
//

import Foundation
import UIKit
public class DrawAnimation:NSObject,UIViewControllerAnimatedTransitioning{
    let ScreenW = UIScreen.main.bounds.size.width
    let ScreenH = UIScreen.main.bounds.size.height

    public enum AniDrawState {
        case show,close,none
    }

    public enum AniDrawForm{
        case left,right
    }

    public var aniState:AniDrawState = .none
    public var aniDrawForm:AniDrawForm = .left
    public var duration = 0.35

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        if aniState == .show{
            let toView = transitionContext.view(forKey: UITransitionContextViewKey.to)
            containerView.addSubview(toView!)
            switch aniDrawForm {
            case .left:
                toView?.frame = CGRect(x: -ScreenW, y: 0, width: ScreenW, height: ScreenH)
            case .right:
                toView?.frame = CGRect(x: ScreenW, y: 0, width: ScreenW, height: ScreenH)
            }
            toView?.backgroundColor = .clear

            UIView.animate(withDuration: duration) {[weak self] in
                guard let weakSelf = self else { return }
                toView?.frame = CGRect(x: 0, y: 0, width: weakSelf.ScreenW, height: weakSelf.ScreenH)
            } completion: { _ in
                transitionContext.completeTransition(true)
            }
        }else{
            let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from)
            UIView.animate(withDuration: duration) { [weak self] in
                guard let weakSelf = self else { return }
                switch weakSelf.aniDrawForm {
                case .left:
                    fromView?.frame = CGRect(x: -weakSelf.ScreenW, y: 0, width: weakSelf.ScreenW, height: weakSelf.ScreenH)
                case .right:
                    fromView?.frame = CGRect(x: weakSelf.ScreenW, y: 0, width: weakSelf.ScreenW, height: weakSelf.ScreenH)
                }
            } completion: { _ in
                transitionContext.completeTransition(true)
            }
        }
    }
}
