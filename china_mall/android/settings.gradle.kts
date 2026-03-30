pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val propertiesFile = file("local.properties")
        if (!propertiesFile.exists()) {
            throw GradleException("local.properties file not found. Please run 'flutter pub get' first.")
        }
        propertiesFile.inputStream().use { properties.load(it) }
        val sdkPath = properties.getProperty("flutter.sdk")
        require(sdkPath != null) { "flutter.sdk not set in local.properties" }
        sdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    // Force all plugins to use the correct Kotlin version
    resolutionStrategy {
        eachPlugin {
            if (requested.id.id.startsWith("org.jetbrains.kotlin")) {
                useVersion("2.3.10")
            }
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.10" apply false
}

include(":app")