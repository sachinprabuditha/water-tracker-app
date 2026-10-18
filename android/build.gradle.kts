allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// AGP defaults every module (the app and each plugin) to Build Tools 35.0.0,
// which isn't installed on this machine. Use the installed 36.1.0 instead.
// Safe to delete once Build Tools 35.0.0 is installed via SDK Manager.
// Must stay above evaluationDependsOn(":app"), which evaluates :app right away.
subprojects {
    listOf("com.android.application", "com.android.library").forEach { id ->
        pluginManager.withPlugin(id) {
            extensions.getByName("android").withGroovyBuilder {
                "setBuildToolsVersion"("36.1.0")
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
