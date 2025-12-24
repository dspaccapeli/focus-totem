//
//  NotificationPermissionPageView.swift
//  Focus Totem
//
//  Created by Daniele Spaccapeli on 24/12/25.
//

import SwiftUI

struct NotificationPermissionPageView: View {
    @Binding var notificationPermissionGranted: Bool
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var isRequesting = false
    var onSkip: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
            }

            // Title
            Text("Stay on Track")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)

            // Description
            VStack(spacing: 16) {
                Text("Gentle reminders help you remember to use your totem and build lasting focus habits.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)

                // Educational section
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(
                        icon: "brain.head.profile",
                        text: "Breaks automatic phone habits"
                    )

                    InfoRow(
                        icon: "chart.line.uptrend.xyaxis",
                        text: "Builds consistency through repetition"
                    )

                    InfoRow(
                        icon: "clock.badge.checkmark",
                        text: "Creates external cues for focus time"
                    )
                }
                .padding(.horizontal, 30)
                .padding(.top, 10)
            }

            // Permission status or request button
            if notificationManager.notificationPermissionStatus == .authorized {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Notifications Enabled")
                        .font(.body)
                        .foregroundColor(.green)
                }
                .padding()
            } else if notificationManager.notificationPermissionStatus == .denied {
                VStack(spacing: 12) {
                    Text("Notifications are disabled")
                        .font(.body)
                        .foregroundColor(.orange)

                    Button(action: {
                        notificationManager.openSettings()
                    }) {
                        Text("Open Settings")
                            .font(.body)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            } else {
                Button(action: {
                    requestPermission()
                }) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "bell.fill")
                            Text("Enable Reminders")
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isRequesting)

                Button(action: {
                    // Skip this step - complete onboarding
                    onSkip?()
                }) {
                    Text("Skip for Now")
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                }
            }

            Spacer()

            // Bottom explanatory text
            Text("You can change this anytime in Settings")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 20)
        }
        .padding()
        .onChange(of: notificationManager.notificationPermissionStatus) { _, newStatus in
            if newStatus == .authorized {
                notificationPermissionGranted = true
            }
        }
    }

    private func requestPermission() {
        isRequesting = true

        Task {
            let granted = await notificationManager.requestNotificationPermission()

            await MainActor.run {
                isRequesting = false
                if granted {
                    notificationPermissionGranted = true
                }
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(text)
                .font(.body)
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

#Preview {
    NotificationPermissionPageView(notificationPermissionGranted: .constant(false))
}
