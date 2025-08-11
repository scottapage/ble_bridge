import java.io.FileInputStream
import java.util.Properties

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

val flutterSdkPath = System.getenv("FLUTTER_ROOT") ?: run {
    val props = Properties()
    val localProps = File(rootDir, "local.properties")
    if (localProps.exists()) {
        props.load(FileInputStream(localProps))
        props.getProperty("flutter.sdk")
    } else null
} ?: throw GradleException("Flutter SDK not found. Set FLUTTER_ROOT or define flutter.sdk in android/local.properties")

includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "ble_bridge"
include(":app")
