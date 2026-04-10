import java.nio.charset.Charset
import java.util.Properties
import java.io.FileInputStream

val localProperties = Properties().apply {
    rootProject.file("local.properties").bufferedReader(Charset.forName("UTF-8"))
        .use { reader -> load(reader) }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

val keystoreProperties = Properties().apply {
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystorePropertiesFileExists = keystorePropertiesFile.exists()
    if (keystorePropertiesFileExists) {
        this.load(FileInputStream(keystorePropertiesFile))
    }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "org.sparcs.otlplus"
    compileSdk = rootProject.extra.get("compileSdkVersion")?.toString()?.toIntOrNull()

    sourceSets {
        kotlin.sourceSets["main"].kotlin {
            srcDir("src/main/kotlin")
        }
    }

    lint {
        disable.addAll(
            listOf(
                "InvalidPackage",
            ),
        )
    }

    defaultConfig {
        applicationId = "org.sparcs.otlplus"
        minSdk = flutter.minSdkVersion
        targetSdk = rootProject.extra.get("targetSdkVersion")?.toString()?.toIntOrNull()
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        register("release") {
            if (keystoreProperties.isNotEmpty()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")!!
                keyPassword = keystoreProperties.getProperty("keyPassword")!!
                storeFile = file(keystoreProperties.getProperty("storeFile")!!)
                storePassword = keystoreProperties.getProperty("storePassword")!!
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        viewBinding = true
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("androidx.preference:preference-ktx:1.2.1")
    implementation("androidx.constraintlayout:constraintlayout:2.2.0")
    implementation("com.google.firebase:firebase-analytics")
    implementation("androidx.work:work-runtime-ktx:2.9.0")
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test:runner:1.6.2")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
}
