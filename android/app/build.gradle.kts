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

android {
    namespace = "com.inoxoft.afterlife"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Update to your actual unique Application ID for production
        applicationId = "com.inoxoft.afterlife"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // MultiDex support for large applications
        multiDexEnabled = true
        
        // Vector drawable support
        vectorDrawables.useSupportLibrary = true
        
        // Proguard optimization files
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // Disable code shrinking for now due to flutter_gemma compatibility issues
            isMinifyEnabled = false
            isShrinkResources = false
            
            // Use the release signing config
            signingConfig = signingConfigs.getByName("release")
            
            // Proguard configuration
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            
            // Ensure release builds are debuggable in case of issues
            isDebuggable = false
            
            // Enable multidex optimization
            multiDexKeepProguard = file("multidex-config.pro")
        }
        
        debug {
            isDebuggable = true
            isMinifyEnabled = false
            multiDexEnabled = true
            signingConfig = signingConfigs.getByName("debug")
            applicationIdSuffix = ".debug"
        }
    }
    
    // Configure build features
    buildFeatures {
        buildConfig = true
    }
    
    // Bundle configuration for app bundles
    bundle {
        language {
            // Enable per-language APKs
            enableSplit = true
        }
        density {
            // Enable per-density APKs  
            enableSplit = true
        }
        abi {
            // Enable per-ABI APKs
            enableSplit = true
        }
    }
    
    // Packaging options
    packagingOptions {
        resources {
            excludes += listOf(
                "/META-INF/{AL2.0,LGPL2.1}",
                "/META-INF/DEPENDENCIES",
                "/META-INF/LICENSE",
                "/META-INF/LICENSE.txt",
                "/META-INF/license.txt",
                "/META-INF/NOTICE",
                "/META-INF/NOTICE.txt",
                "/META-INF/notice.txt",
                "/META-INF/ASL2.0"
            )
        }
        // Ensure native libraries are extracted on device (required by some ML runtimes/plugins)
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

flutter {
    source = "../.."
}
