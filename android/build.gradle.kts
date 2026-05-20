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

subprojects {
    // evaluationDependsOn must come first so `:app` is ready before other modules,
    // but afterEvaluate is registered in the same pass so it fires for every
    // non-app subproject once it finishes evaluating itself.
    if (project.name != "app") {
        afterEvaluate {
            project.extensions.findByType<com.android.build.gradle.LibraryExtension>()
                ?.compileSdk = 36
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
