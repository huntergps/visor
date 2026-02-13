package tech.galapagos.theosvisor

import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.UUID

class MainActivity : FlutterActivity() {
    companion object {
        private const val SCAN_CHANNEL = "tech.galapagos.theosvisor/scan"
        private const val METHOD_CHANNEL = "tech.galapagos.theosvisor/hardware"
        private const val BT_CHANNEL = "tech.galapagos.theosvisor/bluetooth"
        private const val SCAN_ACTION = "tech.galapagos.theosvisor.SCAN"
        private const val DW_API_ACTION = "com.symbol.datawedge.api.ACTION"
        private val SPP_UUID = UUID.fromString("00001101-0000-1000-8000-00805f9b34fb")
    }

    private var eventSink: EventChannel.EventSink? = null
    private var scanReceiver: BroadcastReceiver? = null
    private var btSocket: BluetoothSocket? = null

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

        // MethodChannel: Bluetooth operations for Zebra printer
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BT_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPairedDevices" -> getPairedBluetoothDevices(result)
                    "connect" -> {
                        val address = call.argument<String>("address") ?: ""
                        connectBluetooth(address, result)
                    }
                    "send" -> {
                        val data = call.argument<String>("data") ?: ""
                        sendBluetoothData(data, result)
                    }
                    "disconnect" -> disconnectBluetooth(result)
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

    // --- Bluetooth methods for Zebra printer ---

    private fun hasBluetoothPermissions(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val connect = ContextCompat.checkSelfPermission(this, android.Manifest.permission.BLUETOOTH_CONNECT)
            val scan = ContextCompat.checkSelfPermission(this, android.Manifest.permission.BLUETOOTH_SCAN)
            return connect == PackageManager.PERMISSION_GRANTED &&
                   scan == PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    private fun requestBluetoothPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    android.Manifest.permission.BLUETOOTH_CONNECT,
                    android.Manifest.permission.BLUETOOTH_SCAN
                ),
                101
            )
        }
    }

    private fun getPairedBluetoothDevices(result: MethodChannel.Result) {
        try {
            if (!hasBluetoothPermissions()) {
                requestBluetoothPermissions()
                result.error("BT_NO_PERMISSION", "Permisos Bluetooth no concedidos. Intente de nuevo.", null)
                return
            }
            val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            val adapter = btManager?.adapter
            if (adapter == null) {
                result.error("BT_NO_ADAPTER", "Bluetooth no disponible en este dispositivo", null)
                return
            }
            val bonded = adapter.bondedDevices ?: emptySet()
            val devices = bonded.map { device ->
                mapOf("name" to (device.name ?: "Desconocido"), "address" to device.address)
            }
            android.util.Log.i("TheosVisor_BT", "Paired devices found: ${devices.size}")
            for (d in devices) {
                android.util.Log.i("TheosVisor_BT", "  - ${d["name"]} (${d["address"]})")
            }
            result.success(devices)
        } catch (e: SecurityException) {
            android.util.Log.e("TheosVisor_BT", "SecurityException getting paired devices", e)
            result.error("BT_SECURITY", "Error de permisos: ${e.message}", null)
        } catch (e: Exception) {
            android.util.Log.e("TheosVisor_BT", "Error getting paired devices", e)
            result.error("BT_ERROR", "Error: ${e.message}", null)
        }
    }

    private fun connectBluetooth(address: String, result: MethodChannel.Result) {
        Thread {
            try {
                if (!hasBluetoothPermissions()) {
                    runOnUiThread {
                        requestBluetoothPermissions()
                        result.error("BT_NO_PERMISSION", "Permisos Bluetooth no concedidos. Intente de nuevo.", null)
                    }
                    return@Thread
                }
                // Disconnect existing socket
                btSocket?.let {
                    try { it.close() } catch (_: Exception) {}
                }
                val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                val adapter = btManager?.adapter
                if (adapter == null) {
                    runOnUiThread { result.error("BT_NO_ADAPTER", "Bluetooth no disponible", null) }
                    return@Thread
                }
                // cancelDiscovery is best practice but not essential
                try { adapter.cancelDiscovery() } catch (_: SecurityException) {}
                val device = adapter.getRemoteDevice(address)
                val socket = device.createRfcommSocketToServiceRecord(SPP_UUID)
                socket.connect()
                btSocket = socket
                android.util.Log.i("TheosVisor_BT", "Connected to $address")
                runOnUiThread { result.success(true) }
            } catch (e: IOException) {
                android.util.Log.e("TheosVisor_BT", "Connection failed to $address", e)
                runOnUiThread { result.error("BT_CONNECT_FAIL", "No se pudo conectar: ${e.message}", null) }
            } catch (e: Exception) {
                android.util.Log.e("TheosVisor_BT", "Connection error to $address", e)
                runOnUiThread { result.error("BT_ERROR", "Error: ${e.message}", null) }
            }
        }.start()
    }

    private fun sendBluetoothData(data: String, result: MethodChannel.Result) {
        Thread {
            try {
                val socket = btSocket
                if (socket == null || !socket.isConnected) {
                    runOnUiThread { result.error("BT_NOT_CONNECTED", "No hay conexión Bluetooth activa", null) }
                    return@Thread
                }
                socket.outputStream.write(data.toByteArray(Charsets.UTF_8))
                socket.outputStream.flush()
                android.util.Log.i("TheosVisor_BT", "Sent ${data.length} bytes via Bluetooth")
                runOnUiThread { result.success(true) }
            } catch (e: IOException) {
                android.util.Log.e("TheosVisor_BT", "Send failed", e)
                runOnUiThread { result.error("BT_SEND_FAIL", "Error al enviar: ${e.message}", null) }
            }
        }.start()
    }

    private fun disconnectBluetooth(result: MethodChannel.Result) {
        try {
            btSocket?.let {
                try { it.close() } catch (_: Exception) {}
            }
            btSocket = null
            android.util.Log.i("TheosVisor_BT", "Disconnected")
            result.success(true)
        } catch (e: Exception) {
            result.error("BT_ERROR", "Error al desconectar: ${e.message}", null)
        }
    }

    override fun onDestroy() {
        unregisterScanReceiver()
        btSocket?.let {
            try { it.close() } catch (_: Exception) {}
        }
        btSocket = null
        super.onDestroy()
    }
}
