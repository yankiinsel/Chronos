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

// MARK: Variables

class CRTimerView: NibView {

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

    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var startPauseButton: RaisedButton!
    @IBOutlet weak var cancelButton: RaisedButton!
    @IBOutlet weak var timePicker: UIDatePicker!

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
        seconds = 0
        buttonMode = .start
        isTimerActive = false
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
            resetTimer()
            //Send alert to indicate "time's up!"
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
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
