import SwiftUI
import UserNotifications
import AVFoundation
import CoreLocation
import Photos
#if canImport(HealthKit)
import HealthKit
#endif
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

struct PermissionBlockRenderer: BlockRenderer {
    func render(
        block: Block,
        theme: Theme,
        state: FlowState,
        onAnswer: @escaping (String, Any) -> Void,
        onAction: @escaping (String, String?) -> Void
    ) -> AnyView {
        AnyView(PermissionBlockView(block: block, theme: theme, onAction: onAction))
    }
}

private struct PermissionBlockView: View {
    let block: Block
    let theme: Theme
    let onAction: (String, String?) -> Void

    @StateObject private var locationRequester = LocationPermissionRequester()
    @State private var isRequesting = false

    var body: some View {
        let tokens = theme.tokens
        VStack(spacing: 16) {
            IconView(iconName: permissionIconName(), color: tokens.primaryColor, size: 28)
                .frame(width: 56, height: 56)
                .background(tokens.primaryColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            Text(block.headline ?? "Allow permission")
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(tokens.textPrimaryColor)

            Text(block.permissionDescription ?? "This helps personalize your experience.")
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(tokens.textSecondaryColor)

            VStack(spacing: 10) {
                Button(action: {
                    requestPermissionThenAdvance()
                }) {
                    Text(block.ctaLabel ?? "Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(tokens.primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(tokens.cornerRadius)
                }
                .disabled(isRequesting)

                Button(action: {
                    advance(with: block.onDenied)
                }) {
                    Text(block.skipLabel ?? "Not now")
                        .font(.system(size: 15))
                        .foregroundColor(tokens.textSecondaryColor)
                }
                .disabled(isRequesting)
            }
        }
        .padding(.horizontal, Spacing.md.value)
        .padding(.vertical, 8)
    }

    private func permissionIconName() -> String {
        if let icon = block.icon, !icon.isEmpty {
            return icon
        }
        switch block.type {
        case "notification_permission":
            return "Bell"
        case "health_permission":
            return "Heart"
        case "tracking_permission":
            return "TrendingUp"
        case "camera_permission":
            return "Camera"
        case "location_permission":
            return "Map"
        case "microphone_permission":
            return "Mic"
        case "photo_library_permission":
            return "Photo"
        default:
            return "Shield"
        }
    }

    private func requestPermissionThenAdvance() {
        isRequesting = true
        Task {
            let granted = await requestPermission()
            DispatchQueue.main.async {
                isRequesting = false
                advance(with: granted ? block.onGranted : block.onDenied)
            }
        }
    }

    private func requestPermission() async -> Bool {
        switch block.type {
        case "notification_permission":
            return await requestNotificationPermission()
        case "health_permission":
            return await requestHealthPermission()
        case "tracking_permission":
            return await requestTrackingPermission()
        case "camera_permission":
            return await requestCameraPermission()
        case "location_permission":
            return await requestLocationPermission()
        case "microphone_permission":
            return await requestMicrophonePermission()
        case "photo_library_permission":
            return await requestPhotoLibraryPermission()
        default:
            return false
        }
    }

    private func advance(with action: String?) {
        let normalized = action?.lowercased() ?? "next_screen"
        if normalized == "complete_flow" {
            onAction("complete", nil)
        } else {
            onAction("next", nil)
        }
    }

    private func hasPlistUsageDescription(_ key: String) -> Bool {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return false
        }
        return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func requestNotificationPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestHealthPermission() async -> Bool {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        guard hasPlistUsageDescription("NSHealthShareUsageDescription") else { return false }
        guard let steps = HKObjectType.quantityType(forIdentifier: .stepCount),
              let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return false
        }
        let readTypes: Set<HKObjectType> = [steps, energy]
        let store = HKHealthStore()
        return await withCheckedContinuation { continuation in
            store.requestAuthorization(toShare: [], read: readTypes) { success, _ in
                continuation.resume(returning: success)
            }
        }
        #else
        return false
        #endif
    }

    private func requestTrackingPermission() async -> Bool {
        #if canImport(AppTrackingTransparency)
        guard hasPlistUsageDescription("NSUserTrackingUsageDescription") else { return false }
        if #available(iOS 14.5, *) {
            return await withCheckedContinuation { continuation in
                ATTrackingManager.requestTrackingAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
        return false
        #else
        return false
        #endif
    }

    private func requestCameraPermission() async -> Bool {
        guard hasPlistUsageDescription("NSCameraUsageDescription") else { return false }
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestLocationPermission() async -> Bool {
        guard hasPlistUsageDescription("NSLocationWhenInUseUsageDescription") else { return false }
        return await locationRequester.requestWhenInUse()
    }

    private func requestMicrophonePermission() async -> Bool {
        guard hasPlistUsageDescription("NSMicrophoneUsageDescription") else { return false }
        return await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func requestPhotoLibraryPermission() async -> Bool {
        guard hasPlistUsageDescription("NSPhotoLibraryUsageDescription") else { return false }
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status == .authorized || status == .limited)
            }
        }
    }
}

private final class LocationPermissionRequester: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<Bool, Never>?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestWhenInUse() async -> Bool {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            return true
        }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let continuation else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            self.continuation = nil
            continuation.resume(returning: true)
        case .denied, .restricted:
            self.continuation = nil
            continuation.resume(returning: false)
        default:
            break
        }
    }
}
