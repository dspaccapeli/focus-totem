//
//  Session.swift
//  Deliberate
//
//  Created by Daniele Spaccapeli on 15/03/25.
//

import SwiftData
import Foundation

@Model
class SessionModel {
    var startTime: Date
    var endTime: Date?
    
    init(startTime: Date = Date(), endTime: Date? = nil) {
        self.startTime = startTime
        self.endTime = endTime
    }
    
    var duration: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        } else {
            return Date().timeIntervalSince(startTime)
        }
    }
    
    var isActive: Bool {
        return endTime == nil
    }
}
