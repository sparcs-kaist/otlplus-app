package org.sparcs.otlplus.api

import android.content.Context
import android.util.Base64
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import java.security.KeyStore
import java.util.UUID
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class TokenStoreInstrumentedTest {
    private lateinit var context: Context
    private lateinit var keyAlias: String
    private lateinit var preferences: AndroidTokenPreferences
    private lateinit var cipher: AndroidKeystoreTokenCipher
    private lateinit var store: TokenStore

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        context.getSharedPreferences(VAULT_PREFERENCES, Context.MODE_PRIVATE).edit().clear().commit()
        context.getSharedPreferences(LEGACY_PREFERENCES, Context.MODE_PRIVATE).edit().clear().commit()
        keyAlias = "org.sparcs.otlplus.token_vault.test.${UUID.randomUUID()}"
        cipher = AndroidKeystoreTokenCipher(keyAlias)
        cipher.reset()
        preferences = AndroidTokenPreferences(context)
        store = TokenStore(preferences, cipher) {}
    }

    @After
    fun tearDown() {
        context.getSharedPreferences(VAULT_PREFERENCES, Context.MODE_PRIVATE).edit().clear().commit()
        context.getSharedPreferences(LEGACY_PREFERENCES, Context.MODE_PRIVATE).edit().clear().commit()
        cipher.reset()
    }

    @Test
    fun writeUsesAndroidKeystoreAndStoresOnlyOneEncryptedEnvelope() {
        store.updateTokens("instrumented-access", "instrumented-refresh")

        val vaultPreferences = context.getSharedPreferences(VAULT_PREFERENCES, Context.MODE_PRIVATE)
        assertEquals(setOf(ENCRYPTED_PAIR_KEY), vaultPreferences.all.keys)
        val envelope = requireNotNull(vaultPreferences.getString(ENCRYPTED_PAIR_KEY, null))
        assertFalse(envelope.contains("instrumented-access"))
        assertFalse(envelope.contains("instrumented-refresh"))

        val envelopeJson = JSONObject(envelope)
        assertEquals(1, envelopeJson.getInt("version"))
        assertEquals("AES-256-GCM", envelopeJson.getString("algorithm"))
        assertTrue(envelopeJson.getString("iv").isNotEmpty())
        assertTrue(envelopeJson.getString("ciphertext").isNotEmpty())
        assertTrue(loadKeyStore().containsAlias(keyAlias))
        assertEquals(TokenPair("instrumented-access", "instrumented-refresh"), store.readTokenPair())
    }

    @Test
    fun readMigratesPlaintextWidgetKeysAndRemovesThem() {
        context.getSharedPreferences(LEGACY_PREFERENCES, Context.MODE_PRIVATE).edit()
            .putString(LEGACY_ACCESS_TOKEN_KEY, "legacy-access")
            .putString(LEGACY_REFRESH_TOKEN_KEY, "legacy-refresh")
            .commit()

        assertEquals(TokenPair("legacy-access", "legacy-refresh"), store.readTokenPair())

        val legacyPreferences = context.getSharedPreferences(LEGACY_PREFERENCES, Context.MODE_PRIVATE)
        assertFalse(legacyPreferences.contains(LEGACY_ACCESS_TOKEN_KEY))
        assertFalse(legacyPreferences.contains(LEGACY_REFRESH_TOKEN_KEY))
        assertTrue(context.getSharedPreferences(VAULT_PREFERENCES, Context.MODE_PRIVATE)
            .contains(ENCRYPTED_PAIR_KEY))
    }

    @Test
    fun tamperedCiphertextLogsOutWithoutCrashing() {
        store.updateTokens("access", "refresh")
        val vaultPreferences = context.getSharedPreferences(VAULT_PREFERENCES, Context.MODE_PRIVATE)
        val envelope = JSONObject(requireNotNull(vaultPreferences.getString(ENCRYPTED_PAIR_KEY, null)))
        val ciphertext = Base64.decode(envelope.getString("ciphertext"), Base64.DEFAULT)
        ciphertext[ciphertext.lastIndex] = (ciphertext.last().toInt() xor 1).toByte()
        envelope.put("ciphertext", Base64.encodeToString(ciphertext, Base64.NO_WRAP))
        vaultPreferences.edit().putString(ENCRYPTED_PAIR_KEY, envelope.toString()).commit()

        assertNull(store.readTokenPair())
        assertFalse(vaultPreferences.contains(ENCRYPTED_PAIR_KEY))
        assertFalse(loadKeyStore().containsAlias(keyAlias))
    }

    @Test
    fun corruptVaultLogsOutAndDoesNotFallBackToPlaintext() {
        context.getSharedPreferences(VAULT_PREFERENCES, Context.MODE_PRIVATE).edit()
            .putString(ENCRYPTED_PAIR_KEY, "not-json")
            .commit()
        context.getSharedPreferences(LEGACY_PREFERENCES, Context.MODE_PRIVATE).edit()
            .putString(LEGACY_ACCESS_TOKEN_KEY, "legacy-access")
            .putString(LEGACY_REFRESH_TOKEN_KEY, "legacy-refresh")
            .commit()

        assertNull(store.readTokenPair())

        assertFalse(context.getSharedPreferences(VAULT_PREFERENCES, Context.MODE_PRIVATE)
            .contains(ENCRYPTED_PAIR_KEY))
        val legacyPreferences = context.getSharedPreferences(LEGACY_PREFERENCES, Context.MODE_PRIVATE)
        assertFalse(legacyPreferences.contains(LEGACY_ACCESS_TOKEN_KEY))
        assertFalse(legacyPreferences.contains(LEGACY_REFRESH_TOKEN_KEY))
        assertFalse(loadKeyStore().containsAlias(keyAlias))
    }

    private fun loadKeyStore(): KeyStore {
        return KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
    }

    private companion object {
        const val VAULT_PREFERENCES = "TokenVault"
        const val ENCRYPTED_PAIR_KEY = "encrypted_token_pair"
        const val LEGACY_PREFERENCES = "FlutterSharedPreferences"
        const val LEGACY_ACCESS_TOKEN_KEY = "flutter.access_token"
        const val LEGACY_REFRESH_TOKEN_KEY = "flutter.refresh_token"
    }
}
