import Foundation
import AppKit
import Combine
import UserNotifications

struct GitHubRelease: Codable {
    let tagName: String
    let name: String
    let body: String?
    let assets: [GitHubAsset]
    let publishedAt: String
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case assets
        case publishedAt = "published_at"
    }
}

struct GitHubAsset: Codable {
    let name: String
    let browserDownloadUrl: String
    let size: Int
    
    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadUrl = "browser_download_url"
        case size
    }
}

class UpdateManager: NSObject, ObservableObject {
    static let shared = UpdateManager()
    
    @Published var updateAvailable = false
    @Published var latestVersion: String?
    @Published var releaseNotes: String?
    @Published var downloadProgress: Double = 0
    @Published var isDownloading = false
    @Published var isChecking = false
    
    private let githubRepo = "dmfenton/TouchGrass"
    private let currentVersion: String
    private var downloadTask: URLSessionDownloadTask?
    private var updateCheckTimer: Timer?
    
    // UserDefaults keys
    private let autoUpdateEnabledKey = "TouchGrass.autoUpdateEnabled"
    private let lastUpdateCheckKey = "TouchGrass.lastUpdateCheck"
    private let skipVersionKey = "TouchGrass.skipVersion"
    
    var autoUpdateEnabled: Bool {
        get { UserDefaults.standard.object(forKey: autoUpdateEnabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: autoUpdateEnabledKey) }
    }
    
    override init() {
        // Get current version from Info.plist
        self.currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        super.init()
        
        // Schedule automatic checks if enabled
        if autoUpdateEnabled {
            scheduleAutomaticChecks()
        }
    }
    
    // MARK: - Public Methods
    
    func checkForUpdates(silent: Bool = true) async {
        guard !isChecking else { return }
        
        await MainActor.run {
            isChecking = true
        }
        
        do {
            let url = URL(string: "https://api.github.com/repos/\(githubRepo)/releases/latest")!
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            
            // Extract version from tag (remove 'v' prefix if present)
            let latestVersionString = release.tagName.hasPrefix("v") 
                ? String(release.tagName.dropFirst()) 
                : release.tagName
            
            await MainActor.run {
                self.latestVersion = latestVersionString
                self.releaseNotes = release.body
                self.isChecking = false
                
                // Check if update is available
                if self.isNewerVersion(latestVersionString, than: self.currentVersion) {
                    // Check if user wants to skip this version
                    let skipVersion = UserDefaults.standard.string(forKey: self.skipVersionKey)
                    if skipVersion != latestVersionString {
                        self.updateAvailable = true
                        
                        if !silent {
                            self.showUpdateDialog()
                        } else {
                            self.showUpdateNotification()
                        }
                    }
                } else if !silent {
                    // Show "up to date" message for manual checks
                    self.showUpToDateDialog()
                }
                
                // Update last check time
                UserDefaults.standard.set(Date(), forKey: self.lastUpdateCheckKey)
            }
        } catch {
            print("Failed to check for updates: \(error)")
            await MainActor.run {
                self.isChecking = false
                if !silent {
                    self.showUpdateCheckError(error)
                }
            }
        }
    }
    
    func downloadAndInstallUpdate() async {
        guard latestVersion != nil else { return }
        
        await MainActor.run {
            isDownloading = true
            downloadProgress = 0
        }
        
        do {
            // Get the DMG URL from the latest release
            let url = URL(string: "https://api.github.com/repos/\(githubRepo)/releases/latest")!
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            
            // Find the DMG asset
            guard let dmgAsset = release.assets.first(where: { $0.name.hasSuffix(".dmg") }) else {
                throw UpdateError.noDMGFound
            }
            
            // Download the DMG
            let dmgURL = URL(string: dmgAsset.browserDownloadUrl)!
            let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(dmgAsset.name)
            
            // Use URLSession with progress tracking
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            downloadTask = session.downloadTask(with: dmgURL) { [weak self] tempURL, response, error in
                guard let self = self, let tempURL = tempURL else {
                    self?.handleDownloadError(error ?? UpdateError.downloadFailed)
                    return
                }
                
                do {
                    // Move downloaded file to destination
                    try? FileManager.default.removeItem(at: destinationURL)
                    try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                    
                    // Install the update
                    DispatchQueue.main.async {
                        self.installUpdate(from: destinationURL)
                    }
                } catch {
                    self.handleDownloadError(error)
                }
            }
            
            downloadTask?.resume()
            
        } catch {
            await MainActor.run {
                isDownloading = false
                showUpdateError(error)
            }
        }
    }
    
    func skipThisVersion() {
        guard let latestVersion = latestVersion else { return }
        UserDefaults.standard.set(latestVersion, forKey: skipVersionKey)
        updateAvailable = false
    }
    
    func cancelDownload() {
        downloadTask?.cancel()
        isDownloading = false
        downloadProgress = 0
    }
    
    // MARK: - Private Methods
    
    private func isNewerVersion(_ new: String, than current: String) -> Bool {
        let newComponents = new.split(separator: ".").compactMap { Int($0) }
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(newComponents.count, currentComponents.count) {
            let newValue = i < newComponents.count ? newComponents[i] : 0
            let currentValue = i < currentComponents.count ? currentComponents[i] : 0
            
            if newValue > currentValue {
                return true
            } else if newValue < currentValue {
                return false
            }
        }
        
        return false
    }
    
    private func scheduleAutomaticChecks() {
        // Check on launch
        Task {
            await checkForUpdates(silent: true)
        }
        
        // Check daily
        updateCheckTimer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
            Task {
                await self.checkForUpdates(silent: true)
            }
        }
    }
    
    private func installUpdate(from dmgPath: URL) {
        isDownloading = false
        
        // Show installation dialog
        let alert = NSAlert()
        alert.messageText = "Update Ready to Install"
        alert.informativeText = "Touch Grass will restart to complete the update."
        alert.addButton(withTitle: "Install & Restart")
        alert.addButton(withTitle: "Later")
        
        if alert.runModal() == .alertFirstButtonReturn {
            performInstallation(from: dmgPath)
        }
    }
    
    private func performInstallation(from dmgPath: URL) {
        // Create a shell script to replace the app
        let script = """
        #!/bin/bash
        # Wait for app to quit
        sleep 2
        
        # Mount the DMG
        MOUNT_POINT=$(hdiutil attach "\(dmgPath.path)" -nobrowse -noautoopen | grep Volumes | cut -f 3)
        
        # Copy the new app
        if [ -d "$MOUNT_POINT/Touch Grass.app" ]; then
            rm -rf "/Applications/Touch Grass.app"
            cp -R "$MOUNT_POINT/Touch Grass.app" "/Applications/"
            
            # Unmount the DMG
            hdiutil detach "$MOUNT_POINT"
            
            # Clean up
            rm "\(dmgPath.path)"
            
            # Relaunch the app
            open "/Applications/Touch Grass.app"
        fi
        """
        
        // Save script to temp file
        let scriptPath = FileManager.default.temporaryDirectory.appendingPathComponent("update.sh")
        try? script.write(to: scriptPath, atomically: true, encoding: .utf8)
        
        // Make script executable
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath.path)
        
        // Execute script in background and quit app
        Process.launchedProcess(launchPath: "/bin/bash", arguments: [scriptPath.path])
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - UI Methods
    
    private func showUpdateDialog() {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "Touch Grass \(latestVersion ?? "") is available. You have version \(currentVersion).\n\nWould you like to download it now?"
        
        if let notes = releaseNotes {
            let truncatedNotes = notes.prefix(500)
            alert.informativeText += "\n\nWhat's New:\n\(truncatedNotes)"
        }
        
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Skip This Version")
        alert.addButton(withTitle: "Remind Me Later")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            Task {
                await downloadAndInstallUpdate()
            }
        case .alertSecondButtonReturn:
            skipThisVersion()
        default:
            break
        }
    }
    
    private func showUpToDateDialog() {
        let alert = NSAlert()
        alert.messageText = "You're up to date!"
        alert.informativeText = "Touch Grass \(currentVersion) is the latest version."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showUpdateNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Update Available"
        content.body = "Touch Grass \(latestVersion ?? "") is ready to install"
        content.sound = nil // Silent notification
        
        let request = UNNotificationRequest(
            identifier: "update-available",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { _ in }
    }
    
    private func showUpdateCheckError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Update Check Failed"
        alert.informativeText = "Unable to check for updates. Please try again later."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showUpdateError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Update Failed"
        alert.informativeText = "Unable to download or install the update. Please try again later or download manually from GitHub."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func handleDownloadError(_ error: Error) {
        DispatchQueue.main.async {
            self.isDownloading = false
            self.showUpdateError(error)
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension UpdateManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            self.downloadProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Handled in completion handler
    }
}

// MARK: - Custom Errors

enum UpdateError: LocalizedError {
    case noDMGFound
    case downloadFailed
    case installationFailed
    
    var errorDescription: String? {
        switch self {
        case .noDMGFound:
            return "No DMG file found in the release"
        case .downloadFailed:
            return "Failed to download the update"
        case .installationFailed:
            return "Failed to install the update"
        }
    }
}