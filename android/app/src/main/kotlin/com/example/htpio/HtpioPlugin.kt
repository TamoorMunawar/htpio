package com.ontechinc.htpio

import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.PluginRegistry

class HtpioPlugin : MethodChannel.MethodCallHandler {

    // Handle method calls from Flutter
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                // Respond with the platform version
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        // Register the plugin with the Flutter engine
        @JvmStatic
        fun registerWith(registrar: PluginRegistry.Registrar) {
            val channel = MethodChannel(registrar.messenger(), "htpio")
            channel.setMethodCallHandler(HtpioPlugin())
        }
    }
}
