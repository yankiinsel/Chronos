//
//  TimerView.swift
//  Chronos
//
//  Created by Yanki Insel on 23.11.2018.
//  Copyright © 2018 Yanki Insel. All rights reserved.
//

import UIKit
import Material
import AudioToolbox

protocol TimerViewDelegate {
    func changeColor(mood: Mood)
}

// MARK: Variables

class CRTimerView: NibView {
    
    var gradientMultiplier: CGFloat = 3
    
    var animator: UIViewPropertyAnimator!
    
    var totalSeconds = 0
    var currentMood = Mood.normal
    var secondsRemaining = 0 {
        didSet {
            updateTimerLabel()
        }
    }
    var timer = Timer()
    var isTimerActive = false {
        didSet {
            updateTimerView()
        }
    }
    var isTimerRunning = false
    var buttonMode: ButtonMode = .start {
        didSet {
            updateStartPauseButton()
        }
    }
    var yConstraint: NSLayoutConstraint!
    var xConstraint: NSLayoutConstraint!
    var heightConstraint: NSLayoutConstraint!
    var widthConstraint: NSLayoutConstraint!

    
    var timerMode = TimerMode.solo {
        didSet {
            switch timerMode {
            case .moderator:
                timePicker.isHidden = isTimerActive
                timerLabel.isHidden = !isTimerActive
            case .presenter:
                timePicker.isHidden = true
                timerLabel.isHidden = false
                startPauseButton.isHidden = true
                cancelButton.isHidden = true
            case .solo:
                timePicker.isHidden = isTimerActive
                timerLabel.isHidden = !isTimerActive
                
            }
        }
    }

    // MARK: UI Elements

    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var startPauseButton: FABButton!
    @IBOutlet weak var cancelButton: FlatButton!
    @IBOutlet weak var timePicker: UIDatePicker!
    
    var delegate: TimerViewDelegate!
    
    var gradientView:  GradientView!
    var testView: UIView!

    // MARK: ViewController Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        prepareViews()
        prepareNotifications()

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        prepareGradientView()
    }

    override func removeFromSuperview() {
        removeNotifications()
    }

    // MARK: Prepare UI

    fileprivate func prepareViews() {
        prepareTimerLabel()
        prepareStartPauseButton()
        prepareCancelButton()
        prepareTimerPicker()
        updateTimerView()
    }
    
    
    fileprivate func prepareNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(cancelNotificationHandler(_:)), name: Notifications.cancelTimer.name, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startPauseNotificationHandler(_:)), name: Notifications.startPauseTimer.name, object: nil)
    }
    
    fileprivate func removeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    // Init Timer Label
    fileprivate func prepareTimerLabel() {
        timerLabel.textAlignment = .center
        updateTimerLabel()
        timerLabel.fontSize = 48
    }
    
    fileprivate func prepareGradientView() {
        
        gradientView = GradientView()
        gradientView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * gradientMultiplier)
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        if let delegate = delegate as? TimerViewController {
            delegate.view.addSubview(gradientView)
            delegate.view.sendSubviewToBack(gradientView)

            yConstraint = (NSLayoutConstraint(item: delegate.view, attribute: .top, relatedBy: .equal, toItem: gradientView, attribute: .top, multiplier: 1, constant: 0))
            xConstraint = (NSLayoutConstraint(item: delegate.view, attribute: .left, relatedBy: .equal, toItem: gradientView, attribute: .left, multiplier: 1, constant: 0))
            widthConstraint = (NSLayoutConstraint(item: delegate.view, attribute: .width, relatedBy: .equal, toItem: gradientView, attribute: .width, multiplier: 1, constant: 0))
            heightConstraint = NSLayoutConstraint(item: gradientView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: UIScreen.main.bounds.height * gradientMultiplier)

            delegate.view.addConstraints([yConstraint, xConstraint, widthConstraint,])
            gradientView.addConstraint(heightConstraint)
        }

    }

    // Init Start/Pause Button
    func prepareStartPauseButton() {
        startPauseButton.setTitle("Start", for: .normal)
        startPauseButton.fontSize = 36
        startPauseButton.titleColor = Colors.spaceGray
        startPauseButton.backgroundColor = .clear
        startPauseButton.addTarget(self, action: #selector(startPauseButtonHandler), for: .touchUpInside)
        startPauseButton.depthPreset = .depth2
        startPauseButton.borderColor = Colors.spaceGray
        startPauseButton.borderWidthPreset = .border3
        startPauseButton.pulseColor = .white

    }

    // Init Cancel Button
    func prepareCancelButton() {
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleColor = .white
        cancelButton.backgroundColor = Colors.spaceGray
        cancelButton.addTarget(self, action: #selector(cancelButtonHandler), for: .touchUpInside)
        cancelButton.depthPreset = .depth4
        cancelButton.cornerRadiusPreset = .cornerRadius4
    }

    func prepareTimerPicker() {
        timePicker.datePickerMode = .countDownTimer
        timePicker.addTarget(self, action: #selector(timePicked), for: .valueChanged)
    }


    // MARK: Functions
    
    @objc func startPauseNotificationHandler(_ notification: Notification) {
        if timerMode != .presenter { return }
        if let timer = notification.userInfo?["timer"] as? Int {
            timePicker.countDownDuration = Double(timer)
            startPauseButtonHandler()
        }
    }

    // Start timer if it is paused. Pause if it is running
    @objc func startPauseButtonHandler() {
        switch buttonMode {
        case .start:
            buttonMode = .pause
            runTimer()
            break
        case .pause:
            buttonMode = .start
            timer.invalidate()
            animator.pauseAnimation()
            break
        }
        if timerMode == .moderator {
            print(Int(timePicker.countDownDuration))
            SocketService.shared.socket.emit("startPauseButtonHandler", [SocketService.shared.room, Int(timePicker.countDownDuration)])
        }
    }
    
    @objc func cancelNotificationHandler(_ notification: Notification) {
        if timerMode != .presenter { return }
        cancelButtonHandler()
    }

    // Cancel timer and reset UI
    @objc func cancelButtonHandler() {
        
        resetTimer()
        
        if timerMode == .moderator {
            SocketService.shared.socket.emit("cancelButtonHandler", SocketService.shared.room)
        }
    }

    // Reset timer
    func resetTimer() {
        currentMood = .normal
        timer.invalidate()
        secondsRemaining = 0
        totalSeconds = 0
        buttonMode = .start
        isTimerActive = false
        resetAnimation()
        delegate.changeColor(mood: .normal)
    }
    
    func resetAnimation() {
        if animator != nil {
            animator.stopAnimation(true)
        }
        self.yConstraint.constant = 0
        self.gradientView.layoutIfNeeded()
        (self.delegate as! TimerViewController).view.layoutIfNeeded()
        animator = nil
    }

    // Start Timer
    func runTimer() {
        if !isTimerActive {
            totalSeconds = Int(timePicker.countDownDuration)
            secondsRemaining = totalSeconds
            isTimerActive = true
        }
        
        if animator == nil {

            animator = UIViewPropertyAnimator(duration: TimeInterval(secondsRemaining), curve: .linear){
                self.yConstraint.constant = UIScreen.main.bounds.height * (self.gradientMultiplier-1)
                self.gradientView.layoutIfNeeded()
                (self.delegate as! TimerViewController).view.layoutIfNeeded()
                self.animator.startAnimation()
            }
        }
        animator.startAnimation()
    
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
    }

    // Updite Timer
    @objc func updateTimer() {
        vibrateIfNeeded()
        changeColorIfNeeded()
        if secondsRemaining < 1 {
            resetTimer()
        } else {
            secondsRemaining -= 1
        }
    }

    // Switch Button mode between start/pause
    func updateStartPauseButton() {
        switch buttonMode {
        case .start:
            startPauseButton.setTitle("Start", for: .normal)
            layoutIfNeeded()
            break
        case .pause:
            startPauseButton.setTitle("Pause", for: .normal)
            layoutIfNeeded()
            break
        }
    }

    func updateTimerLabel() {
        timerLabel.text = timeString(time: TimeInterval(secondsRemaining))
    }

    @objc func timePicked(datePicker: UIDatePicker) {
        totalSeconds = Int(datePicker.countDownDuration)
        secondsRemaining = totalSeconds
    }

    func updateTimerView() {
        
        if timerMode == .presenter {
            return
        }
        timePicker.isHidden = isTimerActive
        timerLabel.isHidden = !isTimerActive
    }

    // MARK: Helper Methods

    // Format Time to String
    func timeString(time:TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
    
    func vibrateIfNeeded() {
        
        let minutesRemaining = (Double(secondsRemaining)/60)
        let vibrationMilestones:[Double] = [45, 30, 15, 10, 5, 4, 3, 2, 1]
        let vibrationMilestonesSeconds:[Double] = [45, 30, 15, 10, 5, 4, 3, 2, 1]


        if (minutesRemaining.truncatingRemainder(dividingBy: 60) == 0) ||
            (vibrationMilestones.contains(minutesRemaining)){
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        
        if (vibrationMilestonesSeconds.contains(Double(secondsRemaining))){
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
    
    func changeColorIfNeeded() {
        return
        if secondsRemaining == 0 {
            return
        }
        
        let remainingRatio = Double(secondsRemaining) / Double(totalSeconds)
        
        if remainingRatio > 0.66  && currentMood != .relaxed {
            currentMood = .relaxed
            delegate.changeColor(mood: .relaxed)
            
        } else if remainingRatio <= 0.66  && remainingRatio > 0.33 && currentMood != .stressed {
            currentMood = .stressed
            delegate.changeColor(mood: .stressed)
            
        } else if remainingRatio <= 0.33 && currentMood != .panicked {
            currentMood = .panicked
            delegate.changeColor(mood: .panicked)
        }
    }
}
