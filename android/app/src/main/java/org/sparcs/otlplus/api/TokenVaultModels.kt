package org.sparcs.otlplus.api

import okio.ByteString.Companion.decodeBase64
import okio.ByteString.Companion.toByteString
import org.json.JSONException
import org.json.JSONObject

internal data class TokenPair(
    val accessToken: String,
    val refreshToken: String,
) {
    init {
        require(accessToken.isNotEmpty() && refreshToken.isNotEmpty()) {
            "Token pair values must be non-empty."
        }
    }
}

internal data class EncryptedTokenPayload(
    val iv: ByteArray,
    val ciphertext: ByteArray,
)

internal interface TokenCipher {
    fun encrypt(plaintext: ByteArray): EncryptedTokenPayload

    fun decrypt(payload: EncryptedTokenPayload): ByteArray

    fun reset()
}

internal interface TokenPreferences {
    val encryptedEnvelope: String?
    val legacyAccessToken: String?
    val legacyRefreshToken: String?

    fun writeEncryptedEnvelope(value: String): Boolean

    fun clearEncryptedEnvelope(): Boolean

    fun clearLegacyTokens(): Boolean
}

internal object TokenVaultCodec {
    private const val VERSION = 1
    private const val ALGORITHM = "AES-256-GCM"
    private const val GCM_IV_BYTES = 12
    private const val GCM_TAG_BYTES = 16

    fun encodeTokenPair(pair: TokenPair): ByteArray {
        return JSONObject()
            .put("version", VERSION)
            .put("accessToken", pair.accessToken)
            .put("refreshToken", pair.refreshToken)
            .toString()
            .toByteArray(Charsets.UTF_8)
    }

    fun decodeTokenPair(value: ByteArray): TokenPair {
        val json = JSONObject(value.toString(Charsets.UTF_8))
        if (json.opt("version") != VERSION) {
            throw JSONException("Unsupported token pair version.")
        }

        val accessToken = json.opt("accessToken") as? String
        val refreshToken = json.opt("refreshToken") as? String
        if (accessToken.isNullOrEmpty() || refreshToken.isNullOrEmpty()) {
            throw JSONException("Invalid token pair.")
        }
        return TokenPair(accessToken, refreshToken)
    }

    fun encodeEnvelope(payload: EncryptedTokenPayload): String {
        require(payload.iv.size == GCM_IV_BYTES) { "Invalid GCM IV length." }
        require(payload.ciphertext.size >= GCM_TAG_BYTES) { "Invalid GCM ciphertext length." }

        return JSONObject()
            .put("version", VERSION)
            .put("algorithm", ALGORITHM)
            .put("iv", payload.iv.toByteString().base64())
            .put("ciphertext", payload.ciphertext.toByteString().base64())
            .toString()
    }

    fun decodeEnvelope(value: String): EncryptedTokenPayload {
        val json = JSONObject(value)
        if (json.opt("version") != VERSION || json.opt("algorithm") != ALGORITHM) {
            throw JSONException("Unsupported token vault envelope.")
        }

        val encodedIv = json.opt("iv") as? String
            ?: throw JSONException("Invalid token vault IV.")
        val encodedCiphertext = json.opt("ciphertext") as? String
            ?: throw JSONException("Invalid token vault ciphertext.")
        val iv = encodedIv.decodeBase64()?.toByteArray()
            ?: throw JSONException("Invalid token vault IV.")
        val ciphertext = encodedCiphertext.decodeBase64()?.toByteArray()
            ?: throw JSONException("Invalid token vault ciphertext.")
        if (iv.size != GCM_IV_BYTES || ciphertext.size < GCM_TAG_BYTES) {
            throw JSONException("Invalid token vault payload length.")
        }
        return EncryptedTokenPayload(iv, ciphertext)
    }
}

class TokenVaultException(message: String, cause: Throwable? = null) : IllegalStateException(message, cause)
