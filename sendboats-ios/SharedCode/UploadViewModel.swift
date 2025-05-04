//
//  UploadViewModel.swift
//  sendboats
//
//  Created on 3/23/25.
//

import Foundation
import SwiftUI

public enum UIFlowState {
    case fileSelection
    case previewAndUpload
    case uploading
    case success
}

public enum UploadState: Equatable {
    case idle
    case generatingPreview
    case uploading
    case success(UploadResult)
    case error(String)

    public static func == (lhs: UploadState, rhs: UploadState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.generatingPreview, .generatingPreview):
            return true
        case (.uploading, .uploading):
            return true
        case (.success(let lhsResult), .success(let rhsResult)):
            return lhsResult.key == rhsResult.key
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

public class UploadViewModel: ObservableObject {
    private let uploadService: UploadService

    public init() {
        uploadService = UploadService()

        let configuration = ConfigurationManager.shared.loadConfiguration()
        self.serverURL = configuration.serverURL
        self.username = configuration.username
        self.password = configuration.password

        checkForSharedFiles()
    }

    var uiFlowState: UIFlowState {
        if selectedFileURL == nil || selectedFileName.isEmpty {
            return .fileSelection
        }

        switch uploadState {
        case .uploading:
            return .uploading
        case .success:
            return .success
        case .error, .generatingPreview, .idle:
            return .previewAndUpload
        }
    }

    @Published public var isVideoFile: Bool = false

    @Published public var serverURL: String
    @Published public var username: String
    @Published public var password: String
    @Published public var selectedFileURL: URL?
    @Published public var selectedFileName: String = ""
    @Published public var uploadState: UploadState = .idle
    @Published public var uploadProgress: Double = 0.0
    @Published public var uploadResult: UploadResult?

    func checkForSharedFiles() {
        let sharedDefaults = UserDefaults(suiteName: "group.jsdf.sendboats")

        if let hasSharedFile = sharedDefaults?.bool(forKey: "HasSharedFile"), hasSharedFile,
           let sharedFilePath = sharedDefaults?.string(forKey: "SharedFilePath"),
           let sharedFileName = sharedDefaults?.string(forKey: "SharedFileName") {

            let sharedFileURL = URL(fileURLWithPath: sharedFilePath)

            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: sharedFilePath) {
                handleFileSelection(fileURL: sharedFileURL, fileName: sharedFileName)

                sharedDefaults?.set(false, forKey: "HasSharedFile")
                sharedDefaults?.removeObject(forKey: "SharedFilePath")
                sharedDefaults?.removeObject(forKey: "SharedFileName")
                sharedDefaults?.synchronize()

                Task {
                    await startUpload()
                }
            }
        }
    }

    public func saveConfiguration() {
        let configuration = APIConfiguration(
            serverURL: serverURL,
            username: username,
            password: password
        )
        ConfigurationManager.shared.saveConfiguration(configuration)
        uploadService.setupAPIClient()
    }

    public func startUpload() async {
        guard let fileURL = selectedFileURL else {
            await MainActor.run {
                uploadState = .error("No file selected")
            }
            return
        }

        await MainActor.run {
            uploadProgress = 0.0
            uploadState = .idle
        }

        let result = await uploadService.uploadFile(fileURL: fileURL) { [weak self] phase in
            Task { @MainActor in
                guard let self = self else { return }
                switch phase {
                case .generatingPreview:
                    self.uploadState = .generatingPreview
                    self.uploadProgress = 0
                case .uploading(let progress):
                    if self.uploadState != .uploading {
                         self.uploadState = .uploading
                    }
                    self.uploadProgress = progress
                }
            }
        }

        await MainActor.run {
            switch result {
            case .success(let uploadResultData):
                self.uploadResult = uploadResultData
                self.uploadState = .success(uploadResultData)
            case .failure(let error):
                self.uploadState = .error(error.localizedDescription)
            }
        }
    }

    public func handleFileSelection(fileURL: URL, fileName: String) {
        reset()

        selectedFileURL = fileURL
        selectedFileName = fileName

        checkFileType()
    }

    public func reset() {
        selectedFileURL = nil
        selectedFileName = ""

        uploadState = .idle
        uploadProgress = 0.0
        uploadResult = nil

        isVideoFile = false
    }

    func checkFileType() {
        guard let fileURL = selectedFileURL else {
            isVideoFile = false
            return
        }

        let fileExtension = fileURL.pathExtension.lowercased()
        let videoExtensions = ["mp4", "mov", "m4v", "avi", "mkv"]
        isVideoFile = videoExtensions.contains(fileExtension)
    }

    func copyURLToClipboard(_ url: URL?) {
        UploadService.copyURLToClipboard(url)
    }
}
