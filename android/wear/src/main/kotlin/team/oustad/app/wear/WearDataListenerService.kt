package team.oustad.app.wear

import android.content.Intent
import android.util.Log
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.WearableListenerService

class WearDataListenerService : WearableListenerService() {

    companion object {
        private const val TAG = "WearDataListener"
        private const val DATA_PATH = "/member_data"
        const val ACTION_DATA_UPDATED = "team.oustad.app.wear.DATA_UPDATED"
    }

    override fun onDataChanged(dataEvents: DataEventBuffer) {
        for (event in dataEvents) {
            if (event.type == DataEvent.TYPE_CHANGED &&
                event.dataItem.uri.path == DATA_PATH
            ) {
                val dataMap = DataMapItem.fromDataItem(event.dataItem).dataMap
                Log.d(TAG, "Données reçues du téléphone: ${dataMap.keySet()}")

                // Sauvegarder dans SharedPreferences (lu par WearMainActivity via MethodChannel)
                val prefs = getSharedPreferences("wear_data", MODE_PRIVATE)
                prefs.edit().apply {
                    putString("userName",            dataMap.getString("userName", ""))
                    putInt("memberId",               dataMap.getInt("memberId", 0))
                    putString("subscriptionStatus",  dataMap.getString("subscriptionStatus", ""))
                    putString("subscriptionName",    dataMap.getString("subscriptionName", ""))
                    putString("gymName",             dataMap.getString("gymName", ""))
                    putInt("daysLeft",               dataMap.getInt("daysLeft", 0))
                    putString("expiresAt",           dataMap.getString("expiresAt", ""))
                    putString("todayPlanningTitle",  dataMap.getString("todayPlanningTitle", ""))
                    putInt("todayExercisesCount",    dataMap.getInt("todayExercisesCount", 0))
                    putString("qrBase64",            dataMap.getString("qrBase64", ""))
                    apply()
                }

                // Notifier l'activité si elle est active
                sendBroadcast(Intent(ACTION_DATA_UPDATED))
            }
        }
    }
}
