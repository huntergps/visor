package tech.galapagos.theosvisor

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val SCAN_CHANNEL = "tech.galapagos.theosvisor/scan"
        private const val METHOD_CHANNEL = "tech.galapagos.theosvisor/hardware"
        private const val SCAN_ACTION = "tech.galapagos.theosvisor.SCAN"
        private const val DW_API_ACTION = "com.symbol.datawedge.api.ACTION"
    }

    private var eventSink: EventChannel.EventSink? = null
    private var scanReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // MethodChannel: detect if device has DataWedge (hardware barcode scanner)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasHardwareScanner" -> {
                        val hasDataWedge = try {
                            @Suppress("DEPRECATION")
                            packageManager.getPackageInfo("com.symbol.datawedge", 0)
                            true
                        } catch (_: Exception) {
                            false
                        }
                        result.success(hasDataWedge)
                    }
                    else -> result.notImplemented()
                }
            }

        // EventChannel: stream barcode scan results from DataWedge
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SCAN_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerScanReceiver()
                    configureDataWedge()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    unregisterScanReceiver()
                }
            })
    }

    private fun registerScanReceiver() {
        if (scanReceiver != null) return
        scanReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val barcode = intent?.getStringExtra("com.symbol.datawedge.data_string")
                if (!barcode.isNullOrEmpty()) {
                    eventSink?.success(barcode.trim())
                }
            }
        }
        val filter = IntentFilter(SCAN_ACTION).apply {
            addCategory(Intent.CATEGORY_DEFAULT)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(scanReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(scanReceiver, filter)
        }
    }

    private fun unregisterScanReceiver() {
        scanReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Exception) {}
        }
        scanReceiver = null
    }

    private fun configureDataWedge() {
        // Enable intent output for this app
        sendDataWedgeConfig(Bundle().apply {
            putString("PLUGIN_NAME", "INTENT")
            putString("RESET_CONFIG", "true")
            putBundle("PARAM_LIST", Bundle().apply {
                putString("intent_output_enabled", "true")
                putString("intent_action", SCAN_ACTION)
                putString("intent_delivery", "2") // 2 = Broadcast
            })
        })
        // Disable keystroke output to avoid duplicates
        sendDataWedgeConfig(Bundle().apply {
            putString("PLUGIN_NAME", "KEYSTROKE")
            putString("RESET_CONFIG", "true")
            putBundle("PARAM_LIST", Bundle().apply {
                putString("keystroke_output_enabled", "false")
            })
        })
    }

    private fun sendDataWedgeConfig(pluginConfig: Bundle) {
        val profileConfig = Bundle().apply {
            putString("PROFILE_NAME", "TheosVisor")
            putString("PROFILE_ENABLED", "true")
            putString("CONFIG_MODE", "CREATE_IF_NOT_EXIST")
            putParcelableArray("APP_LIST", arrayOf(Bundle().apply {
                putString("PACKAGE_NAME", packageName)
                putStringArray("ACTIVITY_LIST", arrayOf("*"))
            }))
            putBundle("PLUGIN_CONFIG", pluginConfig)
        }
        sendBroadcast(Intent(DW_API_ACTION).apply {
            putExtra("com.symbol.datawedge.api.SET_CONFIG", profileConfig)
        })
    }

    override fun onDestroy() {
        unregisterScanReceiver()
        super.onDestroy()
    }
}
