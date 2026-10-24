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

// Patch AGP 8: add missing namespace for Flutter plugins that still use the old `package` attribute.
// Uses plugins.withId (not afterEvaluate) to avoid the "already evaluated" error caused by
// the evaluationDependsOn(":app") above.
subprojects {
    plugins.withId("com.android.library") {
        val androidLib = extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
        if (androidLib.namespace == null) {
            val manifest = file("src/main/AndroidManifest.xml")
            if (manifest.exists()) {
                val factory = javax.xml.parsers.DocumentBuilderFactory.newInstance()
                val doc = factory.newDocumentBuilder().parse(manifest)
                val pkg = doc.documentElement.getAttribute("package")
                if (pkg.isNotBlank()) androidLib.namespace = pkg
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
