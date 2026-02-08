package org.sparcs.otlplus.api

import android.content.Context
import okhttp3.*
import java.io.IOException
import java.util.concurrent.TimeUnit

class ApiLoader(context: Context) {
    private val tokenStore = TokenStore(context)
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS) // Connection timeout
        .readTimeout(30, TimeUnit.SECONDS)   // Read timeout
        .writeTimeout(30, TimeUnit.SECONDS)  // Write timeout
        .build()

    fun get(url: String, then: (String) -> Unit) {
        val requestBuilder = Request.Builder()
            .url(url)

        tokenStore.accessToken?.let {
            requestBuilder.addHeader("Authorization", "Bearer $it")
        }
        tokenStore.refreshToken?.let {
            requestBuilder.addHeader("X-Refresh-Token", it)
        }

        val request = requestBuilder.build()

        client.newCall(request).enqueue(object: Callback {
            override fun onFailure(call: Call, e: IOException) {
                // Api call failed
            }

            override fun onResponse(call: Call, response: Response) {
                if (!response.isSuccessful) {
                    return
                }
                val responseText = response.body?.string() ?: ""
                then(responseText)
            }
        })
    }
}
