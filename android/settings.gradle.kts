pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties().apply {
            file("local.properties")
                .bufferedReader(java.nio.charset.Charset.forName("UTF-8"))
                .use { reader -> load(reader) }
        }
        properties.getProperty("flutter.sdk")
            ?: throw GradleException("flutter.sdk not set in local.properties")
    }
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.10" apply false
}

include(":app")
