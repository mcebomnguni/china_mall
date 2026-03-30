pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "eClinic"

// App Module
include(":app")

// Core Modules
include(":core:ui")
include(":core:network")
include(":core:database")
include(":core:security")
include(":core:common")

// Feature Modules
include(":features:auth")
include(":features:patient")
include(":features:doctor")
include(":features:nurse")
include(":features:admin")
include(":features:manager")
include(":features:district")
include(":features:regional")
include(":features:provincial")
include(":features:national")
include(":features:appointments")
include(":features:pharmacy")
include(":features:notifications")
include(":features:sync")
