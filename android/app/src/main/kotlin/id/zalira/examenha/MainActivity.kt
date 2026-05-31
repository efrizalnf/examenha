package id.zalira.examenha

import android.app.ActivityManager
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivity"
    }

    private val methodChannelName = "com.enha_exam/security"
    private val eventChannelName = "com.enha_exam/security_events"

    private var eventSink: EventChannel.EventSink? = null
    private var toneGenerator: ToneGenerator? = null
    private var isExamActive = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        toneGenerator = ToneGenerator(AudioManager.STREAM_ALARM, 80)

        // MethodChannel: Dart -> Native commands
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startExam" -> {
                        isExamActive = true
                        applySecurityFlags()
                        val isLockTaskActive = ensureLockTaskMode()
                        if (!isLockTaskActive) {
                            dispatchSecurityEvent("lockTaskUnavailable")
                        }
                        result.success(isLockTaskActive)
                    }
                    "stopExam" -> {
                        isExamActive = false
                        clearSecurityFlags()
                        releaseLockTaskMode()
                        result.success(null)
                    }
                    "beep" -> {
                        toneGenerator?.startTone(ToneGenerator.TONE_CDMA_PIP, 150)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // EventChannel: Native -> Dart events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        eventSink = events
                    }

                    override fun onCancel(arguments: Any?) {
                        eventSink = null
                    }
                },
            )
    }

    override fun onResume() {
        super.onResume()
        if (isExamActive && !ensureLockTaskMode()) {
            dispatchSecurityEvent("lockTaskUnavailable")
        }
    }

    // Fired when user presses Home or Recent Apps
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (isExamActive) {
            toneGenerator?.startTone(ToneGenerator.TONE_CDMA_PIP, 150)
            dispatchSecurityEvent("userLeaveHint")
        }
    }

    // Fired when notification panel is pulled down
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (isExamActive && !hasFocus) {
            dispatchSecurityEvent("windowFocusLost")
        } else if (isExamActive && hasFocus && !isLockTaskActive()) {
            ensureLockTaskMode()
        }
    }

    override fun onDestroy() {
        toneGenerator?.release()
        toneGenerator = null
        super.onDestroy()
    }

    private fun applySecurityFlags() {
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
    }

    private fun clearSecurityFlags() {
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    private fun ensureLockTaskMode(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            Log.w(TAG, "LockTask is not supported below API 21")
            return false
        }

        if (isLockTaskActive()) {
            return true
        }

        return try {
            startLockTask()
            isLockTaskActive()
        } catch (exception: IllegalArgumentException) {
            Log.w(TAG, "Failed to start LockTask", exception)
            false
        } catch (exception: IllegalStateException) {
            Log.w(TAG, "LockTask is not allowed on this device state", exception)
            false
        } catch (exception: SecurityException) {
            Log.w(TAG, "LockTask rejected by the system", exception)
            false
        }
    }

    private fun releaseLockTaskMode() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            return
        }

        if (!isLockTaskActive()) {
            return
        }

        try {
            stopLockTask()
        } catch (exception: IllegalArgumentException) {
            Log.w(TAG, "Failed to stop LockTask", exception)
        } catch (exception: IllegalStateException) {
            Log.w(TAG, "LockTask stop rejected by the system", exception)
        }
    }

    private fun isLockTaskActive(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            return false
        }

        val activityManager = getSystemService(ActivityManager::class.java) ?: return false
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            activityManager.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
        } else {
            @Suppress("DEPRECATION")
            activityManager.isInLockTaskMode
        }
    }

    private fun dispatchSecurityEvent(event: String) {
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(event)
        }
    }
}
