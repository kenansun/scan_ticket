package com.example.scan_ticket

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.example.scan_ticket.MediaScannerPlugin // Assuming MediaScannerPlugin is in the same package
import com.example.scan_ticket.CameraPlugin // Assuming CameraPlugin is in the same package

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(MediaScannerPlugin())
        flutterEngine.plugins.add(CameraPlugin())
    }
}
