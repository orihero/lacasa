plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "uz.lacasa.lacasa_mobile"
    // Pinned to 37 rather than Flutter's default (36, `flutter.compileSdkVersion`):
    // permission_handler_android 14.0.0 publishes AAR metadata requiring every
    // consumer to compile against API 37+, so a 36 app module fails
    // `checkDebugAarMetadata` outright. Compiling against a newer SDK does not
    // change runtime behaviour — targetSdk stays on Flutter's default below.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "uz.lacasa.lacasa_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Flutter's default (24) is left as-is: the highest floor among the
        // plugins added for image/permission/link/webview capabilities is
        // also 24 (image_picker, webview_flutter), so nothing here needs
        // raising it.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
