//
//  NotificationManager.swift
//  Focus Totem
//
//  Created by Daniele Spaccapeli on 24/12/25.
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
            if notificationsEnabled {
                scheduleNotifications()
            } else {
                cancelAllNotifications()
            }
        }
    }

    private let notificationFrequencyKey = "notificationFrequency"

    enum NotificationFrequency: String, CaseIterable {
        case daily = "Daily"
        case twiceDaily = "Twice Daily"
        case threeTimesDaily = "3 Times Daily"

        var timeRanges: [(startHour: Int, endHour: Int)] {
            switch self {
            case .daily:
                return [(9, 11)] // Between 9-11 AM
            case .twiceDaily:
                return [
                    (9, 11),   // Between 9-11 AM
                    (17, 19)   // Between 5-7 PM
                ]
            case .threeTimesDaily:
                return [
                    (8, 10),   // Between 8-10 AM
                    (13, 15),  // Between 1-3 PM
                    (18, 20)   // Between 6-8 PM
                ]
            }
        }
    }

    private let motivationalMessages = [
        "Ready to focus? Your totem is waiting 🎯",
        "You've got this! Time to enter flow state ✨",
        "Building better habits, one session at a time 🌱",
        "Your future self will thank you for focusing now 💪",
        "Break the scroll cycle — scan your totem 📱",
        "Focus time! Your goals are calling 🚀",
        "Transform distraction into dedication 🔥",
        "Small focused sessions = Big results 📈",
        "Your totem is ready when you are 🎯",
        "Make this moment count — start a focus session 💎",
        "Practice makes permanent. Time to focus! 🧠",
        "Turn intention into action. Scan your totem! ⚡️"
    ]

    private init() {
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        checkNotificationPermission()
    }

    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }

    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            await MainActor.run {
                self.notificationPermissionStatus = granted ? .authorized : .denied
                if granted {
                    self.notificationsEnabled = true
                }
            }

            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }

    func getNotificationFrequency() -> NotificationFrequency {
        if let rawValue = UserDefaults.standard.string(forKey: notificationFrequencyKey),
           let frequency = NotificationFrequency(rawValue: rawValue) {
            return frequency
        }
        return .daily // Default
    }

    func setNotificationFrequency(_ frequency: NotificationFrequency) {
        UserDefaults.standard.set(frequency.rawValue, forKey: notificationFrequencyKey)
        if notificationsEnabled {
            scheduleNotifications()
        }
    }

    func scheduleNotifications() {
        // Cancel existing notifications first
        cancelAllNotifications()

        guard notificationsEnabled else { return }

        let frequency = getNotificationFrequency()
        let timeRanges = frequency.timeRanges

        for (index, range) in timeRanges.enumerated() {
            // Generate random hour and minute within the range
            let randomHour = Int.random(in: range.startHour..<range.endHour)
            let randomMinute = Int.random(in: 0..<60)

            var dateComponent = DateComponents()
            dateComponent.hour = randomHour
            dateComponent.minute = randomMinute

            let content = UNMutableNotificationContent()
            content.title = "Time to Focus"
            content.body = motivationalMessages.randomElement() ?? "Ready to focus with your totem?"
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponent, repeats: true)
            let request = UNNotificationRequest(
                identifier: "focus-reminder-\(index)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                } else {
                    print("Scheduled notification for \(randomHour):\(String(format: "%02d", randomMinute))")
                }
            }
        }
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("Cancelled all notifications")
    }

    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
}
