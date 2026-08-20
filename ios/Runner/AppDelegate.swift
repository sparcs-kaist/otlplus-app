import UIKit
import Flutter
import ChannelIOFront
import Darwin
import Security
import WatchConnectivity
import WidgetKit

private struct AppleTokenPair: Codable {
  let accessToken: String
  let refreshToken: String

  var isValid: Bool {
    !accessToken.isEmpty && !refreshToken.isEmpty
  }
}

private enum TokenVaultError: LocalizedError {
  case invalidTokenPair
  case keychain(OSStatus)
  case lockUnavailable
  case lockFailed(Int32)

  var errorDescription: String? {
    switch self {
    case .invalidTokenPair:
      return "Token pair is missing or invalid."
    case .keychain(let status):
      return SecCopyErrorMessageString(status, nil) as String? ?? "Keychain error \(status)."
    case .lockUnavailable:
      return "Shared token vault container is unavailable."
    case .lockFailed(let code):
      return "Shared token vault lock failed (\(code))."
    }
  }
}

private enum SharedTokenVaultLock {
  static let appGroup = "group.org.sparcs.otl"
  private static let fileName = "token-vault.lock"

  static func withLock<T>(_ operation: () throws -> T) throws -> T {
    guard let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroup
    ) else {
      throw TokenVaultError.lockUnavailable
    }

    let descriptor = open(
      container.appendingPathComponent(fileName).path,
      O_CREAT | O_RDWR,
      S_IRUSR | S_IWUSR
    )
    guard descriptor >= 0 else {
      throw TokenVaultError.lockFailed(errno)
    }
    defer { close(descriptor) }

    guard flock(descriptor, LOCK_EX) == 0 else {
      throw TokenVaultError.lockFailed(errno)
    }
    defer { flock(descriptor, LOCK_UN) }
    return try operation()
  }
}

private enum SharedTokenRefreshLease {
  private static let fileName = "token-refresh.lock"
  private static let timeout: TimeInterval = 15
  private static let stateLock = NSLock()
  private static var descriptors: [String: Int32] = [:]

  static func acquire() -> String? {
    guard let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: SharedTokenVaultLock.appGroup
    ) else {
      return nil
    }
    let descriptor = open(
      container.appendingPathComponent(fileName).path,
      O_CREAT | O_RDWR,
      S_IRUSR | S_IWUSR
    )
    guard descriptor >= 0 else {
      return nil
    }

    let deadline = Date().addingTimeInterval(timeout)
    while flock(descriptor, LOCK_EX | LOCK_NB) != 0 {
      if Date() >= deadline {
        close(descriptor)
        return nil
      }
      usleep(50_000)
    }

    let leaseId = UUID().uuidString
    stateLock.lock()
    descriptors[leaseId] = descriptor
    stateLock.unlock()
    return leaseId
  }

  static func release(_ leaseId: String) {
    stateLock.lock()
    let descriptor = descriptors.removeValue(forKey: leaseId)
    stateLock.unlock()
    guard let descriptor = descriptor else {
      return
    }
    flock(descriptor, LOCK_UN)
    close(descriptor)
  }
}

private enum SharedTokenVault {
  static let service = "org.sparcs.otlplus.token-vault"
  static let account = "token-pair"
  static let accessGroup = "N5V8W52U3U.org.sparcs.otlplus.token-vault"

  static func read() throws -> AppleTokenPair? {
    try SharedTokenVaultLock.withLock(readUnlocked)
  }

  static func write(_ pair: AppleTokenPair) throws {
    try SharedTokenVaultLock.withLock {
      try writeUnlocked(pair)
    }
  }

  static func writeIfRefreshTokenMatches(
    expectedRefreshToken: String,
    pair: AppleTokenPair
  ) throws -> Bool {
    try SharedTokenVaultLock.withLock {
      guard try readUnlocked()?.refreshToken == expectedRefreshToken else {
        return false
      }
      try writeUnlocked(pair)
      return true
    }
  }

  static func clear() throws {
    try SharedTokenVaultLock.withLock(clearUnlocked)
  }

  static func clearIfRefreshTokenMatches(
    _ expectedRefreshToken: String
  ) throws -> Bool {
    try SharedTokenVaultLock.withLock {
      guard try readUnlocked()?.refreshToken == expectedRefreshToken else {
        return false
      }
      try clearUnlocked()
      return true
    }
  }

  private static func readUnlocked() throws -> AppleTokenPair? {
    var query = baseQuery
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    if status == errSecItemNotFound {
      return nil
    }
    guard status == errSecSuccess, let data = result as? Data else {
      throw TokenVaultError.keychain(status)
    }

    let pair = try JSONDecoder().decode(AppleTokenPair.self, from: data)
    guard pair.isValid else {
      throw TokenVaultError.invalidTokenPair
    }
    return pair
  }

  private static func writeUnlocked(_ pair: AppleTokenPair) throws {
    guard pair.isValid else {
      throw TokenVaultError.invalidTokenPair
    }

    let data = try JSONEncoder().encode(pair)
    let attributes: [String: Any] = [
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]
    let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
    if updateStatus == errSecSuccess {
      return
    }
    guard updateStatus == errSecItemNotFound else {
      throw TokenVaultError.keychain(updateStatus)
    }

    var item = baseQuery
    attributes.forEach { item[$0.key] = $0.value }
    let addStatus = SecItemAdd(item as CFDictionary, nil)
    if addStatus == errSecSuccess {
      return
    }
    if addStatus == errSecDuplicateItem {
      let retryStatus = SecItemUpdate(
        baseQuery as CFDictionary,
        attributes as CFDictionary
      )
      guard retryStatus == errSecSuccess else {
        throw TokenVaultError.keychain(retryStatus)
      }
      return
    }
    throw TokenVaultError.keychain(addStatus)
  }

  private static func clearUnlocked() throws {
    let status = SecItemDelete(baseQuery as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw TokenVaultError.keychain(status)
    }
  }

  private static var baseQuery: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecAttrAccessGroup as String: accessGroup,
    ]
  }
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private static let tokenVaultChannelName = "org.sparcs.otlplus/token_vault"
  private static let widgetAppGroup = "group.org.sparcs.otl"
  private static let legacyTokenKeys = Set(["accessToken", "refreshToken"])

  private var tokenVaultChannel: FlutterMethodChannel?
  private var watchSession: WCSession?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    ChannelIO.initialize(application)
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      configureTokenVaultChannel(binaryMessenger: controller.binaryMessenger)
    }
    activateWatchSessionIfSupported()
    removeLegacyWidgetTokens()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configureTokenVaultChannel(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: Self.tokenVaultChannelName,
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleTokenVaultCall(call, result: result)
    }
    tokenVaultChannel = channel
  }

  private func handleTokenVaultCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      switch call.method {
      case "readTokenPair":
        let pair = try SharedTokenVault.read()
        result(pair.map {
          ["accessToken": $0.accessToken, "refreshToken": $0.refreshToken]
        })
      case "writeTokenPair":
        let pair = try tokenPair(from: call)
        try SharedTokenVault.write(pair)
        synchronizeReplicas(pair)
        result(nil)
      case "writeTokenPairIfRefreshTokenMatches":
        let pair = try tokenPair(from: call)
        let expectedRefreshToken = try requiredString(
          "expectedRefreshToken",
          from: call
        )
        let written = try SharedTokenVault.writeIfRefreshTokenMatches(
          expectedRefreshToken: expectedRefreshToken,
          pair: pair
        )
        synchronizeReplicas(try SharedTokenVault.read())
        result(written)
      case "clearTokenPair":
        try SharedTokenVault.clear()
        synchronizeReplicas(nil)
        result(nil)
      case "clearTokenPairIfRefreshTokenMatches":
        let expectedRefreshToken = try requiredString(
          "expectedRefreshToken",
          from: call
        )
        let cleared = try SharedTokenVault.clearIfRefreshTokenMatches(
          expectedRefreshToken
        )
        synchronizeReplicas(try SharedTokenVault.read())
        result(cleared)
      case "acquireRefreshLease":
        DispatchQueue.global(qos: .utility).async {
          let leaseId = SharedTokenRefreshLease.acquire()
          DispatchQueue.main.async {
            result(leaseId)
          }
        }
      case "releaseRefreshLease":
        let leaseId = try requiredString("leaseId", from: call)
        SharedTokenRefreshLease.release(leaseId)
        result(nil)
      case "syncTokenReplicas":
        synchronizeReplicas(try SharedTokenVault.read())
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch {
      result(FlutterError(
        code: "token_vault_error",
        message: error.localizedDescription,
        details: nil
      ))
    }
  }

  private func tokenPair(from call: FlutterMethodCall) throws -> AppleTokenPair {
    let pair = AppleTokenPair(
      accessToken: try requiredString("accessToken", from: call),
      refreshToken: try requiredString("refreshToken", from: call)
    )
    guard pair.isValid else {
      throw TokenVaultError.invalidTokenPair
    }
    return pair
  }

  private func requiredString(
    _ key: String,
    from call: FlutterMethodCall
  ) throws -> String {
    guard
      let arguments = call.arguments as? [String: Any],
      let value = arguments[key] as? String,
      !value.isEmpty
    else {
      throw TokenVaultError.invalidTokenPair
    }
    return value
  }

  private func synchronizeReplicas(_ pair: AppleTokenPair?) {
    removeLegacyWidgetTokens()
    reloadWidgets()
    sendTokenStateToWatch(pair)
  }

  private func removeLegacyWidgetTokens() {
    guard let defaults = UserDefaults(suiteName: Self.widgetAppGroup) else {
      return
    }
    for key in Self.legacyTokenKeys where defaults.object(forKey: key) != nil {
      defaults.removeObject(forKey: key)
    }
  }

  private func reloadWidgets() {
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadAllTimelines()
    }
  }

  private func activateWatchSessionIfSupported() {
    guard WCSession.isSupported() else {
      return
    }
    let session = WCSession.default
    session.delegate = self
    watchSession = session
    session.activate()
  }

  private func sendTokenStateToWatch(_ pair: AppleTokenPair?) {
    guard
      let session = watchSession,
      session.activationState == .activated,
      session.isPaired,
      session.isWatchAppInstalled
    else {
      return
    }

    let userID = UserDefaults(suiteName: Self.widgetAppGroup)?.string(forKey: "uid") ?? ""
    let context: [String: Any]
    if let pair = pair {
      context = [
        "method": "tokenPair",
        "accessToken": pair.accessToken,
        "userID": userID,
      ]
    } else {
      context = [
        "method": "clearTokenPair",
        "userID": "",
      ]
    }
    try? session.updateApplicationContext(context)
  }
}

extension AppDelegate: WCSessionDelegate {
  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    guard activationState == .activated else {
      return
    }
    do {
      synchronizeReplicas(try SharedTokenVault.read())
    } catch {
      return
    }
  }

  func sessionDidBecomeInactive(_ session: WCSession) {}

  func sessionDidDeactivate(_ session: WCSession) {
    session.activate()
  }
}
