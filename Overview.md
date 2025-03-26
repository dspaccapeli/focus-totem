# Focus Totem App Overview

## Application Purpose

Focus Totem is a productivity app that helps users maintain focus by blocking distracting applications using the Screen Time API. The app's unique approach is that it uses a physical object (a "totem") to control the blocking functionality, creating a tangible connection between the physical world and digital focus.

## Key Features

- **Totem Recognition**: Uses the Vision API to recognize a specific object chosen by the user during onboarding
- **Application Blocking**: Leverages the Screen Time API to block access to user-selected distracting applications
- **Profile Management**: Allows users to create and customize blocking profiles that define which applications to block
- **Focus Statistics**: Tracks and displays the total time spent in focused mode with application blocking enabled

## Components

1. **ImageSimilarityScanner**: A SwiftUI component that uses the Vision API to compute image similarity between a captured reference image and real-time camera input.

2. **TotemScanningPageView**: Part of the onboarding process, this component allows users to capture an image of their chosen totem object, generate its feature print, and verify the object can be recognized.

3. **CaptureImageView**: A UIViewControllerRepresentable component that handles camera access and photo capture.

4. **ProfileSelectionView**: Allows users to select and customize application blocking profiles.

5. **PermissionsManager**: Handles requesting and checking app permissions (Camera, Screen Time).

6. **ScreenTimeManager**: Interfaces with the Screen Time API to enable/disable application blocking.

## Recent Changes (2025-03-18)

### Added ImageSimilarityScanner Component
- Created a new component similar to QRScanner that computes the similarity between images using Vision API's feature print functionality
- Includes thresholding logic to determine when images are similar enough to trigger actions

### Implemented Totem Capture in Onboarding
- Modified the onboarding flow to capture a reference image of the user's chosen totem object
- Added functionality to generate and store a feature print of the totem for later comparison
- Implemented a verification step to ensure the totem can be reliably recognized

### Enhanced User Experience
- Added two-step process in totem setup: capturing and then verifying
- Included visual feedback during the capture and verification process
- Implemented proper state management between capture modes

## Usage Flow

1. **Onboarding**:
   - User is introduced to the app's concept
   - Camera permissions are requested
   - User captures an image of their chosen totem object
   - The app verifies it can recognize the totem
   
2. **Main Screen**:
   - A camera view continuously analyzes objects in view
   - When the totem is recognized with sufficient similarity, blocking can be toggled
   - User can access profile settings to customize which apps to block
   - A counter displays total focus time
   
3. **Settings**:
   - User can access app settings from the top-right corner
   - Customize app behavior and preferences

## Data Storage

- The app uses SwiftData for persistent storage
- The totem's feature print is securely stored in UserDefaults
- Session data and profiles are stored in the app's database