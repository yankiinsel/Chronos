//
//  SocketService
//  Chronos
//
//  Created by Yanki Insel on 22.12.2018.
//  Copyright © 2018 Yanki Insel. All rights reserved.
//

import Foundation
import SocketIO

class SocketService {
    
    static let shared = SocketService()
     let manager = SocketManager(socketURL: URL(string: "https://server-chronos.now.sh/")!, config: [.log(false)])
    
    var socket: SocketIOClient!
    var room: String!
    var isConnected = false
    
    init() {
        
        socket = manager.defaultSocket
        
        socket.on(clientEvent: .connect) { data, ack in
            print("socket connected")
            self.isConnected = true
            NotificationCenter.default.post(name: Notifications.connected.name, object: nil)
        }
        
        socket.on("startPauseButtonHandler") { data, ack in
            print("startPauseButtonHandler")
            let timer = data[0] as! Int
            let timerDataDict:[String: Int] = ["timer": timer]
            NotificationCenter.default.post(name: Notifications.startPauseTimer.name, object: nil, userInfo: timerDataDict)
        }
        
        socket.on("roomJoinedMod") { data, ack in
            print("roomJoined")
            NotificationCenter.default.post(name: Notifications.joinedRoomMod.name, object: nil)
        }
        
        socket.on("roomJoinedPrsntr") { data, ack in
            print("roomJoined")
            NotificationCenter.default.post(name: Notifications.joinedRoomPrsntr.name, object: nil)
        }
        
        socket.on("cancelButtonHandler") { data, ack in
            print("cancelButtonHandler")
            NotificationCenter.default.post(Notifications.cancelTimer)
        }
        
        socket.connect()
    }
}
