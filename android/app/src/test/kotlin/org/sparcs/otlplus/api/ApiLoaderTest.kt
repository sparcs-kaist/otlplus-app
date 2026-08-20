package org.sparcs.otlplus.api

import java.util.concurrent.TimeUnit
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test

class ApiLoaderTest {
    private lateinit var server: MockWebServer

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()
    }

    @After
    fun tearDown() {
        server.shutdown()
    }

    @Test
    fun `refresh rejection clears the attempted pair and reports rejected`() {
        server.enqueue(MockResponse().setResponseCode(401))
        server.enqueue(MockResponse().setResponseCode(401))

        val preferences = ApiLoaderTestPreferences()
        val tokenStore = TokenStore(preferences, ApiLoaderTestCipher()) {}
        tokenStore.updateTokens("old-access", "old-refresh")
        val loader = ApiLoader(
            tokenStore,
            OkHttpClient.Builder()
                .callTimeout(5, TimeUnit.SECONDS)
                .build(),
            server.url("/").toString(),
        )

        val result = loader.getSyncResult(server.url("/resource").toString())

        assertEquals(ApiLoadFailure.REJECTED, result.failure)
        assertNull(result.body)
        assertNull(tokenStore.readTokenPair())
    }

    @Test
    fun `401 refresh atomically rotates the pair and retries with the new access token`() {
        server.enqueue(MockResponse().setResponseCode(401))
        server.enqueue(
            MockResponse()
                .setResponseCode(200)
                .setHeader("Content-Type", "application/json")
                .setBody(
                    JSONObject()
                        .put("accessToken", "new-access")
                        .put("refreshToken", "new-refresh")
                        .toString(),
                ),
        )
        server.enqueue(MockResponse().setResponseCode(200).setBody("resource-body"))

        val preferences = ApiLoaderTestPreferences()
        val tokenStore = TokenStore(preferences, ApiLoaderTestCipher()) {}
        tokenStore.updateTokens("old-access", "old-refresh")
        val loader = ApiLoader(
            tokenStore,
            OkHttpClient.Builder()
                .callTimeout(5, TimeUnit.SECONDS)
                .build(),
            server.url("/").toString(),
        )

        assertEquals("resource-body", loader.getSync(server.url("/resource").toString()))

        val initialRequest = server.takeRequest()
        assertEquals("/resource", initialRequest.path)
        assertEquals("Bearer old-access", initialRequest.getHeader("Authorization"))

        val refreshRequest = server.takeRequest()
        assertEquals("/session/refresh", refreshRequest.path)
        assertNull(refreshRequest.getHeader("Authorization"))
        assertEquals("old-refresh", JSONObject(refreshRequest.body.readUtf8()).getString("token"))

        val retryRequest = server.takeRequest()
        assertEquals("/resource", retryRequest.path)
        assertEquals("Bearer new-access", retryRequest.getHeader("Authorization"))
        assertEquals(TokenPair("new-access", "new-refresh"), tokenStore.readTokenPair())
    }
}

private class ApiLoaderTestPreferences : TokenPreferences {
    override var encryptedEnvelope: String? = null
    override val legacyAccessToken: String? = null
    override val legacyRefreshToken: String? = null

    override fun writeEncryptedEnvelope(value: String): Boolean {
        encryptedEnvelope = value
        return true
    }

    override fun clearEncryptedEnvelope(): Boolean {
        encryptedEnvelope = null
        return true
    }

    override fun clearLegacyTokens(): Boolean = true
}

private class ApiLoaderTestCipher : TokenCipher {
    override fun encrypt(plaintext: ByteArray): EncryptedTokenPayload {
        return EncryptedTokenPayload(
            iv = byteArrayOf(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12),
            ciphertext = plaintext.map { (it.toInt() xor 0x5a).toByte() }.toByteArray(),
        )
    }

    override fun decrypt(payload: EncryptedTokenPayload): ByteArray {
        return payload.ciphertext.map { (it.toInt() xor 0x5a).toByte() }.toByteArray()
    }

    override fun reset() = Unit
}
