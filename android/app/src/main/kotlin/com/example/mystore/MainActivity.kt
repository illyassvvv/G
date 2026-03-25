package com.example.mystore

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    /**
     * Intercept the hardware back button at the Activity level.
     * Flutter's key event handler will process it; we prevent the
     * default Android behaviour (finishing the Activity) so the
     * back press is never counted twice.
     */
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            // Let Flutter handle it via its own key-event pipeline.
            // Returning false here would let the OS also process it,
            // causing a double-back / app-exit.
            return super.onKeyDown(keyCode, event)
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            // Consume the KeyUp so the OS doesn't treat this as a
            // second back press.
            return true
        }
        return super.onKeyUp(keyCode, event)
    }

    override fun onBackPressed() {
        // Do nothing — Flutter's onKeyEvent handles navigation.
        // This prevents the Activity from being finished by the OS.
    }
}
