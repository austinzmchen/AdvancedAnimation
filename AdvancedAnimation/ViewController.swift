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

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var containerView: UIView!
    
    var state: State = .collapsed
    
    enum State {
        case expanded
        case collapsed
        
        var nextState: State {
            switch self {
            case .expanded:
                return .collapsed
            case .collapsed:
                return .expanded
            }
        }
    }
    
    var runningAnimators = [UIViewPropertyAnimator]()
    private var commentVC: CommentViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(recognizer:)) )
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panned(recognizer:)) )
        containerView.addGestureRecognizer(tapGesture)
        containerView.addGestureRecognizer(panGesture)
        
        // initial values
        blurView.effect = nil
        
        self.commentVC.openTitleLabel.alpha = 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedVC" {
            commentVC = segue.destination as! CommentViewController
        }
    }

    // MARK: non-interactive
    @objc func tapped(recognizer: UITapGestureRecognizer) {
        animateOrReverseRunningTransition(state: state.nextState, duration: kDuration)
    }
    
    var interrupted = false
    var fComplete: CGFloat = 0
    var progressWhenInterrupted: CGFloat = 0
    
    // MARK: interactive
    @objc func panned(recognizer: UIPanGestureRecognizer) {
        let t = recognizer.translation(in: view)
        var r = t.y / view.bounds.height
        
        switch recognizer.state {
        case .began:
            startInteractiveTransition(state: state.nextState, duration: kDuration)
        case .changed:
            r = state.nextState == .expanded ? -r : r
            updateInteractiveTransition(fractionComplete: r + progressWhenInterrupted)
        case .ended:
            let cancel = abs(r) < 0.2
            continueInteractiveTransition(cancel: cancel)
        default:
            break
        }
    }
    
    func animateTransitionIfNeeded(state: State, duration: TimeInterval) {
        if runningAnimators.isEmpty {
            // frame
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    var b = self.view.bounds
                    b.origin.y = 100
                    self.containerView.frame = b
                case .collapsed:
                    var f = self.containerView.frame
                    f.origin.y = self.view.bounds.height - kHeight
                    f.size.height = kHeight
                    self.containerView.frame = f
                }    
            }
            frameAnimator.addCompletion{ position in
                switch position {
                case .end:// allows only set new state when finished (not cancelled)
                    self.state = self.state.nextState
                default:
                    break
                }
                
                self.runningAnimators.removeAll()
            }
            runningAnimators.append(frameAnimator)
            
            // blur
            let blurAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut)
            if #available(iOS 11, *) {
                blurAnimator.scrubsLinearly = false
            }
            blurAnimator.addAnimations {
                switch state {
                case .expanded:
                    self.blurView.effect = UIBlurEffect(style: .dark)
                case .collapsed:
                    self.blurView.effect = nil
                }
            }
            runningAnimators.append(blurAnimator)
            
            // label
            let kOpenTopMargin: CGFloat = 20
            let y = kOpenTopMargin - 0.5 * self.commentVC.closedTitleLabel.bounds.height
            
            let scaleAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.commentVC.closedTitleLabel.transform = CGAffineTransform(scaleX: 1.6, y: 1.6).concatenating(CGAffineTransform(translationX: 0, y: 20))
                    self.commentVC.openTitleLabel.transform = CGAffineTransform(scaleX: 1.6, y: 1.6).concatenating(CGAffineTransform(translationX: 0, y: 20))
                    self.commentVC.openTitleLabel.alpha = 1
                    self.commentVC.closedTitleLabel.alpha = 0
                case .collapsed:
                    self.commentVC.closedTitleLabel.transform = .identity
                    self.commentVC.openTitleLabel.transform = .identity
                    self.commentVC.openTitleLabel.alpha = 0
                    self.commentVC.closedTitleLabel.alpha = 1
                }
            }
            runningAnimators.append(scaleAnimator)
            
            // an animator for the title that is transitioning into view
            let inTitleAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeIn, animations: {
                switch state {
                case .expanded:
                    self.commentVC.openTitleLabel.alpha = 1
                case .collapsed:
                    self.commentVC.closedTitleLabel.alpha = 1
                }
            })
            inTitleAnimator.scrubsLinearly = false
            runningAnimators.append(inTitleAnimator)
            
            // an animator for the title that is transitioning out of view
            let outTitleAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeOut, animations: {
                switch state {
                case .expanded:
                    self.commentVC.closedTitleLabel.alpha = 0
                case .collapsed:
                    self.commentVC.openTitleLabel.alpha = 0
                }
            })
            outTitleAnimator.scrubsLinearly = false
            runningAnimators.append(outTitleAnimator)
            
            // corner
            containerView.clipsToBounds = true
            // Corner mask
            if #available(iOS 11, *) {
                containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            }
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.containerView.layer.cornerRadius = 12
                case .collapsed:
                    self.containerView.layer.cornerRadius = 0
                }
            }
            runningAnimators.append(cornerRadiusAnimator)
            
            // back button rotate
            let backButtonAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                switch state {
                case .expanded:
                        self.backButton.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
                case .collapsed:
                        self.backButton.transform = CGAffineTransform.identity
                }
            }
            runningAnimators.append(backButtonAnimator)
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
        progressWhenInterrupted = runningAnimators.first?.fractionComplete ?? 0
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

fileprivate let kDuration: Double = 3.0
fileprivate let kHeight: CGFloat = 50.0
