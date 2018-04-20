//
//  ViewController.swift
//  AdvancedAnimation
//
//  Created by Austin Chen on 2018-04-14.
//  Copyright © 2018 Austin Chen. All rights reserved.
//

import UIKit

/*
 You can reverse a UIViewPropertyAnimator animation by setting its isReversed property, but there are some quirks. If you change the isReversed property of a running animator from false to true, the animate reverses, but you can't set the isReversed property from true to false while the animation is running and have it switch direction from reverse to forward "live". You have to first pause the animation, switch the isReversed flag, and then restart the animation. (To use an automotive analogy, you can switch from forward to reverse while moving, but you have to come to a comlete stop before you can switch from reverse back into drive.)
 */
class ViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    var state: State = .Collapsed
    
    enum State {
        case Expanded
        case Collapsed
        
        var other: State {
            switch self {
            case .Expanded:
                return .Collapsed
            case .Collapsed:
                return .Expanded
            }
        }
    }
    
    var runningAnimators = [UIViewPropertyAnimator]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(recognizer:)) )
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panned(recognizer:)) )
        containerView.addGestureRecognizer(tapGesture)
        containerView.addGestureRecognizer(panGesture)
    }

    // MARK: non-interactive
    @objc func tapped(recognizer: UITapGestureRecognizer) {
        animateOrReverseRunningTransition(state: state.other, duration: kDuration)
    }
    
    var interrupted = false
    var fComplete: CGFloat = 0
    var progressWhenInterrupted: CGFloat = 0
    
    // MARK: interactive
    @objc func panned(recognizer: UIPanGestureRecognizer) {
        let t = recognizer.translation(in: view)
        let r = t.y / view.bounds.height
        
        switch recognizer.state {
        case .began:
            startInteractiveTransition(state: state.other, duration: kDuration)
            if interrupted {
                progressWhenInterrupted = fComplete // assume first animator represents all
//                print("progressWhenInterrupted: \(progressWhenInterrupted)")
            }
        case .changed:
//            print("r: \(r),    p: \(progressWhenInterrupted)")
            updateInteractiveTransition(fractionComplete: abs(r + progressWhenInterrupted))
        case .ended:
            fComplete = runningAnimators.first?.fractionComplete ?? 0
            progressWhenInterrupted = 0
            
            let cancel = abs(r) < 0.5
            continueInteractiveTransition(cancel: cancel)
            
            
        default:
            break
        }
    }
    
    func animateTransitionIfNeeded(state: State, duration: TimeInterval) {
        if runningAnimators.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .Expanded:
                    self.containerView.frame = self.view.bounds
                case .Collapsed:
                    var f = self.containerView.frame
                    f.origin.y = self.view.bounds.height - kHeight
                    f.size.height = kHeight
                    self.containerView.frame = f
                }    
            }
            frameAnimator.addCompletion{ _ in
                self.runningAnimators.removeAll()
                self.state = state
            }
            frameAnimator.startAnimation()
            runningAnimators.append(frameAnimator)
        }
    }
    
    func animateOrReverseRunningTransition(state: State, duration: TimeInterval) {
        if runningAnimators.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        } else {
            for animator in runningAnimators {
                animator.isReversed = !animator.isReversed
            }
        }
    }
    
    func startInteractiveTransition(state: State, duration: TimeInterval) {
        if runningAnimators.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .Expanded:
                    self.containerView.frame = self.view.bounds
                    print("expanded")
                case .Collapsed:
                    print("collapsed")
                    var f = self.containerView.frame
                    f.origin.y = self.view.bounds.height - kHeight
                    f.size.height = kHeight
                    self.containerView.frame = f
                }
            }
            frameAnimator.addCompletion{ _ in
                self.runningAnimators.removeAll()
                self.interrupted = false
            }
            frameAnimator.pauseAnimation()
            runningAnimators.append(frameAnimator)
        } else {
            self.interrupted = true
            runningAnimators.forEach{
                $0.pauseAnimation()
                $0.isReversed = false
            }
        }
    }
    
    func updateInteractiveTransition(fractionComplete: CGFloat) {
//        let p = containerView.bounds.height / view.bounds.height
        runningAnimators.forEach {
//            print("fractionComplete: \(fractionComplete)")
            $0.fractionComplete = fractionComplete
        }
    }
    
    func continueInteractiveTransition(cancel: Bool) {
        if cancel {
            runningAnimators.forEach {
                $0.isReversed = true
                $0.startAnimation()
            }
        } else {
            runningAnimators.forEach {
                state = state.other
                $0.continueAnimation(withTimingParameters: nil, durationFactor: 0)
            }
        }
    }
}

fileprivate let kDuration: Double = 3.0
fileprivate let kHeight: CGFloat = 50.0
