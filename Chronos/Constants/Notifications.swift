//
//  Notifications.swift
//  Chronos
//
//  Created by Yanki Insel on 23.12.2018.
//  Copyright © 2018 Yanki Insel. All rights reserved.
//

import Foundation

struct Notifications {
    static let startPauseTimer = Notification(name: Notification.Name(rawValue: "startPauseTimer"))
    static let cancelTimer = Notification(name: Notification.Name(rawValue: "cancelTimer"))

}
