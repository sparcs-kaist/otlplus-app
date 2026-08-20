package org.sparcs.otlplus.api

import android.content.Context
import android.util.Log
import java.security.GeneralSecurityException
import java.security.ProviderException
import org.json.JSONException
import org.sparcs.otlplus.WidgetRefreshDispatcher

class TokenStore {
    private val preferences: TokenPreferences
    private val cipher: TokenCipher
    private val onTokensChanged: () -> Unit
    private val onWarning: (String) -> Unit

    constructor(context: Context) {
        val applicationContext = context.applicationContext
        preferences = AndroidTokenPreferences(applicationContext)
        cipher = AndroidKeystoreTokenCipher()
        onTokensChanged = { WidgetRefreshDispatcher.refresh(applicationContext) }
        onWarning = { message -> Log.w(TAG, message) }
    }

    internal constructor(
        preferences: TokenPreferences,
        cipher: TokenCipher,
        onTokensChanged: () -> Unit,
        onWarning: (String) -> Unit = {},
    ) {
        this.preferences = preferences
        this.cipher = cipher
        this.onTokensChanged = onTokensChanged
        this.onWarning = onWarning
    }

    val accessToken: String?
        get() = readTokenPair()?.accessToken

    val refreshToken: String?
        get() = readTokenPair()?.refreshToken

    internal fun readTokenPair(): TokenPair? = synchronized(STORE_LOCK) {
        val encryptedEnvelope = try {
            preferences.encryptedEnvelope
        } catch (error: RuntimeException) {
            return@synchronized discardUnreadableVault(error)
        }
        if (encryptedEnvelope != null) {
            return@synchronized readEncryptedPairOrLogOut(encryptedEnvelope)
        }
        migrateLegacyPair()
    }

    fun updateTokens(newAccessToken: String, newRefreshToken: String) {
        val pair = createPair(newAccessToken, newRefreshToken)
        synchronized(STORE_LOCK) {
            writePairAndNotify(pair)
        }
    }

    internal fun updateTokensIfRefreshTokenMatches(
        expectedRefreshToken: String,
        newAccessToken: String,
        newRefreshToken: String,
    ): Boolean = synchronized(STORE_LOCK) {
        val currentPair = readTokenPair()
        if (currentPair?.refreshToken != expectedRefreshToken) {
            return@synchronized false
        }
        writePairAndNotify(createPair(newAccessToken, newRefreshToken))
        true
    }

    fun clearTokens() = synchronized(STORE_LOCK) {
        clearTokensAndNotify()
    }

    internal fun clearTokensIfRefreshTokenMatches(
        expectedRefreshToken: String,
    ): Boolean = synchronized(STORE_LOCK) {
        val currentPair = readTokenPair()
        if (currentPair?.refreshToken != expectedRefreshToken) {
            return@synchronized false
        }
        clearTokensAndNotify()
        true
    }

    private fun createPair(accessToken: String, refreshToken: String): TokenPair {
        return try {
            TokenPair(accessToken, refreshToken)
        } catch (error: IllegalArgumentException) {
            throw TokenVaultException("Token pair is invalid.", error)
        }
    }

    private fun writePairAndNotify(pair: TokenPair) {
        writeEncryptedPair(pair)
        val legacyCleared = clearLegacyAfterWrite()
        notifyWidgets()
        if (!legacyCleared) {
            throw TokenVaultException("Could not remove legacy token data.")
        }
    }

    private fun clearTokensAndNotify() {
        val vaultCleared = clearEncryptedEnvelopeSafely()
        val legacyCleared = clearLegacyTokensSafely()
        val keyCleared = resetCipherSafely("Could not reset token vault key")
        notifyWidgets()

        if (!vaultCleared || !legacyCleared || !keyCleared) {
            throw TokenVaultException("Could not completely clear token data.")
        }
    }

    private fun migrateLegacyPair(): TokenPair? {
        val legacyAccessToken: String?
        val legacyRefreshToken: String?
        try {
            legacyAccessToken = preferences.legacyAccessToken
            legacyRefreshToken = preferences.legacyRefreshToken
        } catch (error: RuntimeException) {
            return discardUnreadableVault(error)
        }
        if (legacyAccessToken == null && legacyRefreshToken == null) {
            return null
        }
        if (legacyAccessToken.isNullOrEmpty() || legacyRefreshToken.isNullOrEmpty()) {
            if (clearLegacyTokensSafely()) {
                notifyWidgets()
            } else {
                warn("Could not remove incomplete legacy token data")
            }
            return null
        }

        val pair = TokenPair(legacyAccessToken, legacyRefreshToken)
        return try {
            writeEncryptedPair(pair)
            if (!clearLegacyTokensSafely()) {
                warn("Legacy token cleanup will be retried")
            }
            notifyWidgets()
            pair
        } catch (error: TokenVaultException) {
            logVaultFailure("Could not migrate legacy token data", error)
            null
        }
    }

    private fun readEncryptedPairOrLogOut(encryptedEnvelope: String): TokenPair? {
        return try {
            val payload = TokenVaultCodec.decodeEnvelope(encryptedEnvelope)
            val pair = TokenVaultCodec.decodeTokenPair(cipher.decrypt(payload))
            removeLegacyTokensAfterEncryptedRead()
            pair
        } catch (error: GeneralSecurityException) {
            discardUnreadableVault(error)
        } catch (error: ProviderException) {
            throw TokenVaultException("Token vault provider is unavailable.", error)
        } catch (error: JSONException) {
            discardUnreadableVault(error)
        } catch (error: IllegalArgumentException) {
            discardUnreadableVault(error)
        } catch (error: RuntimeException) {
            throw TokenVaultException("Could not read token data.", error)
        }
    }

    private fun discardUnreadableVault(error: Exception): TokenPair? {
        logVaultFailure("Discarding unreadable token vault", error)
        clearEncryptedEnvelopeSafely()
        clearLegacyTokensSafely()
        resetCipherSafely("Could not reset unreadable token vault key")
        notifyWidgets()
        return null
    }

    private fun writeEncryptedPair(pair: TokenPair) {
        try {
            val plaintext = TokenVaultCodec.encodeTokenPair(pair)
            val envelope = TokenVaultCodec.encodeEnvelope(cipher.encrypt(plaintext))
            if (!preferences.writeEncryptedEnvelope(envelope)) {
                throw TokenVaultException("Could not persist encrypted token data.")
            }
        } catch (error: TokenVaultException) {
            throw error
        } catch (error: GeneralSecurityException) {
            throw TokenVaultException("Could not encrypt token data.", error)
        } catch (error: ProviderException) {
            throw TokenVaultException("Could not encrypt token data.", error)
        } catch (error: JSONException) {
            throw TokenVaultException("Could not encode token data.", error)
        } catch (error: IllegalArgumentException) {
            throw TokenVaultException("Could not encode token data.", error)
        } catch (error: RuntimeException) {
            throw TokenVaultException("Could not persist token data.", error)
        }
    }

    private fun removeLegacyTokensAfterEncryptedRead() {
        val hasLegacyTokens = try {
            preferences.legacyAccessToken != null || preferences.legacyRefreshToken != null
        } catch (_: RuntimeException) {
            true
        }
        if (hasLegacyTokens && !clearLegacyTokensSafely()) {
            warn("Legacy token cleanup will be retried")
        }
    }

    private fun clearLegacyAfterWrite(): Boolean {
        val hasLegacyTokens = try {
            preferences.legacyAccessToken != null || preferences.legacyRefreshToken != null
        } catch (_: RuntimeException) {
            true
        }
        return !hasLegacyTokens || clearLegacyTokensSafely()
    }

    private fun clearEncryptedEnvelopeSafely(): Boolean {
        return try {
            preferences.clearEncryptedEnvelope()
        } catch (error: RuntimeException) {
            logVaultFailure("Could not clear encrypted token data", error)
            false
        }
    }

    private fun clearLegacyTokensSafely(): Boolean {
        return try {
            preferences.clearLegacyTokens()
        } catch (error: RuntimeException) {
            logVaultFailure("Could not clear legacy token data", error)
            false
        }
    }

    private fun resetCipherSafely(message: String): Boolean {
        return try {
            cipher.reset()
            true
        } catch (error: Exception) {
            logVaultFailure(message, error)
            false
        }
    }

    private fun notifyWidgets() {
        try {
            onTokensChanged()
        } catch (error: RuntimeException) {
            logVaultFailure("Could not request widget refresh", error)
        }
    }

    private fun logVaultFailure(message: String, error: Throwable) {
        warn("$message (${error.javaClass.simpleName})")
    }

    private fun warn(message: String) {
        onWarning(message)
    }

    private companion object {
        const val TAG = "TokenStore"
        val STORE_LOCK = Any()
    }
}
