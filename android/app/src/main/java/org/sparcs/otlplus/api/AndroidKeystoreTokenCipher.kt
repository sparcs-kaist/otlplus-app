package org.sparcs.otlplus.api

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import java.security.KeyStore
import java.security.UnrecoverableKeyException
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

internal class AndroidKeystoreTokenCipher(
    private val keyAlias: String = DEFAULT_KEY_ALIAS,
) : TokenCipher {
    override fun encrypt(plaintext: ByteArray): EncryptedTokenPayload = synchronized(KEYSTORE_LOCK) {
        try {
            encryptWithKey(plaintext, getOrCreateKey())
        } catch (error: KeyPermanentlyInvalidatedException) {
            resetLocked()
            encryptWithKey(plaintext, getOrCreateKey())
        } catch (error: UnrecoverableKeyException) {
            resetLocked()
            encryptWithKey(plaintext, getOrCreateKey())
        }
    }

    override fun decrypt(payload: EncryptedTokenPayload): ByteArray = synchronized(KEYSTORE_LOCK) {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(
            Cipher.DECRYPT_MODE,
            loadExistingKey(),
            GCMParameterSpec(GCM_TAG_BITS, payload.iv),
        )
        cipher.doFinal(payload.ciphertext)
    }

    override fun reset() = synchronized(KEYSTORE_LOCK) {
        resetLocked()
    }

    private fun encryptWithKey(plaintext: ByteArray, key: SecretKey): EncryptedTokenPayload {
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, key)
        return EncryptedTokenPayload(
            iv = cipher.iv,
            ciphertext = cipher.doFinal(plaintext),
        )
    }

    private fun getOrCreateKey(): SecretKey {
        val keyStore = loadKeyStore()
        if (keyStore.containsAlias(keyAlias)) {
            return loadKey(keyStore)
        }

        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            ANDROID_KEY_STORE,
        )
        keyGenerator.init(
            KeyGenParameterSpec.Builder(
                keyAlias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setKeySize(KEY_SIZE_BITS)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true)
                .build(),
        )
        return keyGenerator.generateKey()
    }

    private fun loadExistingKey(): SecretKey {
        val keyStore = loadKeyStore()
        if (!keyStore.containsAlias(keyAlias)) {
            throw UnrecoverableKeyException("Token vault key is unavailable.")
        }
        return loadKey(keyStore)
    }

    private fun loadKey(keyStore: KeyStore): SecretKey {
        return keyStore.getKey(keyAlias, null) as? SecretKey
            ?: throw UnrecoverableKeyException("Token vault key is unavailable.")
    }

    private fun resetLocked() {
        val keyStore = loadKeyStore()
        if (keyStore.containsAlias(keyAlias)) {
            keyStore.deleteEntry(keyAlias)
        }
    }

    private fun loadKeyStore(): KeyStore {
        return KeyStore.getInstance(ANDROID_KEY_STORE).apply { load(null) }
    }

    private companion object {
        const val ANDROID_KEY_STORE = "AndroidKeyStore"
        const val DEFAULT_KEY_ALIAS = "org.sparcs.otlplus.token_vault.aes_gcm.v1"
        const val TRANSFORMATION = "AES/GCM/NoPadding"
        const val KEY_SIZE_BITS = 256
        const val GCM_TAG_BITS = 128
        val KEYSTORE_LOCK = Any()
    }
}
