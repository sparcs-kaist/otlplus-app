// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "integration_test", path: "../.packages/integration_test"),
        .package(name: "webview_flutter_wkwebview", path: "../.packages/webview_flutter_wkwebview-3.26.0"),
        .package(name: "url_launcher_ios", path: "../.packages/url_launcher_ios-6.3.4"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.4"),
        .package(name: "sentry_flutter", path: "../.packages/sentry_flutter-9.27.0"),
        .package(name: "package_info_plus", path: "../.packages/package_info_plus-9.0.1"),
        .package(name: "posthog_flutter", path: "../.packages/posthog_flutter-5.35.1"),
        .package(name: "permission_handler_apple", path: "../.packages/permission_handler_apple-9.5.0"),
        .package(name: "path_provider_foundation", path: "../.packages/path_provider_foundation-2.4.2"),
        .package(name: "open_app_file", path: "../.packages/open_app_file-4.0.5"),
        .package(name: "firebase_remote_config", path: "../.packages/firebase_remote_config-5.5.0"),
        .package(name: "firebase_core", path: "../.packages/firebase_core-3.15.2"),
        .package(name: "firebase_messaging", path: "../.packages/firebase_messaging-15.2.10"),
        .package(name: "firebase_crashlytics", path: "../.packages/firebase_crashlytics-4.3.10"),
        .package(name: "firebase_analytics", path: "../.packages/firebase_analytics-11.6.0"),
        .package(name: "app_links", path: "../.packages/app_links-6.4.1"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "integration-test", package: "integration_test"),
                .product(name: "webview-flutter-wkwebview", package: "webview_flutter_wkwebview"),
                .product(name: "url-launcher-ios", package: "url_launcher_ios"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "sentry-flutter", package: "sentry_flutter"),
                .product(name: "package-info-plus", package: "package_info_plus"),
                .product(name: "posthog-flutter", package: "posthog_flutter"),
                .product(name: "permission-handler-apple", package: "permission_handler_apple"),
                .product(name: "path-provider-foundation", package: "path_provider_foundation"),
                .product(name: "open-app-file", package: "open_app_file"),
                .product(name: "firebase-remote-config", package: "firebase_remote_config"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "firebase-messaging", package: "firebase_messaging"),
                .product(name: "firebase-crashlytics", package: "firebase_crashlytics"),
                .product(name: "firebase-analytics", package: "firebase_analytics"),
                .product(name: "app-links", package: "app_links"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
