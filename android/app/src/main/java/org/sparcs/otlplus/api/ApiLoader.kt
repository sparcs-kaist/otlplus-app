package org.sparcs.otlplus.api

import android.content.Context
import java.io.IOException
import java.util.concurrent.TimeUnit
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONException
import org.json.JSONObject

enum class ApiLoadFailure {
    REJECTED,
    UNAVAILABLE,
}

data class ApiLoadResult(
    val body: String? = null,
    val failure: ApiLoadFailure? = null,
)

private enum class RefreshResult {
    SUCCESS,
    SUPERSEDED,
    REJECTED,
    UNAVAILABLE,
}

class ApiLoader {
    private val tokenStore: TokenStore
    private val client: OkHttpClient
    private val baseUrl: String

    constructor(context: Context) : this(
        TokenStore(context),
        createHttpClient(),
        DEFAULT_BASE_URL,
    )

    internal constructor(
        tokenStore: TokenStore,
        client: OkHttpClient,
        baseUrl: String,
    ) {
        this.tokenStore = tokenStore
        this.client = client
        this.baseUrl = baseUrl.trimEnd('/')
    }

    fun getSync(url: String): String? = getSyncResult(url).body

    fun getSyncResult(url: String): ApiLoadResult {
        return try {
            val requestAccessToken = tokenStore.accessToken
            val response = executeGet(url, requestAccessToken)
            when {
                response.first != null -> ApiLoadResult(body = response.first)
                response.second != 401 -> ApiLoadResult(failure = ApiLoadFailure.UNAVAILABLE)
                else -> when (refreshToken(requestAccessToken)) {
                    RefreshResult.SUCCESS,
                    RefreshResult.SUPERSEDED -> retryWithCurrentAccessToken(url)

                    RefreshResult.REJECTED -> ApiLoadResult(failure = ApiLoadFailure.REJECTED)
                    RefreshResult.UNAVAILABLE -> ApiLoadResult(failure = ApiLoadFailure.UNAVAILABLE)
                }
            }
        } catch (_: IOException) {
            ApiLoadResult(failure = ApiLoadFailure.UNAVAILABLE)
        } catch (_: TokenVaultException) {
            ApiLoadResult(failure = ApiLoadFailure.UNAVAILABLE)
        }
    }

    private fun executeGet(url: String, accessToken: String?): Pair<String?, Int> {
        val requestBuilder = Request.Builder().url(url)
        accessToken?.let { requestBuilder.addHeader("Authorization", "Bearer $it") }
        return client.newCall(requestBuilder.build()).execute().use { response ->
            Pair(if (response.isSuccessful) response.body?.string() else null, response.code)
        }
    }

    private fun refreshToken(expiredAccessToken: String?): RefreshResult {
        val leaseId = TokenRefreshLease.acquire() ?: return RefreshResult.UNAVAILABLE
        return try {
            val currentPair = tokenStore.readTokenPair() ?: return RefreshResult.REJECTED
            if (expiredAccessToken != null && currentPair.accessToken != expiredAccessToken) {
                return RefreshResult.SUPERSEDED
            }

            val attemptedRefreshToken = currentPair.refreshToken
            val body = JSONObject()
                .put("token", attemptedRefreshToken)
                .toString()
                .toRequestBody(JSON_MEDIA_TYPE)
            val request = Request.Builder()
                .url("$baseUrl/session/refresh")
                .post(body)
                .build()

            try {
                client.newCall(request).execute().use { response ->
                    if (response.code in 400..499) {
                        val cleared = tokenStore.clearTokensIfRefreshTokenMatches(
                            attemptedRefreshToken,
                        )
                        return@use if (cleared) {
                            RefreshResult.REJECTED
                        } else {
                            RefreshResult.SUPERSEDED
                        }
                    }
                    if (!response.isSuccessful) {
                        return@use RefreshResult.UNAVAILABLE
                    }

                    val responseBody = response.body?.string()
                        ?: return@use RefreshResult.UNAVAILABLE
                    val jsonResponse = JSONObject(responseBody)
                    val newAccessToken = jsonResponse.opt("accessToken") as? String
                    val newRefreshToken = jsonResponse.opt("refreshToken") as? String
                    if (newAccessToken.isNullOrEmpty() || newRefreshToken.isNullOrEmpty()) {
                        val cleared = tokenStore.clearTokensIfRefreshTokenMatches(
                            attemptedRefreshToken,
                        )
                        return@use if (cleared) {
                            RefreshResult.REJECTED
                        } else {
                            RefreshResult.SUPERSEDED
                        }
                    }

                    val written = tokenStore.updateTokensIfRefreshTokenMatches(
                        expectedRefreshToken = attemptedRefreshToken,
                        newAccessToken = newAccessToken,
                        newRefreshToken = newRefreshToken,
                    )
                    if (written) RefreshResult.SUCCESS else RefreshResult.SUPERSEDED
                }
            } catch (_: IOException) {
                RefreshResult.UNAVAILABLE
            } catch (_: JSONException) {
                RefreshResult.UNAVAILABLE
            } catch (_: TokenVaultException) {
                RefreshResult.UNAVAILABLE
            }
        } finally {
            TokenRefreshLease.release(leaseId)
        }
    }

    private fun retryWithCurrentAccessToken(url: String): ApiLoadResult {
        val response = executeGet(url, tokenStore.accessToken)
        return if (response.first != null) {
            ApiLoadResult(body = response.first)
        } else {
            ApiLoadResult(failure = ApiLoadFailure.UNAVAILABLE)
        }
    }

    private companion object {
        const val DEFAULT_BASE_URL = "https://otl.kaist.ac.kr"
        val JSON_MEDIA_TYPE = "application/json; charset=utf-8".toMediaType()
        val REFRESH_LOCK = Any()

        fun createHttpClient(): OkHttpClient {
            return OkHttpClient.Builder()
                .connectTimeout(30, TimeUnit.SECONDS)
                .readTimeout(30, TimeUnit.SECONDS)
                .writeTimeout(30, TimeUnit.SECONDS)
                .build()
        }
    }
}
