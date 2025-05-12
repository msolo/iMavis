import Combine
import Foundation
import SwiftUI

// Prototype comes from here:
// https://www.avanderlee.com/swift/appstorage-explained/
//
// Very well thought out. About the only better thing would be directly having
// a modeled object rather than having to specify @Preference in the classes
// that need it. Maybe something like $Prefs.shared.prefName.

final class Prefs {
  static let shared = Prefs(userDefaults: .standard)
  fileprivate let userDefaults: UserDefaults

  // Sends through the changed key path whenever a change occurs.
  var preferencesChangedSubject = PassthroughSubject<AnyKeyPath, Never>()

  init(userDefaults: UserDefaults) {
    self.userDefaults = userDefaults
  }

  @UserDefault("speechVoiceIdentifier") var speechVoiceIdentifier = ""
  @UserDefault("speechRate") var speechRate = 0.5
  @UserDefault("speechPitch") var speechPitch = 1.0
  @UserDefault("speechVolume") var speechVolume = 0.5

  @UserDefault("bellVolume") var bellVolume = 0.5
  @UserDefault("boopVolume") var boopVolume = 0.5
  @UserDefault("loudBellVolume") var loudBellVolume = 0.5
  @UserDefault("keyClickVolume") var keyClickVolume = 0.5
  @UserDefault("soundbiteVolume") var soundbiteVolume = 1.0

  @UserDefault("minReturnKeyDelay") var minReturnKeyDelay = 0.4  // 400ms seems good.

  @UserDefault("noisyTyping") var noisyTyping = true
  @UserDefault("logChatHistory") var logChatHistory = true
  @UserDefault("speakSentencesAutomatically") var speakSentencesAutomatically = false
  @UserDefault("ignoreUselessKeys") var ignoreUselessKeys = true
  @UserDefault("enableSoundbites") var enableSoundbites = true
  @UserDefault("disableScreenLock") var disableScreenLock = false
  @UserDefault("screenLockMinutes") var screenLockMinutes = 30.0  // 30 minutes

  @UserDefault("enableCorrectorService") var enableCorrectorService = false
  @UserDefault("showCorrectionsAutomatically") var showCorrectionsAutomatically = false

  // These control Apple's builtin text capabilities.
  @UserDefault("enableInlineTextPredictions") var enableInlineTextPredictions = true
  @UserDefault("enableInlineTextCorrections") var enableInlineTextCorrections = true

  @UserDefault("fontSize") var fontSize = Double(
    UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body).pointSize)
}

@propertyWrapper
struct UserDefault<Value> {
  let key: String
  let defaultValue: Value

  var wrappedValue: Value {
    get { fatalError("Wrapped value should not be used.") }
    set { fatalError("Wrapped value should not be used.") }
  }

  init(wrappedValue: Value, _ key: String) {
    self.defaultValue = wrappedValue
    self.key = key
  }

  public static subscript(
    _enclosingInstance instance: Prefs,
    wrapped wrappedKeyPath: ReferenceWritableKeyPath<Prefs, Value>,
    storage storageKeyPath: ReferenceWritableKeyPath<Prefs, Self>
  ) -> Value {
    get {
      let container = instance.userDefaults
      let key = instance[keyPath: storageKeyPath].key
      let defaultValue = instance[keyPath: storageKeyPath].defaultValue
      return container.object(forKey: key) as? Value ?? defaultValue
    }
    set {
      let container = instance.userDefaults
      let key = instance[keyPath: storageKeyPath].key
      container.set(newValue, forKey: key)
      instance.preferencesChangedSubject.send(wrappedKeyPath)
    }
  }
}

final class PublisherObservableObject: ObservableObject {

  var subscriber: AnyCancellable?

  init(publisher: AnyPublisher<Void, Never>) {
    subscriber = publisher.sink(receiveValue: { [weak self] _ in
      self?.objectWillChange.send()
    })
  }
}

@propertyWrapper
struct Preference<Value>: DynamicProperty {
  @ObservedObject private var preferencesObserver: PublisherObservableObject
  private let keyPath: ReferenceWritableKeyPath<Prefs, Value>
  private let preferences: Prefs

  init(_ keyPath: ReferenceWritableKeyPath<Prefs, Value>, preferences: Prefs = .shared) {
    self.keyPath = keyPath
    self.preferences = preferences
    let publisher = preferences
      .preferencesChangedSubject
      .filter { changedKeyPath in
        changedKeyPath == keyPath
      }.map { _ in () }
      .eraseToAnyPublisher()
    self.preferencesObserver = .init(publisher: publisher)
  }

  var wrappedValue: Value {
    get { preferences[keyPath: keyPath] }
    nonmutating set { preferences[keyPath: keyPath] = newValue }
  }

  var projectedValue: Binding<Value> {
    Binding(
      get: { wrappedValue },
      set: { wrappedValue = $0 }
    )
  }
}
