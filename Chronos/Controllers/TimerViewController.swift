//
//  TimerViewController.swift
//  Chronos
//
//  Created by Yanki Insel on 28.10.2018.
//  Copyright © 2018 Yanki Insel. All rights reserved.
//

import UIKit
import Material

class TimerViewController: UIViewController {
    
    @IBOutlet var timerView: CRTimerView!
    
    var timerMode = TimerMode.solo
    var session: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        timerView.timerMode = timerMode
    }
    
    fileprivate func prepareViews() {
        view.backgroundColor = .white
        if timerMode == .solo {
            title = "Timer"
        } else {
            if let session = session {
                title = session
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        timerView.delegate = self
    }
}

extension TimerViewController: TimerViewDelegate {
    
    
    func changeColor(mood: Mood) {
        switch mood {
        case .panicked:
            view.backgroundColor = Colors.panicked
            break
        case .relaxed:
            view.backgroundColor = Colors.relaxed
            break
        case .stressed:
            view.backgroundColor = Colors.stressed
            break
        case .normal:
            view.backgroundColor = .white
        }
    }

}

