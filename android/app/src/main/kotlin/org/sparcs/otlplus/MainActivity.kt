package org.sparcs.otlplus

import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors
import org.sparcs.otlplus.api.TokenRefreshLease
import org.sparcs.otlplus.api.TokenStore

class MainActivity : FlutterActivity() {
    private val channel = "org.sparcs.otlplus"
    private val tokenVaultChannel = "org.sparcs.otlplus/token_vault"

    private val mainHandler = Handler(Looper.getMainLooper())
    private val refreshLeaseOwnerId = UUID.randomUUID().toString()
    private val tokenVaultExecutor = Executors.newSingleThreadExecutor()
    private val tokenStore by lazy { TokenStore(applicationContext) }
    private lateinit var preferenceUpdateListener: SharedPreferenceUpdateListener

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        preferenceUpdateListener = SharedPreferenceUpdateListener(this)
        preferenceUpdateListener.register()
    }

    override fun onDestroy() {
        preferenceUpdateListener.unregister()
        tokenVaultExecutor.shutdownNow()
        TokenRefreshLease.releaseOwnedBy(refreshLeaseOwnerId)

        super.onDestroy()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler {
            call, result ->
            if (call.method == "writeImageAsBytes") {
                val fileName = call.argument<String>("fileName")
                val bytes = call.argument<ByteArray>("bytes")
                if (fileName != null && bytes != null) {
                    val path = writeImageAsBytes(fileName, bytes)
                    if (path != null) {
                        result.success(path)
                    } else {
                        result.error("ERROR", "Cannot write image bytes.", null)
                    }
                } else {
                    result.error("ERROR", "Invalid paramters.", null)
                }
            } else if (call.method == "getAndroidVersion") {
                result.success(Build.VERSION.SDK_INT)
            } else if (call.method == "startInlineInstall") {
                val targetPackage = call.argument<String>("packageName")
                val referrer = call.argument<String>("referrer")
                val listing = call.argument<String>("listing")
                if (targetPackage.isNullOrEmpty()) {
                    result.error(
                        "INVALID_ARGUMENTS",
                        "Target package name is required.",
                        null,
                    )
                } else {
                    result.success(startInlineInstall(targetPackage, referrer, listing))
                }
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            tokenVaultChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "readTokenPair" -> runTokenVaultOperation(result) {
                    tokenStore.readTokenPair()?.let { pair ->
                        mapOf(
                            "accessToken" to pair.accessToken,
                            "refreshToken" to pair.refreshToken,
                        )
                    }
                }
                "writeTokenPair" -> {
                    val accessToken = call.argument<String>("accessToken")
                    val refreshToken = call.argument<String>("refreshToken")
                    if (accessToken.isNullOrEmpty() || refreshToken.isNullOrEmpty()) {
                        result.error(
                            "INVALID_ARGUMENTS",
                            "Access and refresh tokens must both be non-empty.",
                            null,
                        )
                    } else {
                        runTokenVaultOperation(result) {
                            tokenStore.updateTokens(accessToken, refreshToken)
                            null
                        }
                    }
                }
                "writeTokenPairIfRefreshTokenMatches" -> {
                    val expectedRefreshToken = call.argument<String>(
                        "expectedRefreshToken",
                    )
                    val accessToken = call.argument<String>("accessToken")
                    val refreshToken = call.argument<String>("refreshToken")
                    if (
                        expectedRefreshToken.isNullOrEmpty() ||
                        accessToken.isNullOrEmpty() ||
                        refreshToken.isNullOrEmpty()
                    ) {
                        result.error(
                            "INVALID_ARGUMENTS",
                            "Expected, access, and refresh tokens must be non-empty.",
                            null,
                        )
                    } else {
                        runTokenVaultOperation(result) {
                            tokenStore.updateTokensIfRefreshTokenMatches(
                                expectedRefreshToken,
                                accessToken,
                                refreshToken,
                            )
                        }
                    }
                }
                "clearTokenPair" -> runTokenVaultOperation(result) {
                    tokenStore.clearTokens()
                    null
                }
                "clearTokenPairIfRefreshTokenMatches" -> {
                    val expectedRefreshToken = call.argument<String>(
                        "expectedRefreshToken",
                    )
                    if (expectedRefreshToken.isNullOrEmpty()) {
                        result.error(
                            "INVALID_ARGUMENTS",
                            "Expected refresh token must be non-empty.",
                            null,
                        )
                    } else {
                        runTokenVaultOperation(result) {
                            tokenStore.clearTokensIfRefreshTokenMatches(
                                expectedRefreshToken,
                            )
                        }
                    }
                }
                "acquireRefreshLease" -> runTokenVaultOperation(result) {
                    TokenRefreshLease.acquire(refreshLeaseOwnerId)
                }
                "releaseRefreshLease" -> {
                    val leaseId = call.argument<String>("leaseId")
                    if (leaseId.isNullOrEmpty()) {
                        result.error(
                            "INVALID_ARGUMENTS",
                            "Lease ID must be non-empty.",
                            null,
                        )
                    } else {
                        runTokenVaultOperation(result) {
                            TokenRefreshLease.release(leaseId)
                            null
                        }
                    }
                }
                "syncTokenReplicas" -> runTokenVaultOperation(result) {
                    WidgetRefreshDispatcher.refresh(applicationContext)
                    null
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun runTokenVaultOperation(
        result: MethodChannel.Result,
        operation: () -> Any?,
    ) {
        tokenVaultExecutor.execute {
            try {
                val value = operation()
                mainHandler.post { result.success(value) }
            } catch (_: Exception) {
                mainHandler.post {
                    result.error(
                        "TOKEN_VAULT_ERROR",
                        "Token vault operation failed.",
                        null,
                    )
                }
            }
        }
    }


    /// Opens the Google Play inline-install half sheet for [targetPackage],
    /// per https://developer.android.com/distribute/marketing-tools/inline-installs.
    /// Returns true when the overlay intent resolved; false tells Dart to
    /// fall back to the regular Play Store listing.
    private fun startInlineInstall(
        targetPackage: String,
        referrer: String?,
        listing: String?,
    ): Boolean {
        val deepLinkUrl = buildString {
            append("https://play.google.com/d?id=")
            append(targetPackage)
            if (!referrer.isNullOrEmpty()) {
                append("&referrer=")
                append(referrer)
            }
            if (!listing.isNullOrEmpty()) {
                append("&listing=")
                append(listing)
            }
        }
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setPackage("com.android.vending")
            data = Uri.parse(deepLinkUrl)
            putExtra("overlay", true)
            putExtra("callerId", packageName)
        }
        if (intent.resolveActivity(packageManager) != null) {
            startActivity(intent)
            return true
        }
        return false
    }

    private fun writeImageAsBytes(fileName: String, bytes: ByteArray): String? {
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            values.put(MediaStore.Images.Media.IS_PENDING, 1)
        }

        val contentResolver = contentResolver
        val item = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)!!

        try {
            val pdf = contentResolver.openFileDescriptor(item, "w", null)
            if (pdf != null) {
                val fos = FileOutputStream(pdf.fileDescriptor)
                fos.write(bytes)
                fos.close()

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    values.clear()
                    values.put(MediaStore.Images.Media.IS_PENDING, 0)
                    contentResolver.update(item, values, null, null)
                }

                val intent = Intent(Intent.ACTION_VIEW)
                intent.setDataAndType(item, "image/png")
                startActivity(intent)
                return item.path
            }
        } catch (e: FileNotFoundException) {
            e.printStackTrace()
        } catch (e: IOException) {
            e.printStackTrace()
        }
        return null
    }
}
