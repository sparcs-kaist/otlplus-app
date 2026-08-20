package org.sparcs.otlplus.api

import java.security.GeneralSecurityException
import java.security.ProviderException
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.assertThrows
import org.junit.Test

class TokenStoreTest {
    @Test
    fun `write stores one encrypted pair and notifies widgets`() {
        val preferences = FakeTokenPreferences()
        val cipher = FakeTokenCipher()
        var refreshCount = 0
        val store = TokenStore(preferences, cipher) { refreshCount += 1 }

        store.updateTokens("new-access", "new-refresh")

        val storedEnvelope = requireNotNull(preferences.encryptedEnvelope)
        assertFalse(storedEnvelope.contains("new-access"))
        assertFalse(storedEnvelope.contains("new-refresh"))
        assertEquals(TokenPair("new-access", "new-refresh"), store.readTokenPair())
        assertEquals(1, refreshCount)
    }

    @Test
    fun `read migrates the complete plaintext pair before deleting legacy keys`() {
        val preferences = FakeTokenPreferences(
            legacyAccessToken = "legacy-access",
            legacyRefreshToken = "legacy-refresh",
        )
        val store = TokenStore(preferences, FakeTokenCipher()) {}

        val migrated = store.readTokenPair()

        assertEquals(TokenPair("legacy-access", "legacy-refresh"), migrated)
        assertNull(preferences.legacyAccessToken)
        assertNull(preferences.legacyRefreshToken)
        assertTrue(preferences.operations.indexOf("writeVault") < preferences.operations.indexOf("clearLegacy"))

        preferences.legacyAccessToken = "stale-access"
        preferences.legacyRefreshToken = "stale-refresh"
        assertEquals(TokenPair("legacy-access", "legacy-refresh"), store.readTokenPair())
    }

    @Test
    fun `read removes an incomplete plaintext pair without migrating it`() {
        val preferences = FakeTokenPreferences(
            legacyAccessToken = "legacy-access",
            legacyRefreshToken = null,
        )
        val store = TokenStore(preferences, FakeTokenCipher()) {}

        assertNull(store.readTokenPair())
        assertNull(preferences.legacyAccessToken)
        assertNull(preferences.legacyRefreshToken)
        assertNull(preferences.encryptedEnvelope)
    }

    @Test
    fun `corrupt encrypted vault logs out and never falls back to plaintext`() {
        val preferences = FakeTokenPreferences(
            encryptedEnvelope = "not-json",
            legacyAccessToken = "legacy-access",
            legacyRefreshToken = "legacy-refresh",
        )
        val cipher = FakeTokenCipher()
        var refreshCount = 0
        val store = TokenStore(preferences, cipher) { refreshCount += 1 }

        assertNull(store.readTokenPair())
        assertNull(preferences.encryptedEnvelope)
        assertNull(preferences.legacyAccessToken)
        assertNull(preferences.legacyRefreshToken)
        assertEquals(1, cipher.resetCount)
        assertEquals(1, refreshCount)
    }

    @Test
    fun `authenticated decryption failure logs out without crashing`() {
        val preferences = FakeTokenPreferences()
        val writerCipher = FakeTokenCipher()
        TokenStore(preferences, writerCipher) {}.updateTokens("access", "refresh")
        val invalidatedCipher = FakeTokenCipher(failDecryption = true)
        val store = TokenStore(preferences, invalidatedCipher) {}

        assertNull(store.readTokenPair())
        assertNull(preferences.encryptedEnvelope)
        assertEquals(1, invalidatedCipher.resetCount)
    }

    @Test
    fun `transient provider failure preserves the encrypted vault`() {
        val preferences = FakeTokenPreferences()
        TokenStore(preferences, FakeTokenCipher()) {}.updateTokens("access", "refresh")
        val providerFailureCipher = FakeTokenCipher(failWithProviderException = true)
        val store = TokenStore(preferences, providerFailureCipher) {}

        assertThrows(TokenVaultException::class.java) {
            store.readTokenPair()
        }
        assertTrue(preferences.encryptedEnvelope != null)
        assertEquals(0, providerFailureCipher.resetCount)
    }

    @Test
    fun `failed atomic rotation preserves the previous encrypted pair`() {
        val preferences = FakeTokenPreferences()
        val cipher = FakeTokenCipher()
        var refreshCount = 0
        val store = TokenStore(preferences, cipher) { refreshCount += 1 }
        store.updateTokens("old-access", "old-refresh")
        refreshCount = 0
        preferences.failVaultWrites = true

        assertThrows(TokenVaultException::class.java) {
            store.updateTokens("new-access", "new-refresh")
        }

        preferences.failVaultWrites = false
        assertEquals(TokenPair("old-access", "old-refresh"), store.readTokenPair())
        assertEquals(0, refreshCount)
    }

    @Test
    fun `legacy cleanup failure keeps the encrypted rotation and retries cleanup on read`() {
        val preferences = FakeTokenPreferences(
            legacyAccessToken = "legacy-access",
            legacyRefreshToken = "legacy-refresh",
            failLegacyClears = true,
        )
        val store = TokenStore(preferences, FakeTokenCipher()) {}

        assertThrows(TokenVaultException::class.java) {
            store.updateTokens("new-access", "new-refresh")
        }
        assertTrue(preferences.encryptedEnvelope != null)
        assertEquals("legacy-access", preferences.legacyAccessToken)
        assertEquals("legacy-refresh", preferences.legacyRefreshToken)

        preferences.failLegacyClears = false
        assertEquals(TokenPair("new-access", "new-refresh"), store.readTokenPair())
        assertNull(preferences.legacyAccessToken)
        assertNull(preferences.legacyRefreshToken)
    }

    @Test
    fun `failed migration keeps plaintext for a later retry but does not use it`() {
        val preferences = FakeTokenPreferences(
            legacyAccessToken = "legacy-access",
            legacyRefreshToken = "legacy-refresh",
            failVaultWrites = true,
        )
        val store = TokenStore(preferences, FakeTokenCipher()) {}

        assertNull(store.readTokenPair())
        assertEquals("legacy-access", preferences.legacyAccessToken)
        assertEquals("legacy-refresh", preferences.legacyRefreshToken)
        assertNull(preferences.encryptedEnvelope)
    }

    @Test
    fun `stale refresh cannot overwrite or clear a newer token pair`() {
        val preferences = FakeTokenPreferences()
        val store = TokenStore(preferences, FakeTokenCipher()) {}
        store.updateTokens("new-access", "new-refresh")

        assertFalse(
            store.updateTokensIfRefreshTokenMatches(
                expectedRefreshToken = "old-refresh",
                newAccessToken = "stale-access",
                newRefreshToken = "stale-refresh",
            ),
        )
        assertFalse(store.clearTokensIfRefreshTokenMatches("old-refresh"))
        assertEquals(TokenPair("new-access", "new-refresh"), store.readTokenPair())
    }

    @Test
    fun `matching refresh token conditionally rotates and clears the pair`() {
        val preferences = FakeTokenPreferences()
        val store = TokenStore(preferences, FakeTokenCipher()) {}
        store.updateTokens("old-access", "old-refresh")

        assertTrue(
            store.updateTokensIfRefreshTokenMatches(
                expectedRefreshToken = "old-refresh",
                newAccessToken = "new-access",
                newRefreshToken = "new-refresh",
            ),
        )
        assertEquals(TokenPair("new-access", "new-refresh"), store.readTokenPair())
        assertTrue(store.clearTokensIfRefreshTokenMatches("new-refresh"))
        assertNull(store.readTokenPair())
    }

    @Test
    fun `clear removes encrypted and plaintext data and notifies widgets`() {
        val preferences = FakeTokenPreferences(
            legacyAccessToken = "legacy-access",
            legacyRefreshToken = "legacy-refresh",
        )
        val cipher = FakeTokenCipher()
        var refreshCount = 0
        val store = TokenStore(preferences, cipher) { refreshCount += 1 }
        store.updateTokens("access", "refresh")
        refreshCount = 0

        store.clearTokens()

        assertNull(preferences.encryptedEnvelope)
        assertNull(preferences.legacyAccessToken)
        assertNull(preferences.legacyRefreshToken)
        assertEquals(1, cipher.resetCount)
        assertEquals(1, refreshCount)
    }
}

private class FakeTokenPreferences(
    override var encryptedEnvelope: String? = null,
    override var legacyAccessToken: String? = null,
    override var legacyRefreshToken: String? = null,
    var failVaultWrites: Boolean = false,
    var failLegacyClears: Boolean = false,
) : TokenPreferences {
    val operations = mutableListOf<String>()

    override fun writeEncryptedEnvelope(value: String): Boolean {
        operations += "writeVault"
        if (failVaultWrites) return false
        encryptedEnvelope = value
        return true
    }

    override fun clearEncryptedEnvelope(): Boolean {
        operations += "clearVault"
        encryptedEnvelope = null
        return true
    }

    override fun clearLegacyTokens(): Boolean {
        operations += "clearLegacy"
        if (failLegacyClears) return false
        legacyAccessToken = null
        legacyRefreshToken = null
        return true
    }
}

private class FakeTokenCipher(
    private val failDecryption: Boolean = false,
    private val failWithProviderException: Boolean = false,
) : TokenCipher {
    var resetCount = 0

    override fun encrypt(plaintext: ByteArray): EncryptedTokenPayload {
        return EncryptedTokenPayload(
            iv = byteArrayOf(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12),
            ciphertext = plaintext.map { (it.toInt() xor 0x5a).toByte() }.toByteArray(),
        )
    }

    override fun decrypt(payload: EncryptedTokenPayload): ByteArray {
        if (failWithProviderException) throw ProviderException("temporarily unavailable")
        if (failDecryption) throw GeneralSecurityException("invalidated")
        return payload.ciphertext.map { (it.toInt() xor 0x5a).toByte() }.toByteArray()
    }

    override fun reset() {
        resetCount += 1
    }
}
