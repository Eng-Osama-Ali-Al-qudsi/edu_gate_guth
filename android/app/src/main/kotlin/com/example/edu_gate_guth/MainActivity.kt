package com.example.edu_gate_guth

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val rememberedIdentifierChannel =
        "edu_gate_guth/remembered_identifier"
    private val preferencesName = "edu_gate_guth_preferences"
    private val rememberedIdentifierKey = "remembered_identifier"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            rememberedIdentifierChannel
        ).setMethodCallHandler { call, result ->
            val preferences = getSharedPreferences(preferencesName, Context.MODE_PRIVATE)

            when (call.method) {
                "readIdentifier" -> {
                    result.success(preferences.getString(rememberedIdentifierKey, null))
                }
                "saveIdentifier" -> {
                    val identifier = call.argument<String>("identifier")?.trim()
                    if (identifier.isNullOrEmpty()) {
                        result.error("INVALID_IDENTIFIER", "Identifier must not be empty.", null)
                    } else {
                        val saved = preferences.edit()
                            .putString(rememberedIdentifierKey, identifier)
                            .commit()
                        if (saved) result.success(null)
                        else result.error("PREFERENCE_WRITE_FAILED", "Could not save identifier.", null)
                    }
                }
                "clearIdentifier" -> {
                    val cleared = preferences.edit()
                        .remove(rememberedIdentifierKey)
                        .commit()
                    if (cleared) result.success(null)
                    else result.error("PREFERENCE_CLEAR_FAILED", "Could not clear identifier.", null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
