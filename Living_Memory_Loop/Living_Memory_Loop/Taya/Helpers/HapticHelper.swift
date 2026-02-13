import UIKit

enum HapticHelper {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let run = {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
        }

        if Thread.isMainThread {
            run()
        } else {
            DispatchQueue.main.async(execute: run)
        }
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let run = {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(type)
        }

        if Thread.isMainThread {
            run()
        } else {
            DispatchQueue.main.async(execute: run)
        }
    }
}
