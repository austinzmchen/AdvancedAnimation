//
//  ViewController.swift
//  AdvancedAnimation
//
//  Created by Austin Chen on 2018-04-14.
//  Copyright © 2018 Austin Chen. All rights reserved.
//

import UIKit

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

/*
 You can reverse a UIViewPropertyAnimator animation by setting its isReversed property, but there are some quirks. If you change the isReversed property of a running animator from false to true, the animate reverses, but you can't set the isReversed property from true to false while the animation is running and have it switch direction from reverse to forward "live". You have to first pause the animation, switch the isReversed flag, and then restart the animation. (To use an automotive analogy, you can switch from forward to reverse while moving, but you have to come to a comlete stop before you can switch from reverse back into drive.)
 */
class ViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var containerView: UIView!
    
    var commentVC: CommentViewController!
    
    var state: State = .collapsed
    var progressWhenInterrupted: CGFloat = 0
    private var animatorManager: InteractiveAnimatorDelegate!
    
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
        animatorManager = InteractiveAnimatorDelegate(owner: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embedVC" {
            commentVC = segue.destination as! CommentViewController
        }
    }

    // MARK: non-interactive
    @objc func tapped(recognizer: UITapGestureRecognizer) {
        animatorManager.animateOrReverseRunningTransition(state: state.nextState, duration: kDuration)
    }
    
    // MARK: interactive
    @objc func panned(recognizer: UIPanGestureRecognizer) {
        let t = recognizer.translation(in: view)
        var r = t.y / view.bounds.height
        
        switch recognizer.state {
        case .began:
            animatorManager.startInteractiveTransition(state: state.nextState, duration: kDuration)
        case .changed:
            r = state.nextState == .expanded ? -r : r
            animatorManager.updateInteractiveTransition(fractionComplete: r + progressWhenInterrupted)
        case .ended:
            let cancel = abs(r) < 0.2
            animatorManager.continueInteractiveTransition(cancel: cancel)
        default:
            break
        }
    }
}

let kDuration: Double = 3.0
let kHeight: CGFloat = 50.0
