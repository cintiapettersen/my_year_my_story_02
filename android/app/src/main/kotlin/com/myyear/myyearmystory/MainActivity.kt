package com.myyear.myyearmystory

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Align behavior across Android versions: allow the app to draw edge-to-edge
        // and let Flutter handle insets via MediaQuery/SafeArea.
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
