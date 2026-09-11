package com.vcare.admin

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        BiometricCryptoChannel.register(
            this,
            flutterEngine.dartExecutor.binaryMessenger,
        )
    }
}
