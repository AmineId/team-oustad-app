package team.oustad.app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val SECURITY_CHANNEL = "team.oustad.security"
    private val WATCH_CHANNEL = "team.oustad.watch"

    private var lastWatchData: Map<String, Any?> = emptyMap()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setScreenCaptureBlocked" -> {
                    try {
                        if (call.arguments as? Boolean == true) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SCREEN_CAPTURE_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Wear OS watch sync channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WATCH_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "syncMemberData" -> {
                    @Suppress("UNCHECKED_CAST")
                    val data = call.arguments as? Map<String, Any?> ?: emptyMap()
                    lastWatchData = data
                    WearSyncService.sendToWatch(applicationContext, data)
                    result.success(true)
                }
                "getLastSyncData" -> {
                    result.success(lastWatchData.ifEmpty { null })
                }
                else -> result.notImplemented()
            }
        }
    }
}
