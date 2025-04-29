package com.example.fci_edutrack

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import android.os.Bundle
import io.flutter.Log

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable verbose logging
        Log.setLogLevel(Log.VERBOSE)
        super.onCreate(savedInstanceState)
    }
}
