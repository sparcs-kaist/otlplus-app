package org.sparcs.otlplus.api

import android.content.Context

class TokenStore(context: Context) {
    var accessToken: String? = null
    var refreshToken: String? = null
    private val sharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    init {
        loadTokens()
    }

    private fun loadTokens() {
        accessToken = sharedPreferences.getString("flutter.access_token", null)
        refreshToken = sharedPreferences.getString("flutter.refresh_token", null)
    }

    fun updateTokens(newAccessToken: String, newRefreshToken: String) {
        sharedPreferences.edit()
            .putString("flutter.access_token", newAccessToken)
            .putString("flutter.refresh_token", newRefreshToken)
            .apply()
        loadTokens()
    }
}
