plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ble_bridge"
    compileSdk = 35
    ndkVersion = "27.1.12297006"

    defaultConfig {
        applicationId = "com.example.ble_bridge"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            // keep simple for now; we'll sign later if needed
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
        }
    }

    // JDK 17
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    // aapt2 override not needed on CI, only on-device
    // buildToolsVersion = "35.0.0"
}

flutter {
    source = "../.."
}
