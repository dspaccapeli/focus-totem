//
//  SessionsStats.swift
//  Deliberate
//
//  Created by Daniele Spaccapeli on 14/03/25.
//

import SwiftData
import Foundation

@Model
class SessionsStatsModel {
    var totalBlockedTime: TimeInterval
    @Relationship(deleteRule: .cascade) var sessions: [SessionModel] = []
    
    init(totalBlockedTime: TimeInterval = 0) {
        self.totalBlockedTime = totalBlockedTime
    }
    
    var isEmpty: Bool {
        return sessions.isEmpty
    }
    
    var currentSession: SessionModel? {
        return sessions.first(where: { $0.isActive })
    }
    
    var hasActiveSession: Bool {
        return currentSession != nil
    }
    
    func startNewSession() -> SessionModel {
        let newSession = SessionModel(startTime: Date())
        sessions.append(newSession)
        return newSession
    }
    
    func endCurrentSession() {
        if let activeSession = currentSession {
            activeSession.endTime = Date()
            totalBlockedTime += activeSession.duration
        }
    }
    
    func calculateTotalTime() -> TimeInterval {
        let completedSessionsTime = sessions
            .filter { $0.endTime != nil }
            .reduce(0) { $0 + $1.duration }
        
        let activeSessionTime = currentSession?.duration ?? 0
        
        return completedSessionsTime + activeSessionTime
    }
    
    /// Calculates the total time spent in sessions during the current week
    /// - Returns: Time interval representing total time this week
    func calculateTimeThisWeek() -> TimeInterval {
        let calendar = Calendar.current
        
        // Get the start of the current week (Sunday or Monday depending on locale)
        let today = Date()
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return 0
        }
        
        // Filter sessions that occurred this week
        let thisWeekSessions = sessions.filter { session in
            // For active sessions, check if they started this week
            if session.isActive {
                return session.startTime >= startOfWeek
            }
            
            // For completed sessions, check if they have any overlap with this week
            guard let endTime = session.endTime else { return false }
            
            // Session started before this week but ended during this week
            if session.startTime < startOfWeek && endTime >= startOfWeek {
                return true
            }
            
            // Session started and ended within this week
            if session.startTime >= startOfWeek {
                return true
            }
            
            return false
        }
        
        // Calculate time for sessions that started before this week but ended during it
        let adjustedTime = thisWeekSessions.reduce(0) { totalTime, session in
            if session.startTime < startOfWeek, let endTime = session.endTime, endTime >= startOfWeek {
                // Only count the portion of time that falls within this week
                return totalTime + endTime.timeIntervalSince(startOfWeek)
            } else {
                return totalTime + session.duration
            }
        }
        
        return adjustedTime
    }
}
