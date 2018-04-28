//
//  InteractiveAnimatorDelegate.swift
//  AdvancedAnimation
//
//  Created by Austin Chen on 2018-04-27.
//  Copyright © 2018 Austin Chen. All rights reserved.
//

import UIKit

class InteractiveAnimatorDelegate {
    let owner: ViewController
    
    init(owner: ViewController) {
        self.owner = owner
    }
    
    var runningAnimators = [UIViewPropertyAnimator]()
    
    func animateTransitionIfNeeded(state: State, duration: TimeInterval) {
        if runningAnimators.isEmpty {
            // frame
            let fa = setupFrameAnimator(state: state, duration: duration)
            runningAnimators.append(fa)
            
            // blur
            let ba = setupBlurAnimator(state: state, duration: duration)
            runningAnimators.append(ba)
            
            // label
            let va = setupViewMorphingAnimator(state: state, duration: duration)
            runningAnimators.append(contentsOf: va)
            
            // back button
            let bba = setupBackButtonAnimator(state: state, duration: duration)
            runningAnimators.append(bba)
            
            // corner
            let ca = setupCornerAnimator(state: state, duration: duration)
            runningAnimators.append(ca)
        }
    }
    
    func animateOrReverseRunningTransition(state: State, duration: TimeInterval) {
        if runningAnimators.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
            runningAnimators.forEach({ $0.startAnimation() })
        } else {
            for animator in runningAnimators {
                animator.isReversed = !animator.isReversed
            }
        }
    }
    
    func startInteractiveTransition(state: State, duration: TimeInterval) {
        animateTransitionIfNeeded(state: state, duration: duration)
        runningAnimators.forEach { $0.pauseAnimation() }
        owner.progressWhenInterrupted = runningAnimators.first?.fractionComplete ?? 0
    }
    
    func updateInteractiveTransition(fractionComplete: CGFloat) {
        runningAnimators.forEach {
            $0.fractionComplete = fractionComplete
        }
    }
    
    func continueInteractiveTransition(cancel: Bool) {
        if cancel {
            runningAnimators.forEach {
                $0.isReversed = !$0.isReversed
                $0.continueAnimation(withTimingParameters: nil, durationFactor: 0)
            }
        } else {
            runningAnimators.forEach {
                $0.continueAnimation(withTimingParameters: nil, durationFactor: 0)
            }
        }
    }
}
