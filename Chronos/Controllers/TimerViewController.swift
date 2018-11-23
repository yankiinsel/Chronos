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
    
    var timerView: CRTimerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareViews()
    }
    
    func prepareViews() {
     view.backgroundColor = Colors.relaxed
    }

}

