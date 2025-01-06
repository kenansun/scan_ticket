package com.example.scan_ticket

import android.media.MediaScannerConnection
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class MediaScannerPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding = binding
        channel = MethodChannel(binding.binaryMessenger, "com.example.scan_ticket/media_scanner")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "scanFile" -> {
                val path = call.argument<String>("path")
                if (path != null) {
                    MediaScannerConnection.scanFile(
                        flutterPluginBinding.applicationContext,
                        arrayOf(path),
                        null
                    ) { _, _ -> result.success(null) }
                } else {
                    result.error("INVALID_ARGUMENT", "Path must not be null", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
