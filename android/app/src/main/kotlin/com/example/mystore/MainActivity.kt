package com.example.mystore

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.vargastv/external_player"

    // MX Player package names
    private val MX_PLAYER_FREE = "com.mxtech.videoplayer.ad"
    private val MX_PLAYER_PRO = "com.mxtech.videoplayer.pro"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isMxPlayerInstalled" -> {
                        val installed = isAppInstalled(MX_PLAYER_PRO) || isAppInstalled(MX_PLAYER_FREE)
                        result.success(installed)
                    }
                    "launchMxPlayer" -> {
                        val url = call.argument<String>("url")
                        val title = call.argument<String>("title")
                        if (url == null) {
                            result.error("NO_URL", "Stream URL is required", null)
                            return@setMethodCallHandler
                        }
                        val launched = launchMxPlayer(url, title ?: "")
                        if (launched) {
                            result.success(true)
                        } else {
                            result.error("LAUNCH_FAILED", "Failed to launch MX Player", null)
                        }
                    }
                    "openMxPlayerStore" -> {
                        openPlayStore(MX_PLAYER_FREE)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isAppInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun launchMxPlayer(url: String, title: String): Boolean {
        // Prefer Pro version, fall back to free
        val packageName = when {
            isAppInstalled(MX_PLAYER_PRO) -> MX_PLAYER_PRO
            isAppInstalled(MX_PLAYER_FREE) -> MX_PLAYER_FREE
            else -> return false
        }

        return try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(Uri.parse(url), "video/*")
                setPackage(packageName)
                putExtra("title", title)
                // MX Player specific extras for better streaming experience
                putExtra("decode_mode", 1) // HW decoder
                putExtra("subs", arrayOf<Uri>())
                putExtra("subs.enable", arrayOf<Uri>())
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun openPlayStore(packageName: String) {
        try {
            // Try Google Play Store app first
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$packageName"))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            // Fall back to browser
            val intent = Intent(
                Intent.ACTION_VIEW,
                Uri.parse("https://play.google.com/store/apps/details?id=$packageName")
            )
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
    }
}
