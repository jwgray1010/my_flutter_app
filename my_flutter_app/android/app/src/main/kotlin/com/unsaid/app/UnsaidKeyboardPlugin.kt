package com.unsaid.app

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import android.view.inputmethod.InputMethodInfo
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class UnsaidKeyboardPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "unsaid_keyboard")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isKeyboardAvailable" -> {
                result.success(isUnsaidKeyboardInstalled())
            }
            "isKeyboardEnabled" -> {
                result.success(isUnsaidKeyboardEnabled())
            }
            "enableKeyboard" -> {
                val enable = call.argument<Boolean>("enable") ?: false
                result.success(enableUnsaidKeyboard(enable))
            }
            "openKeyboardSettings" -> {
                openKeyboardSettings()
                result.success(null)
            }
            "requestKeyboardPermissions" -> {
                result.success(requestKeyboardPermissions())
            }
            "getKeyboardStatus" -> {
                result.success(getKeyboardStatus())
            }
            "updateKeyboardSettings" -> {
                val settings = call.arguments as? Map<String, Any> ?: emptyMap()
                result.success(updateKeyboardSettings(settings))
            }
            "sendToneAnalysis" -> {
                val text = call.argument<String>("text") ?: ""
                val analysis = call.argument<Map<String, Any>>("analysis") ?: emptyMap()
                sendToneAnalysis(text, analysis)
                result.success(null)
            }
            "processTextInput" -> {
                val text = call.argument<String>("text") ?: ""
                result.success(processTextInput(text))
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun isUnsaidKeyboardInstalled(): Boolean {
        val inputMethodManager = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        val inputMethods = inputMethodManager.inputMethodList
        
        return inputMethods.any { inputMethod ->
            inputMethod.packageName == context.packageName
        }
    }

    private fun isUnsaidKeyboardEnabled(): Boolean {
        val inputMethodManager = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        val enabledInputMethods = inputMethodManager.enabledInputMethodList
        
        return enabledInputMethods.any { inputMethod ->
            inputMethod.packageName == context.packageName
        }
    }

    private fun enableUnsaidKeyboard(enable: Boolean): Boolean {
        // Note: On Android, you cannot programmatically enable/disable keyboards
        // You can only direct the user to settings
        openKeyboardSettings()
        return true
    }

    private fun openKeyboardSettings() {
        val intent = Intent(Settings.ACTION_INPUT_METHOD_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }

    private fun requestKeyboardPermissions(): Boolean {
        // Check if we have necessary permissions
        return isUnsaidKeyboardInstalled()
    }

    private fun getKeyboardStatus(): Map<String, Any> {
        return mapOf(
            "installed" to isUnsaidKeyboardInstalled(),
            "enabled" to isUnsaidKeyboardEnabled(),
            "active" to isCurrentKeyboard()
        )
    }

    private fun isCurrentKeyboard(): Boolean {
        val inputMethodManager = context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        val currentInputMethod = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.DEFAULT_INPUT_METHOD
        )
        
        return currentInputMethod?.contains(context.packageName) == true
    }

    private fun updateKeyboardSettings(settings: Map<String, Any>): Boolean {
        // Store settings in SharedPreferences for the keyboard service to access
        val prefs = context.getSharedPreferences("unsaid_keyboard_settings", Context.MODE_PRIVATE)
        val editor = prefs.edit()
        
        settings.forEach { (key, value) ->
            when (value) {
                is Boolean -> editor.putBoolean(key, value)
                is String -> editor.putString(key, value)
                is Int -> editor.putInt(key, value)
                is Float -> editor.putFloat(key, value)
                is Double -> editor.putFloat(key, value.toFloat())
                else -> editor.putString(key, value.toString())
            }
        }
        
        return editor.commit()
    }

    private fun sendToneAnalysis(text: String, analysis: Map<String, Any>) {
        // Store analysis for keyboard service
        val prefs = context.getSharedPreferences("unsaid_keyboard_data", Context.MODE_PRIVATE)
        val editor = prefs.edit()
        
        editor.putString("last_text", text)
        editor.putString("last_analysis", analysis.toString())
        editor.putLong("analysis_timestamp", System.currentTimeMillis())
        
        editor.apply()
        
        // Broadcast to keyboard service if it's running
        val intent = Intent("com.unsaid.keyboard.TONE_ANALYSIS")
        intent.putExtra("text", text)
        intent.putExtra("analysis", analysis.toString())
        context.sendBroadcast(intent)
    }

    private fun processTextInput(text: String): String {
        // For now, return the original text
        // In production, apply tone corrections here
        return text
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
