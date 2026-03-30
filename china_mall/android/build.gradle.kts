// Root build.gradle.kts
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Android Gradle Plugin 8.9.1
        classpath("com.android.tools.build:gradle:8.9.1")
        // Updated Kotlin Gradle Plugin to match your metadata (2.3.10)
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.3.10")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Custom build directories
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // Moved evaluationDependsOn inside a check to prevent issues with non-app modules
    if (project.name != "app") {
        evaluationDependsOn(":app")
    }
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}