import com.android.build.gradle.BaseExtension

// android/build.gradle.kts

buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.4")
        classpath ("com.android.tools.build:gradle:8.11.1")
    }
}

plugins {
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// --- Optional custom build directory ---
val newBuildDir: Directory =
    rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

// 🟩 NAMESPACE FIXER
subprojects {
    afterEvaluate {
        extensions.findByType(BaseExtension::class.java)?.let { ext ->
            if (ext.namespace == null) {
                ext.namespace = "${project.group}.${project.name}"
            }
        }
    }
}

// 🟩 CLEAN TASK
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
