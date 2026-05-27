plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun readRootEnv(): Map<String, String> {
    val envFile = rootProject.file("../../.env")
    if (!envFile.exists()) return emptyMap()

    return envFile.readLines()
        .mapNotNull { line ->
            val trimmed = line.trim()
            if (trimmed.isEmpty() || trimmed.startsWith("#") || !trimmed.contains("=")) {
                return@mapNotNull null
            }

            val key = trimmed.substringBefore("=").trim()
            val value = trimmed.substringAfter("=").trim().trim('"', '\'')
            key to value
        }
        .toMap()
}

val rootEnv = readRootEnv()

fun envValue(name: String, fallback: String): String {
    return providers.environmentVariable(name).orNull
        ?: rootEnv[name]
        ?: fallback
}

android {
    namespace = "com.example.frontend"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.frontend"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        val facebookAppId = envValue("FACEBOOK_APP_ID", "YOUR_FACEBOOK_APP_ID")
        resValue("string", "facebook_app_id", facebookAppId)
        resValue(
            "string",
            "facebook_client_token",
            envValue("FACEBOOK_CLIENT_TOKEN", "YOUR_FACEBOOK_CLIENT_TOKEN")
        )
        resValue("string", "fb_login_protocol_scheme", "fb$facebookAppId")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
