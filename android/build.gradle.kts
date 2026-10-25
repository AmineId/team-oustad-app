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

// Kotlin 2.x fails the build when a module's Kotlin jvmTarget differs from its Java target.
// Old plugins (e.g. `wear` 1.1.0) declare no compileOptions: Java falls back to 1.8 while Kotlin
// targets the running JDK. Align Kotlin on each module's Java target (read lazily, after evaluation).
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile>().configureEach {
        val android = project.extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
            ?: return@configureEach
        compilerOptions.jvmTarget.set(
            org.jetbrains.kotlin.gradle.dsl.JvmTarget.fromTarget(
                android.compileOptions.targetCompatibility.toString()
            )
        )
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
