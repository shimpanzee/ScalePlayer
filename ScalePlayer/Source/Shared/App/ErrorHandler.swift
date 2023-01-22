//
//  ErrorHandling.swift
//  ScalePlayer
//
//  Created by John Shimmin on 1/11/23.
//  Copyright © 2023 shimmin. All rights reserved.
//

import OSLog
import UIKit

enum ErrorCategory {
    case nonRetryable
    case retryable
}

protocol CategorizedError: Error {
    var category: ErrorCategory { get }
}

extension Error {
    func resolveCategory() -> ErrorCategory {
        guard let categorized = self as? CategorizedError
        else {
            // We could optionally choose to trigger an assertion
            // here, if we consider it important that all of our
            // errors have categories assigned to them.
            return .nonRetryable
        }

        return categorized.category
    }
}

protocol ErrorHandler {
    func report(
        _ error: Error,
        userMessage: String?,
        level: OSLogType?,
        retryHandler: (() -> Void)?)
}

extension ErrorHandler {
    func report(
        _ error: Error,
        userMessage: String? = nil,
        level: OSLogType? = nil,
        retryHandler: (() -> Void)? = nil) {
        report(error, userMessage: userMessage, level: level, retryHandler: retryHandler)
    }
}

class LoggingErrorHandler: ErrorHandler {
    func report(
        _ error: Error,
        userMessage: String? = nil,
        level: OSLogType?,
        retryHandler: (() -> Void)? = nil) {
        let level = level ?? .error

        if let userMessage = userMessage {
            Logger.app.log(level: level, "\(userMessage): \(error.localizedDescription)")
        } else {
            Logger.app.log(level: level, "\(error.localizedDescription)")
        }
    }
}

class UserFacingErrorHandler: ErrorHandler {
    private let viewController: UIViewController
    private let loggingErrorHandler = LoggingErrorHandler()

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    func report(
        _ error: Error,
        userMessage: String? = nil,
        level: OSLogType?,
        retryHandler: (() -> Void)? = nil) {
        loggingErrorHandler.report(
            error,
            userMessage: userMessage,
            level: level,
            retryHandler: retryHandler)

        var message = NSMutableAttributedString(string: error.localizedDescription)
        if let userMessage = userMessage {
            let normalFont = UIFont.preferredFont(forTextStyle: .body)
            let boldFont = UIFont(
                descriptor: normalFont.fontDescriptor.withSymbolicTraits(.traitBold)!,
                size: normalFont.pointSize)
            let boldAttributes: [NSAttributedString.Key: Any] = [.font: boldFont]
            message = NSMutableAttributedString()
                .append(userMessage)
                .append("\n\n")
                .append("Detail:", attributes: boldAttributes)
                .append(error.localizedDescription)
        }

        let alert = UIAlertController(
            title: "An error occured",
            message: "",
            preferredStyle: .alert)

        // Attributed messages seem to be implemented but not supported.
        // Probably wouldn't put this in a shipping app though.
        if alert.responds(to: NSSelectorFromString("setAttributedMessage:")) {
            alert.setValue(message, forKey: "attributedMessage")
        } else {
            alert.message = message.string
        }

        alert.addAction(UIAlertAction(
            title: "Dismiss",
            style: .default))

        switch error.resolveCategory() {
        case .retryable:
            alert.addAction(UIAlertAction(
                title: "Retry",
                style: .default,
                handler: { _ in retryHandler?() }))
        case .nonRetryable:
            break
        }

        viewController.present(alert, animated: true)
    }
}
