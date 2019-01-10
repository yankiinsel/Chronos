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
    @IBOutlet weak var connectionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createSocket()
        prepareButtons()
        prepareTextField()
        prepareView()
    }
    
    private func prepareView() {
        title = "Session"
        let gradientView = GradientView()
        gradientView.startColor = Colors.primary
        gradientView.endColor = Colors.secondary
        gradientView.diagonalMode = true
        gradientView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        view.addSubview(gradientView)
        view.sendSubviewToBack(gradientView)
        updateConnection()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareNotifications()
        socket.emit("leaveRoom")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeNotifications()
    }
    
    fileprivate func prepareNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateConnection), name: Notifications.connected.name, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(joinedRoomMod(_:)), name: Notifications.joinedRoomMod.name, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(joinedRoomPrsntr(_:)), name: Notifications.joinedRoomPrsntr.name, object: nil)
    }
    
    @objc fileprivate func updateConnection() {
        if SocketService.shared.isConnected {
            connectionLabel.text = "Connected"
            connectionLabel.textColor = Colors.relaxed
        } else {
            connectionLabel.text = "Not Connected"
            connectionLabel.textColor = Colors.panicked
        }
    }
    
    fileprivate func removeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    private func createSocket() {
        socket = SocketService.shared.socket
    }
    
    private func prepareButtons() {
        createButton.setTitle("Moderator", for: .normal)
        joinButton.setTitle("Presenter", for: .normal)
        
        createButton.addTarget(self, action: #selector(createButtonHandler), for: .touchUpInside)
        joinButton.addTarget(self, action: #selector(joinButtonHandler), for: .touchUpInside)
        
        createButton.tintColor = Colors.secondary
        createButton.titleColor = .white
        createButton.pulseColor = .white
        createButton.backgroundColor = Colors.secondary
        createButton.heightPreset = .medium
        createButton.cornerRadiusPreset = .cornerRadius4
        createButton.depthPreset = .depth3
        createButton.fontSize = 18
        
        joinButton.tintColor = Colors.secondary
        joinButton.titleColor = .white
        joinButton.pulseColor = .white
        joinButton.backgroundColor = Colors.secondary
        joinButton.heightPreset = .medium
        joinButton.cornerRadiusPreset = .cornerRadius4
        joinButton.depthPreset = .depth3
        joinButton.fontSize = 18
    }
    
    private func prepareTextField() {
        sessionCodeLabel.placeholder = "Enter session name"
        sessionCodeLabel.tintColor = .white
        sessionCodeLabel.detailColor = .white
        sessionCodeLabel.textColor = .white
        sessionCodeLabel.dividerNormalColor = .white
        sessionCodeLabel.dividerActiveColor = .white
        sessionCodeLabel.placeholderActiveColor = .white
        sessionCodeLabel.placeholderNormalColor = .white

    }
    
    private func joinRoomMod() {
        if let room = sessionCodeLabel.text {
            print("trying to join \(room)")
                socket.emit("roomMod", room);
                SocketService.shared.room = room
        }
    }
    
    private func joinRoomPrsntr() {
        if let room = sessionCodeLabel.text {
            print("trying to join \(room)")
            socket.emit("roomPrsntr", room);
            SocketService.shared.room = room
        }
    }
    
    @objc func joinButtonHandler() {

        guard let session = sessionCodeLabel.text, !session.isEmpty else {
            return
        }
        
        joinRoomPrsntr()

    }
    
    @objc func createButtonHandler() {
        guard let session = sessionCodeLabel.text, !session.isEmpty else {
            return
        }
        joinRoomMod()
    }
    
    @objc func joinedRoomMod(_ notification: Notification) {
        guard let session = sessionCodeLabel.text, !session.isEmpty else {
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let timerVC = storyboard.instantiateViewController(withIdentifier: "TimerVC") as! TimerViewController
        timerVC.timerMode = .moderator
        timerVC.session = session
        navigationController?.pushViewController(timerVC, animated: true)
    }
    
    @objc func joinedRoomPrsntr(_ notification: Notification) {
        guard let session = sessionCodeLabel.text, !session.isEmpty else {
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let timerVC = storyboard.instantiateViewController(withIdentifier: "TimerVC") as! TimerViewController
        timerVC.timerMode = .presenter
        timerVC.session = session
        navigationController?.pushViewController(timerVC, animated: true)
    }
}
