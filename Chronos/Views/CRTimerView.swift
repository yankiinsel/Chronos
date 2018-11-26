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
    }
    
    func viewDidLoad() {
        prepareViews()
        translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: Prepare UI

    func prepareViews() {
        prepareTimerLabel()
        prepareStartPauseButton()
        prepareCancelButton()
        prepareTimerPicker()
        updateTimerView()
    }

    // Init Timer Label
    func prepareTimerLabel() {
        timerLabel.textAlignment = .center
        updateTimerLabel()
        timerLabel.fontSize = 48
    }

    // Init Start/Pause Button
    func prepareStartPauseButton() {
        startPauseButton.setTitle("Start", for: .normal)
        startPauseButton.titleColor = .white
        startPauseButton.backgroundColor = Colors.spaceGray
        startPauseButton.addTarget(self, action: #selector(startPauseButtonTapped), for: .touchUpInside)
        startPauseButton.depthPreset = .depth4
        startPauseButton.cornerRadiusPreset = .cornerRadius4
    }

    // Init Cancel Button
    func prepareCancelButton() {
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleColor = .white
        cancelButton.backgroundColor = Colors.spaceGray
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.depthPreset = .depth4
        cancelButton.cornerRadiusPreset = .cornerRadius4
    }

    func prepareTimerPicker() {
        timePicker.datePickerMode = .countDownTimer
        timePicker.addTarget(self, action: #selector(timePicked), for: .valueChanged)
    }


    // MARK: Functions

    // Start timer if it is paused. Pause if it is running
    @objc func startPauseButtonTapped() {
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
    }

    // Cancel timer and reset UI
    @objc func cancelButtonTapped() {
        resetTimer()
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
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))

        }
    }
    
    func changeColorIfNeeded() {
        
        if secondsRemaining == 0 {
            return
        }
        
        let remainingRatio = Double(totalSeconds) / Double(secondsRemaining)
        
        if remainingRatio <= 1.0  && currentMood != .relaxed {
            currentMood = .relaxed
            delegate.changeColor(mood: .relaxed)
            
        } else if remainingRatio <= 1.5  && remainingRatio > 1.0 && currentMood != .stressed {
            currentMood = .stressed
            delegate.changeColor(mood: .stressed)
            
        } else if remainingRatio <= 3.0 && remainingRatio > 1.5 && currentMood != .panicked {
            currentMood = .panicked
            delegate.changeColor(mood: .panicked)
        }
    }
}
