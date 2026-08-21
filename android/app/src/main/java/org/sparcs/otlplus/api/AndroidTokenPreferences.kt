package org.sparcs.otlplus.api

import android.content.Context

internal class AndroidTokenPreferences(context: Context) : TokenPreferences {
    private val vaultPreferences = context.getSharedPreferences(VAULT_PREFERENCES, Context.MODE_PRIVATE)
    private val legacyPreferences = context.getSharedPreferences(LEGACY_PREFERENCES, Context.MODE_PRIVATE)

    override val encryptedEnvelope: String?
        get() = vaultPreferences.getString(ENCRYPTED_PAIR_KEY, null)

    override val legacyAccessToken: String?
        get() = legacyPreferences.getString(LEGACY_ACCESS_TOKEN_KEY, null)

    override val legacyRefreshToken: String?
        get() = legacyPreferences.getString(LEGACY_REFRESH_TOKEN_KEY, null)

    override fun writeEncryptedEnvelope(value: String): Boolean {
        return vaultPreferences.edit().putString(ENCRYPTED_PAIR_KEY, value).commit()
    }

    override fun clearEncryptedEnvelope(): Boolean {
        return vaultPreferences.edit().remove(ENCRYPTED_PAIR_KEY).commit()
    }

    override fun clearLegacyTokens(): Boolean {
        return legacyPreferences.edit()
            .remove(LEGACY_ACCESS_TOKEN_KEY)
            .remove(LEGACY_REFRESH_TOKEN_KEY)
            .commit()
    }

    private companion object {
        const val VAULT_PREFERENCES = "TokenVault"
        const val ENCRYPTED_PAIR_KEY = "encrypted_token_pair"
        const val LEGACY_PREFERENCES = "FlutterSharedPreferences"
        const val LEGACY_ACCESS_TOKEN_KEY = "flutter.access_token"
        const val LEGACY_REFRESH_TOKEN_KEY = "flutter.refresh_token"
    }
}
