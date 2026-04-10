package org.sparcs.otlplus.api

import android.content.Context
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit

class ApiLoader(context: Context) {
    private val tokenStore = TokenStore(context)
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS) // Connection timeout
        .readTimeout(30, TimeUnit.SECONDS)   // Read timeout
        .writeTimeout(30, TimeUnit.SECONDS)  // Write timeout
        .build()

    fun getSync(url: String): String? {
        val requestBuilder = Request.Builder()
            .url(url)

        tokenStore.accessToken?.let {
            requestBuilder.addHeader("Authorization", "Bearer $it")
        }

        val request = requestBuilder.build()

        return try {
            val response = client.newCall(request).execute()
            if (response.isSuccessful) {
                response.body?.string()
            } else if (response.code == 401) {
                // Token might be expired, try to refresh
                if (refreshToken()) {
                    // Retry once with new token
                    val newRequestBuilder = Request.Builder()
                        .url(url)
                    tokenStore.accessToken?.let {
                        newRequestBuilder.addHeader("Authorization", "Bearer $it")
                    }
                    val newResponse = client.newCall(newRequestBuilder.build()).execute()
                    if (newResponse.isSuccessful) {
                        newResponse.body?.string()
                    } else {
                        null
                    }
                } else {
                    null
                }
            } else {
                null
            }
        } catch (e: IOException) {
            null
        }
    }

    private fun refreshToken(): Boolean {
        val currentRefreshToken = tokenStore.refreshToken ?: return false
        val baseUrl = "https://otl.kaist.ac.kr"
        val refreshUrl = "$baseUrl/session/refresh"

        val json = JSONObject()
        json.put("token", currentRefreshToken)
        
        val mediaType = "application/json; charset=utf-8".toMediaType()
        val body = json.toString().toRequestBody(mediaType)

        val request = Request.Builder()
            .url(refreshUrl)
            .post(body)
            .build()

        return try {
            val response = client.newCall(request).execute()
            if (response.isSuccessful) {
                val responseBody = response.body?.string() ?: return false
                val jsonResponse = JSONObject(responseBody)
                val newAccessToken = jsonResponse.optString("accessToken")
                val newRefreshToken = jsonResponse.optString("refreshToken")

                if (newAccessToken.isNotEmpty() && newRefreshToken.isNotEmpty()) {
                    tokenStore.updateTokens(newAccessToken, newRefreshToken)
                    true
                } else {
                    false
                }
            } else {
                false
            }
        } catch (e: IOException) {
            false
        }
    }

    // Deprecated or not used in worker for simplicity
    fun get(url: String, then: (String) -> Unit) {
        // ... (existing implementation or update if needed)
    }
}

