package com.example.scan_ticket

import android.hardware.camera2.*
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.content.Context
import android.os.Process

class CameraPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val mainHandler = Handler(Looper.getMainLooper())
    
    private var cameraManager: CameraManager? = null
    private var cameraDevice: CameraDevice? = null
    private var cameraThread: HandlerThread? = null
    private var cameraHandler: Handler? = null

    private fun startCameraThread() {
        cameraThread = HandlerThread("CameraThread", Process.THREAD_PRIORITY_MORE_FAVORABLE).apply {
            start()
            cameraHandler = Handler(looper)
        }
    }

    private fun stopCameraThread() {
        try {
            cameraHandler?.removeCallbacksAndMessages(null)
            cameraHandler = null
            cameraThread?.quitSafely()
            cameraThread?.join(1000)
            cameraThread = null
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun cleanup() {
        try {
            cameraDevice?.close()
            cameraDevice = null
            stopCameraThread()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun openCamera() {
        try {
            startCameraThread()
            val cameraIds = cameraManager?.cameraIdList
            if (!cameraIds.isNullOrEmpty()) {
                cameraManager?.openCamera(cameraIds[0], object : CameraDevice.StateCallback() {
                    override fun onOpened(camera: CameraDevice) {
                        mainHandler.post {
                            cameraDevice = camera
                            // 这里可以添加创建预览会话的代码
                        }
                    }

                    override fun onDisconnected(camera: CameraDevice) {
                        mainHandler.post {
                            cleanup()
                        }
                    }

                    override fun onError(camera: CameraDevice, error: Int) {
                        mainHandler.post {
                            cleanup()
                        }
                    }
                }, cameraHandler)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            cleanup()
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.example.scan_ticket/camera")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
        cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        cleanup()
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initializeCamera" -> {
                try {
                    openCamera()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("CAMERA_ERROR", e.message, null)
                }
            }
            "cleanupCamera" -> {
                try {
                    cleanup()
                    result.success(null)
                } catch (e: Exception) {
                    result.error("CAMERA_ERROR", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }
}
