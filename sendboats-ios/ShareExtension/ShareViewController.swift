//
//  ShareViewController.swift
//  ShareExtension
//
//  Created on 4/28/25.
//

import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers
import SwiftUI

class ShareViewController: UIViewController {

    private let uploadService = UploadService()

    private var statusLabel: UILabel!
    private var progressView: UIProgressView!
    private var cancelButton: UIButton!
    private var copyButton: UIButton!
    private var uploadResult: UploadResult?
    private var hostingController: UIHostingController<SuccessView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.processAndUploadSharedItem()
        }
    }

    private func setupUI() {
        statusLabel = UILabel()
        statusLabel.text = "Processing shared content..."
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = 0.0
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)

        cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)

        copyButton = UIButton(type: .system)
        copyButton.setTitle("Copy Link", for: .normal)
        copyButton.addTarget(self, action: #selector(copyButtonTapped), for: .touchUpInside)
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        copyButton.isHidden = true
        view.addSubview(copyButton)

        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),

            progressView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            cancelButton.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 20),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            copyButton.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 15),
            copyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func copyButtonTapped() {
        // This button is hidden on success, so this action is unlikely to be triggered then.
        // If triggered before success (e.g., if shown in an intermediate state),
        // it wouldn't have a URL yet.
    }

    @objc private func cancelButtonTapped() {
        if hostingController != nil {
             extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        } else {
             extensionContext?.cancelRequest(withError: NSError(domain: "UserCancelled", code: 0, userInfo: nil))
        }
    }

    func processAndUploadSharedItem() {
        guard let extensionContext = self.extensionContext else {
            showError("Invalid extension context")
            return
        }

        let config = ConfigurationManager.shared.loadConfiguration()

        if config.serverURL.isEmpty || config.username.isEmpty {
             showError("Server not configured. Please set up in the main app.")
             return
        }

        uploadService.setupAPIClient()

        guard uploadService.isAPIClientConfigured() else {
            showError("Server configuration is invalid. Please check settings in the main app.")
            return
        }

        guard let item = extensionContext.inputItems.first as? NSExtensionItem,
              let attachment = item.attachments?.first else {
            showError("No file or content found to share.")
            return
        }

        if attachment.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            loadAndUploadItem(attachment: attachment, typeIdentifier: UTType.fileURL.identifier)
        } else if attachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            loadAndUploadItem(attachment: attachment, typeIdentifier: UTType.movie.identifier)
        } else if attachment.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            loadAndUploadItem(attachment: attachment, typeIdentifier: UTType.image.identifier)
        } else if attachment.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
            loadAndUploadItem(attachment: attachment, typeIdentifier: UTType.text.identifier)
        } else {
            showError("Unsupported content type.")
        }
    }

    private func loadAndUploadItem(attachment: NSItemProvider, typeIdentifier: String) {
        attachment.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] (itemData, error) in
            guard let self = self else { return }

            if let error = error {
                self.showError("Error loading content: \(error.localizedDescription)")
                return
            }

            var fileURLToUpload: URL?
            var temporaryFileURL: URL?

            switch itemData {
            case let url as URL:
                fileURLToUpload = url

            case let urlData as Data:
                 if let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                      fileURLToUpload = url
                 } else {
                      self.showError("Invalid file data received.")
                      return
                 }

            case let image as UIImage:
                temporaryFileURL = self.saveImageToTempFile(image: image)
                fileURLToUpload = temporaryFileURL
                if fileURLToUpload == nil {
                    self.showError("Failed to save shared image.")
                    return
                }

            case let text as String:
                temporaryFileURL = self.saveTextToTempFile(text: text)
                fileURLToUpload = temporaryFileURL
                if fileURLToUpload == nil {
                    self.showError("Failed to save shared text.")
                    return
                }

            default:
                self.showError("Unsupported content format.")
                return
            }

            guard let finalURL = fileURLToUpload else {
                return
            }

            DispatchQueue.main.async {
                self.statusLabel.text = "Starting upload..."
                self.progressView.progress = 0

                Task {
                    await self.performUpload(fileURL: finalURL, temporaryFileURL: temporaryFileURL)
                }
            }
        }
    }

    private func performUpload(fileURL: URL, temporaryFileURL: URL?) async {
         let result = await uploadService.uploadFile(fileURL: fileURL) { [weak self] phase in
             Task { @MainActor in
                 guard let self = self else { return }
                 switch phase {
                 case .generatingPreview:
                     self.statusLabel.text = "Generating preview..."
                     self.progressView.setProgress(0.1, animated: true)
                 case .uploading(let progress):
                     self.statusLabel.text = "Uploading (\(Int(progress * 100))%)..."
                     self.progressView.setProgress(Float(progress), animated: true)
                 }
             }
         }

         if let tempURL = temporaryFileURL {
             try? FileManager.default.removeItem(at: tempURL)
         }

         await MainActor.run {
             switch result {
             case .success(let uploadResult):
                 self.uploadResult = uploadResult
                 self.showSuccessView(result: uploadResult)
                 self.cancelButton.setTitle("Done", for: .normal)

             case .failure(let error):
                 self.showError("Upload Failed: \(error.localizedDescription)")
             }
         }
     }

    private func showSuccessView(result: UploadResult) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.showSuccessView(result: result) }
            return
        }

        statusLabel.isHidden = true
        progressView.isHidden = true
        copyButton.isHidden = true

        let successViewModel = UploadViewModel()
        successViewModel.uploadState = .success(result)

        let successSwiftUIView = SuccessView(viewModel: successViewModel, isShareExtensionContext: true)

        let hc = UIHostingController(rootView: successSwiftUIView)
        self.hostingController = hc

        addChild(hc)
        view.addSubview(hc.view)
        hc.didMove(toParent: self)

        hc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hc.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hc.view.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -20)
        ])

        view.bringSubviewToFront(cancelButton)
    }

    private func saveImageToTempFile(image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }

        let fileManager = FileManager.default
        let tempDirectoryURL = fileManager.temporaryDirectory
        let fileName = "shared_image_\(UUID().uuidString).jpg"
        let fileURL = tempDirectoryURL.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }

    private func saveTextToTempFile(text: String) -> URL? {
        let fileManager = FileManager.default
        let tempDirectoryURL = fileManager.temporaryDirectory
        let fileName = "shared_text_\(UUID().uuidString).txt"
        let fileURL = tempDirectoryURL.appendingPathComponent(fileName)

        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }

    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
            self.statusLabel.textColor = .red
            self.progressView.isHidden = true
            self.copyButton.isHidden = true
            self.cancelButton.setTitle("Close", for: .normal)
        }
    }
}
