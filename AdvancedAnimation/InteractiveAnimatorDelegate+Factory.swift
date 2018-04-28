//
//  InteractiveAnimatorDelegate.swift
//  AdvancedAnimation
//
//  Created by Austin Chen on 2018-04-27.
//  Copyright © 2018 Austin Chen. All rights reserved.
//

import UIKit

extension InteractiveAnimatorDelegate {
    
    func setupFrameAnimator(state: State, duration: TimeInterval) -> UIViewPropertyAnimator {
        let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
            switch state {
            case .expanded:
                var b = self.owner.view.bounds
                b.origin.y = 100
                self.owner.containerView.frame = b
            case .collapsed:
                var f = self.owner.containerView.frame
                f.origin.y = self.owner.view.bounds.height - kHeight
                f.size.height = kHeight
                self.owner.containerView.frame = f
            }
        }
        frameAnimator.addCompletion{ position in
            switch position {
            case .end:// allows only set new state when finished (not cancelled)
                self.owner.state = self.owner.state.nextState
            default:
                break
            }
            
            self.runningAnimators.removeAll()
        }
        return frameAnimator
    }
    
    func setupBlurAnimator(state: State, duration: TimeInterval) -> UIViewPropertyAnimator {
        let blurAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut)
        if #available(iOS 11, *) {
            blurAnimator.scrubsLinearly = false
        }
        blurAnimator.addAnimations {
            switch state {
            case .expanded:
                self.owner.blurView.effect = UIBlurEffect(style: .dark)
            case .collapsed:
                self.owner.blurView.effect = nil
            }
        }
        return blurAnimator
    }
    
    func setupViewMorphingAnimator(state: State, duration: TimeInterval) -> [UIViewPropertyAnimator] {
        let kOpenTopMargin: CGFloat = 20
        let y = kOpenTopMargin - 0.5 * owner.commentVC.closedTitleLabel.bounds.height
        
        let commentVC = owner.commentVC
        let scaleAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
            switch state {
            case .expanded:
                commentVC?.closedTitleLabel.transform = CGAffineTransform(scaleX: 1.6, y: 1.6).concatenating(CGAffineTransform(translationX: 0, y: 20))
                commentVC?.openTitleLabel.transform = CGAffineTransform(scaleX: 1.6, y: 1.6).concatenating(CGAffineTransform(translationX: 0, y: 20))
                commentVC?.openTitleLabel.alpha = 1
                commentVC?.closedTitleLabel.alpha = 0
            case .collapsed:
                commentVC?.closedTitleLabel.transform = .identity
                commentVC?.openTitleLabel.transform = .identity
                commentVC?.openTitleLabel.alpha = 0
                commentVC?.closedTitleLabel.alpha = 1
            }
        }
        
        // an animator for the title that is transitioning into view
        let inTitleAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeIn, animations: {
            switch state {
            case .expanded:
                commentVC?.openTitleLabel.alpha = 1
            case .collapsed:
                commentVC?.closedTitleLabel.alpha = 1
            }
        })
        inTitleAnimator.scrubsLinearly = false
        
        // an animator for the title that is transitioning out of view
        let outTitleAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeOut, animations: {
            switch state {
            case .expanded:
                commentVC?.closedTitleLabel.alpha = 0
            case .collapsed:
                commentVC?.openTitleLabel.alpha = 0
            }
        })
        outTitleAnimator.scrubsLinearly = false
        
        return [scaleAnimator, inTitleAnimator, outTitleAnimator]
    }
    
    func setupCornerAnimator(state: State, duration: TimeInterval) -> UIViewPropertyAnimator {
        owner.containerView.clipsToBounds = true
        // Corner mask
        if #available(iOS 11, *) {
            owner.containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
        let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
            switch state {
            case .expanded:
                self.owner.containerView.layer.cornerRadius = 12
            case .collapsed:
                self.owner.containerView.layer.cornerRadius = 0
            }
        }
        return cornerRadiusAnimator
    }
    
    func setupBackButtonAnimator(state: State, duration: TimeInterval) -> UIViewPropertyAnimator {
        // back button rotate
        let backButtonAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
            switch state {
            case .expanded:
                self.owner.backButton.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
            case .collapsed:
                self.owner.backButton.transform = CGAffineTransform.identity
            }
        }
        return backButtonAnimator
    }
}
