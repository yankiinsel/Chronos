//
//  TimerViewController.swift
//  Chronos
//
//  Created by Yanki Insel on 28.10.2018.
//  Copyright © 2018 Yanki Insel. All rights reserved.
//

import UIKit
import Material

// Button Modes: Start, Pause
enum ButtonMode {
    case start
    case pause
}

class TimerViewController: UIViewController {
    
    // MARK: Variables
    
    var seconds = 0 {
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
    
    var timerLabel: UILabel!
    var startPauseButton: RaisedButton!
    var cancelButton: RaisedButton!
    var timePicker: UIDatePicker!
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareViews()
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
        timerLabel = UILabel(frame: CGRect(x: 0, y: 32, width: view.frame.width, height: 256))
        timerLabel.textAlignment = .center
        view.addSubview(timerLabel)
        updateTimerLabel()
        timerLabel.fontSize = 48
    }
    
    // Init Start/Pause Button
    func prepareStartPauseButton() {
        startPauseButton = RaisedButton(frame: CGRect(x: (view.frame.width/2) + ((view.frame.width/2)-128)/2, y: timerLabel.frame.height + timerLabel.frame.origin.y + 32, width: 128, height: 64))
        view.addSubview(startPauseButton)
        startPauseButton.setTitle("Start", for: .normal)
        startPauseButton.titleColor = Color.blue.base
        startPauseButton.backgroundColor = Color.grey.lighten4
        startPauseButton.addTarget(self, action: #selector(startPauseButtonTapped), for: .touchUpInside)
        startPauseButton.depthPreset = .depth2
        startPauseButton.cornerRadiusPreset = .cornerRadius2
    }
    
    // Init Cancel Button
    func prepareCancelButton() {
        cancelButton = RaisedButton(frame: CGRect(x: ((view.frame.width/2)-128)/2, y: timerLabel.frame.height + timerLabel.frame.origin.y + 32, width: 128, height: 64))
        view.addSubview(cancelButton)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleColor = Color.red.base
        cancelButton.backgroundColor = Color.grey.lighten4
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.depthPreset = .depth2
        cancelButton.cornerRadiusPreset = .cornerRadius2
    }
    
    func prepareTimerPicker() {
        timePicker = UIDatePicker(frame: CGRect(x: 0, y: 32, width: view.frame.width, height: 256))
        view.addSubview(timePicker)
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
        isTimerActive = false
    }
    
    // Reset timer
    func resetTimer() {
        timer.invalidate()
        seconds = 0
        buttonMode = .start
    }
    
    // Start Timer
    func runTimer() {
        if !isTimerActive {
            seconds = Int(timePicker.countDownDuration)
            isTimerActive = true
        }
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self,   selector: (#selector(updateTimer)), userInfo: nil, repeats: true)
    }
    
    // Updite Timer
    @objc func updateTimer() {
        if seconds < 1 {
            timer.invalidate()
            //Send alert to indicate "time's up!"
        } else {
            seconds -= 1
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
        timerLabel.text = timeString(time: TimeInterval(seconds))
    }
    
    @objc func timePicked(datePicker: UIDatePicker) {
        seconds = Int(datePicker.countDownDuration)
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


}

