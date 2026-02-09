package org.sparcs.otlplus.api

import android.content.Context

class TokenStore(context: Context) {
    val accessToken: String?
    val refreshToken: String?

    init {
        val sharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        accessToken = sharedPreferences.getString("flutter.access_token", null)
        refreshToken = sharedPreferences.getString("flutter.refresh_token", null)
    }
}
