package com.example.vault_flow

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// local_auth needs a FragmentActivity to host the BiometricPrompt.
class MainActivity : FlutterFragmentActivity() {
    private var channel: MethodChannel? = null

    // Files shared into the app before Dart asked for them.
    private val pending = mutableListOf<Map<String, String>>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    // Dart calls this once at start-up to drain what was
                    // shared while the app was not running.
                    "takePending" -> {
                        result.success(pending.toList())
                        pending.clear()
                    }
                    else -> result.notImplemented()
                }
            }
        }
        handleShare(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleShare(intent)
    }

    /// ACTION_SEND / ACTION_SEND_MULTIPLE: copy each content URI into the
    /// app cache (the URI grant is temporary) and hand paths to Dart.
    private fun handleShare(intent: Intent?) {
        if (intent == null) return
        val uris: List<Uri> = when (intent.action) {
            Intent.ACTION_SEND ->
                listOfNotNull(intent.getParcelableExtra(Intent.EXTRA_STREAM))
            Intent.ACTION_SEND_MULTIPLE ->
                intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM) ?: emptyList()
            else -> emptyList()
        }
        if (uris.isEmpty()) return
        val dir = File(cacheDir, "shared").apply { mkdirs() }
        val files = uris.mapNotNull { uri ->
            val name = displayName(uri) ?: "shared-${System.currentTimeMillis()}"
            val target = File(dir, "${System.nanoTime()}-$name")
            try {
                contentResolver.openInputStream(uri)?.use { input ->
                    target.outputStream().use { output -> input.copyTo(output) }
                } ?: return@mapNotNull null
                mapOf("name" to name, "path" to target.absolutePath)
            } catch (e: Exception) {
                null
            }
        }
        if (files.isEmpty()) return
        // Consume the intent so a configuration change does not re-import.
        intent.removeExtra(Intent.EXTRA_STREAM)
        val ch = channel
        if (ch == null) pending.addAll(files) else ch.invokeMethod("shared", files)
    }

    private fun displayName(uri: Uri): String? {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
            if (it.moveToFirst()) {
                val idx = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (idx >= 0) return it.getString(idx)
            }
        }
        return uri.lastPathSegment
    }

    companion object {
        const val CHANNEL = "dev.vaultflow/share"
    }
}
