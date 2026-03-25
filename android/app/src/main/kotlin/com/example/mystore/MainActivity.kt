package com.example.mystore

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    /**
     * Intercept the hardware back button at the Activity level.
     *
     * On Android TV the remote's back button generates both a KeyEvent
     * AND a call to onBackPressed(). If we don't consume the KeyEvent
     * here, Android treats it as "unhandled" and calls onBackPressed()
     * a second time — causing the app to exit instead of just going
     * back one screen.
     */
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            // Forward the event to Flutter so our Dart onKeyEvent fires
            super.onKeyDown(keyCode, event)
            // Return true = "consumed". This stops Android from ALSO
            // calling onBackPressed(), which would be a second back.
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            // Consume the KeyUp as well so the OS never sees it.
            return true
        }
        return super.onKeyUp(keyCode, event)
    }

    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        // Do nothing. Flutter handles all back navigation via onKeyEvent.
        // This is the last line of defence against the OS finishing
        // the Activity on a back press.
    }
}
