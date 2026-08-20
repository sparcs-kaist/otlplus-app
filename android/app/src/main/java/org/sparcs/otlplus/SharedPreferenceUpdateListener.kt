package org.sparcs.otlplus

import android.content.Context
import android.content.SharedPreferences

class SharedPreferenceUpdateListener(context: Context) {
    private val sharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    private val preferenceChangeListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        if (key != LEGACY_ACCESS_TOKEN_KEY && key != LEGACY_REFRESH_TOKEN_KEY) {
            WidgetRefreshDispatcher.refresh(context)
        }
    }

    fun register() {
        sharedPreferences.registerOnSharedPreferenceChangeListener(preferenceChangeListener)
    }

    fun unregister() {
        sharedPreferences.unregisterOnSharedPreferenceChangeListener(preferenceChangeListener)
    }

    private companion object {
        const val LEGACY_ACCESS_TOKEN_KEY = "flutter.access_token"
        const val LEGACY_REFRESH_TOKEN_KEY = "flutter.refresh_token"
    }
}
