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
    @IBOutlet weak var startPauseButton: RaisedButton!
    @IBOutlet weak var cancelButton: RaisedButton!
    @IBOutlet weak var timePicker: UIDatePicker!
    
    var delegate: TimerViewDelegate!

    // MARK: ViewController Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        prepareViews()
        prepareNotifications()

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

    // Init Start/Pause Button
    func prepareStartPauseButton() {
        startPauseButton.setTitle("Start", for: .normal)
        startPauseButton.titleColor = .white
        startPauseButton.backgroundColor = Colors.spaceGray
        startPauseButton.addTarget(self, action: #selector(startPauseButtonHandler), for: .touchUpInside)
        startPauseButton.depthPreset = .depth4
        startPauseButton.cornerRadiusPreset = .cornerRadius4
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
        timer.invalidate()
        secondsRemaining = 0
        totalSeconds = 0
        buttonMode = .start
        isTimerActive = false
        delegate.changeColor(mood: .normal)
    }

    // Start Timer
    func runTimer() {
        if !isTimerActive {
            totalSeconds = Int(timePicker.countDownDuration)
            secondsRemaining = totalSeconds
            isTimerActive = true
        }
        
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
            break
        case .pause:
            startPauseButton.setTitle("Pause", for: .normal)
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

        if (minutesRemaining.truncatingRemainder(dividingBy: 60) == 0) ||
            (vibrationMilestones.contains(minutesRemaining)){
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
    
    func changeColorIfNeeded() {
        
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
