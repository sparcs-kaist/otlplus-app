package org.sparcs.otlplus

import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val CHANNEL = "org.sparcs.otlplus"

    private lateinit var preferenceUpdateListener: SharedPreferenceUpdateListener

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        preferenceUpdateListener = SharedPreferenceUpdateListener(this)
        preferenceUpdateListener.register()
    }

    override fun onDestroy() {
        preferenceUpdateListener.unregister()

        super.onDestroy()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
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
            } else {
                result.notImplemented()
            }
        }
    }

    private fun writeImageAsBytes(fileName: String, bytes: ByteArray): String? {
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            values.put(MediaStore.Images.Media.IS_PENDING, 1)
        }

        val contentResolver = getContentResolver()
        val item = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)!!
        
        try {
            val pdf = contentResolver.openFileDescriptor(item, "w", null)
            if (pdf != null) {
                val fos = FileOutputStream(pdf.getFileDescriptor())
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
