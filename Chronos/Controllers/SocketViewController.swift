//
//  SocketViewController.swift
//  Chronos
//
//  Created by Yanki Insel on 22.12.2018.
//  Copyright © 2018 Yanki Insel. All rights reserved.
//

import UIKit
import SocketIO
import Material

class SocketViewController: UIViewController {
    

    var socket : SocketIOClient!

    @IBOutlet weak var sessionCodeLabel: TextField!
    @IBOutlet weak var createButton: RaisedButton!
    @IBOutlet weak var joinButton: RaisedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createSocket()
        prepareButtons()
        prepareTextField()
        //prepareNotifications()
    }

    
    private func createSocket() {
        socket = SocketService.shared.socket
    }
    
    private func prepareButtons() {
        createButton.setTitle("Create", for: .normal)
        joinButton.setTitle("Join", for: .normal)
        
        createButton.addTarget(self, action: #selector(createButtonHandler), for: .touchUpInside)
        joinButton.addTarget(self, action: #selector(joinButtonHandler), for: .touchUpInside)
    }
    
    private func prepareTextField() {
        sessionCodeLabel.placeholder = "Room no."
    }
    
    private func joinRoom() {
        let room = sessionCodeLabel.text
        if let room = room {
            socket.emit("room", room);
            SocketService.shared.room = room
        }
    }
    
    @objc func joinButtonHandler() {
        joinRoom()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let timerVC = storyboard.instantiateViewController(withIdentifier: "TimerVC") as! TimerViewController
        timerVC.timerMode = .presenter
        navigationController?.pushViewController(timerVC, animated: true)
    }
    
    @objc func createButtonHandler() {
        joinRoom()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let timerVC = storyboard.instantiateViewController(withIdentifier: "TimerVC") as! TimerViewController
        timerVC.timerMode = .moderator
        navigationController?.pushViewController(timerVC, animated: true)
    }
}
