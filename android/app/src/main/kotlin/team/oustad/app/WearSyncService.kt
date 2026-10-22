package team.oustad.app

import android.content.Context
import android.util.Log
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable

object WearSyncService {
    private const val TAG = "WearSyncService"
    private const val DATA_PATH = "/member_data"

    fun sendToWatch(context: Context, data: Map<String, Any?>) {
        try {
            val request = PutDataMapRequest.create(DATA_PATH).apply {
                dataMap.apply {
                    putString("userName", data["userName"] as? String ?: "")
                    putInt("memberId", (data["memberId"] as? Int) ?: 0)
                    putString("subscriptionStatus", data["subscriptionStatus"] as? String ?: "")
                    putString("subscriptionName", data["subscriptionName"] as? String ?: "")
                    putString("gymName", data["gymName"] as? String ?: "")
                    putInt("daysLeft", (data["daysLeft"] as? Int) ?: 0)
                    putString("expiresAt", data["expiresAt"] as? String ?: "")
                    putString("todayPlanningTitle", data["todayPlanningTitle"] as? String ?: "")
                    putInt("todayExercisesCount", (data["todayExercisesCount"] as? Int) ?: 0)
                    putString("qrBase64", data["qrBase64"] as? String ?: "")
                    // Timestamp forces DataClient to treat this as a new item even if values unchanged
                    putLong("timestamp", System.currentTimeMillis())
                }
            }.asPutDataRequest().setUrgent()

            Wearable.getDataClient(context).putDataItem(request)
                .addOnSuccessListener { Log.d(TAG, "Watch data synced") }
                .addOnFailureListener { Log.w(TAG, "Watch sync failed: ${it.message}") }
        } catch (e: Exception) {
            Log.w(TAG, "WearSyncService error: ${e.message}")
        }
    }
}
