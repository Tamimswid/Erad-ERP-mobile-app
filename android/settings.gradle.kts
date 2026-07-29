pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // Aliyun mirrors (primary)
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        // Fallback to original repos
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")

// Force all subprojects (plugins) to use the same AGP and Kotlin versions
// This prevents plugins from using their own hardcoded AGP versions
gradle.projectsLoaded {
    rootProject.allprojects {
        buildscript {
            repositories {
                // Aliyun mirrors (primary)
                maven { url = uri("https://maven.aliyun.com/repository/google") }
                maven { url = uri("https://maven.aliyun.com/repository/public") }
                maven { url = uri("https://maven.aliyun.com/repository/central") }
                // Fallback to original repos
                google()
                mavenCentral()
            }
            configurations.classpath {
                resolutionStrategy.eachDependency {
                    if (requested.group == "com.android.tools.build" && requested.name == "gradle") {
                        useVersion("8.11.1")
                        because("Force AGP 8.11.1 for all subprojects to avoid version conflicts")
                    }
                    if (requested.group == "org.jetbrains.kotlin") {
                        useVersion("2.1.0")
                        because("Force Kotlin 2.1.0 for all subprojects to avoid version conflicts")
                    }
                }
            }
        }
    }
}