package com.ontechinc.htpio

import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    // Optionally, manually register the plugin if necessary (but typically this is not required)
    override fun configureFlutterEngine() {
        super.configureFlutterEngine()
        GeneratedPluginRegistrant.registerWith(flutterEngine!!)
    }
}
