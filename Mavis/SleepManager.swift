import Foundation
import UIKit

// Set a timer that will make re-enable the application idle
// timer some interval after the last activity. This is means
// the screen will stay active for at least the interval
// specified, and then respect the iOS preferences on
// idle lock.
class SleepManager {
  private var timer: DispatchSourceTimer?
  private let queue = DispatchQueue(label: "com.hiredgoons.iMavis.sleepTimer")
  static let shared = SleepManager()

  func deferSleep(_ interval: TimeInterval) {
    // Cancel any existing timer
    timer?.cancel()
    timer = nil

    // Create a new DispatchSourceTimer
    timer = DispatchSource.makeTimerSource(queue: queue)
    timer?.schedule(deadline: .now() + interval)
    timer?.setEventHandler { [weak self] in
      self?.performSleep()
    }
    timer?.resume()
  }

  private func performSleep() {
    print("re-enable screen lock idle timer")
    UIApplication.shared.isIdleTimerDisabled = false
  }
}
