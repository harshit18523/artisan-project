plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.handora.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.handora.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    androidResources {
        noCompress.addAll(
            listOf(
                "png",
                "jpg",
                "jpeg",
                "webp",
                "env",
                "json"
            )
        )
    }

    // Prevent release lint analysis from exhausting the Java heap.
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    buildTypes {
        release {
            // Temporary/debug signing configuration.
            signingConfig = signingConfigs.getByName("debug")

            // Disable R8/minification to reduce memory usage during the build.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
