import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val isProductionReleaseTask = gradle.startParameter.taskNames.any {
    it.contains("Production", ignoreCase = true) &&
        it.contains("Release", ignoreCase = true)
}

android {
    namespace = "com.youssefshawky.guessparty"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.youssefshawky.guessparty"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Google's public test AdMob app ID. Development and staging always use it;
    // production reads admobAppId from key.properties (kept out of git).
    val testAdMobAppId = "ca-app-pub-3940256099942544~3347511713"
    val productionAdMobAppId = (keystoreProperties["admobAppId"] as String?)
        ?.takeIf { it.isNotBlank() }
    if (isProductionReleaseTask && productionAdMobAppId == null) {
        logger.warn(
            "admobAppId is not set in key.properties: production uses the AdMob test app ID.",
        )
    }

    flavorDimensions += "environment"
    productFlavors {
        create("development") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Guess Party Dev")
            manifestPlaceholders["admobAppId"] = testAdMobAppId
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "Guess Party Staging")
            manifestPlaceholders["admobAppId"] = testAdMobAppId
        }
        create("production") {
            dimension = "environment"
            resValue("string", "app_name", "Guess Party")
            manifestPlaceholders["admobAppId"] = productionAdMobAppId ?: testAdMobAppId
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (isProductionReleaseTask && !keystorePropertiesFile.exists()) {
                throw GradleException("Production release signing is not configured.")
            }
            // Release artifacts are never signed with the debug key. A production
            // key.properties file is supplied outside version control/through CI.
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}
