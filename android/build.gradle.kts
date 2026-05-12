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
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val configureAndroid = {
        val ext = project.extensions.findByName("android")
        if (ext != null) {
            val getNamespace = ext::class.java.methods.find { it.name == "getNamespace" }
            val setNamespace = ext::class.java.methods.find { it.name == "setNamespace" }
            if (getNamespace != null && setNamespace != null) {
                val currentNamespace = getNamespace.invoke(ext) as? String
                if (currentNamespace.isNullOrBlank()) {
                    var packageNamespace = ""
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val contents = manifestFile.readText()
                        val match = Regex("package=\"([^\"]+)\"").find(contents)
                        if (match != null) {
                            packageNamespace = match.groupValues[1]
                        }
                    }
                    if (packageNamespace.isBlank()) {
                        packageNamespace = "com.example.${project.name.replace("-", "_").replace(".", "_")}"
                    }
                    setNamespace.invoke(ext, packageNamespace)
                }
            }
        }
    }
    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate {
            configureAndroid()
        }
    }
}
