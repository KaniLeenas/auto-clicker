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
// Build all modules (including plugins such as `jni`) with the NDK already
// installed on this PC instead of downloading Flutter's default NDK 28.2.
val installedNdkVersion = "29.0.13846066"
subprojects {
    val useInstalledNdk = {
        (extensions.findByName("android") as? com.android.build.gradle.BaseExtension)
            ?.ndkVersion = installedNdkVersion
    }
    if (state.executed) useInstalledNdk() else afterEvaluate { useInstalledNdk() }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
