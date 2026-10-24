package team.oustad.app.wear

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class WearMainActivity : FlutterActivity() {

    private val channelName = "team.oustad.watch"
    private var methodChannel: MethodChannel? = null

    private val dataReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == WearDataListenerService.ACTION_DATA_UPDATED) {
                pushDataToFlutter()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getLastSyncData" -> result.success(readPrefs())
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        ContextCompat.registerReceiver(
            this,
            dataReceiver,
            IntentFilter(WearDataListenerService.ACTION_DATA_UPDATED),
            ContextCompat.RECEIVER_NOT_EXPORTED
        )
    }

    override fun onPause() {
        super.onPause()
        unregisterReceiver(dataReceiver)
    }

    private fun readPrefs(): Map<String, Any>? {
        val prefs = getSharedPreferences("wear_data", MODE_PRIVATE)
        if (prefs.all.isEmpty()) return null
        return prefs.all
            .filterValues { it != null }
            .mapValues { it.value as Any }
    }

    private fun pushDataToFlutter() {
        val data = readPrefs() ?: return
        runOnUiThread {
            methodChannel?.invokeMethod("updateData", data)
        }
    }
}
