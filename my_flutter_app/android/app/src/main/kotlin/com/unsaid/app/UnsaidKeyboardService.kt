package com.unsaid.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.inputmethodservice.InputMethodService
import android.text.TextUtils
import android.util.Log
import android.view.KeyEvent
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import org.json.JSONObject

class UnsaidKeyboardService : InputMethodService() {
    
    private val TAG = "UnsaidKeyboardService"
    private lateinit var keyboardView: View
    private lateinit var toneIndicator: TextView
    private lateinit var currentToneView: View
    private var currentTone: String = "balanced"
    
    private val toneAnalysisReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.unsaid.keyboard.TONE_ANALYSIS") {
                val text = intent.getStringExtra("text") ?: ""
                val analysisString = intent.getStringExtra("analysis") ?: ""
                try {
                    val analysis = JSONObject(analysisString)
                    updateToneDisplay(analysis)
                } catch (e: Exception) {
                    Log.e(TAG, "Error parsing tone analysis", e)
                }
            }
        }
    }
    
    override fun onCreateInputView(): View {
        keyboardView = createKeyboardLayout()
        registerToneAnalysisReceiver()
        return keyboardView
    }
    
    private fun createKeyboardLayout(): View {
        val mainLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#1E1E1E"))
            setPadding(16, 16, 16, 16)
        }
        
        // Tone indicator row
        val toneRow = createToneIndicatorRow()
        mainLayout.addView(toneRow)
        
        // Main keyboard rows
        val keyboardRows = createKeyboardRows()
        keyboardRows.forEach { row ->
            mainLayout.addView(row)
        }
        
        return mainLayout
    }
    
    private fun createToneIndicatorRow(): View {
        val toneLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, 0, 0, 16)
        }
        
        // Unsaid logo/brand
        val logoView = ImageView(this).apply {
            setImageResource(R.drawable.logo_icon) // Assuming you have this in drawable
            layoutParams = LinearLayout.LayoutParams(48, 48).apply {
                marginEnd = 16
            }
        }
        toneLayout.addView(logoView)
        
        // Current tone indicator
        currentToneView = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(12, 12).apply {
                setMargins(0, 18, 8, 0)
            }
            setBackgroundResource(R.drawable.tone_circle)
        }
        toneLayout.addView(currentToneView)
        
        // Tone text
        toneIndicator = TextView(this).apply {
            text = "Balanced tone"
            textSize = 14f
            setTextColor(Color.WHITE)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = android.view.Gravity.CENTER_VERTICAL
            }
        }
        toneLayout.addView(toneIndicator)
        
        return toneLayout
    }
    
    private fun createKeyboardRows(): List<View> {
        val rows = mutableListOf<View>()
        
        // Row 1: QWERTYUIOP
        val row1Keys = listOf("Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P")
        rows.add(createKeyRow(row1Keys))
        
        // Row 2: ASDFGHJKL
        val row2Keys = listOf("A", "S", "D", "F", "G", "H", "J", "K", "L")
        rows.add(createKeyRow(row2Keys))
        
        // Row 3: ZXCVBNM with special keys
        val row3 = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, 8, 0, 8)
        }
        
        // Shift key
        val shiftKey = createSpecialKey("⇧", 1.5f) {
            // Toggle case
            handleShift()
        }
        row3.addView(shiftKey)
        
        // Letter keys
        val row3Keys = listOf("Z", "X", "C", "V", "B", "N", "M")
        row3Keys.forEach { key ->
            val keyButton = createKey(key)
            row3.addView(keyButton)
        }
        
        // Backspace key
        val backspaceKey = createSpecialKey("⌫", 1.5f) {
            handleBackspace()
        }
        row3.addView(backspaceKey)
        
        rows.add(row3)
        
        // Row 4: Bottom row with space, numbers, etc.
        val row4 = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, 8, 0, 0)
        }
        
        // Numbers key
        val numbersKey = createSpecialKey("123", 1.5f) {
            // Switch to numbers mode
        }
        row4.addView(numbersKey)
        
        // Space bar
        val spaceKey = createSpecialKey("space", 4f) {
            handleSpace()
        }
        row4.addView(spaceKey)
        
        // Return key
        val returnKey = createSpecialKey("⏎", 1.5f) {
            handleReturn()
        }
        row4.addView(returnKey)
        
        rows.add(row4)
        
        return rows
    }
    
    private fun createKeyRow(keys: List<String>): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, 8, 0, 8)
        }
        
        keys.forEach { key ->
            val keyButton = createKey(key)
            row.addView(keyButton)
        }
        
        return row
    }
    
    private fun createKey(letter: String): Button {
        return Button(this).apply {
            text = letter
            textSize = 16f
            setTextColor(Color.WHITE)
            setBackgroundResource(R.drawable.keyboard_key_bg)
            layoutParams = LinearLayout.LayoutParams(0, 120).apply {
                weight = 1f
                setMargins(2, 2, 2, 2)
            }
            setOnClickListener {
                handleKeyPress(letter)
            }
        }
    }
    
    private fun createSpecialKey(label: String, weight: Float, action: () -> Unit): Button {
        return Button(this).apply {
            text = label
            textSize = 14f
            setTextColor(Color.WHITE)
            setBackgroundResource(R.drawable.keyboard_special_key_bg)
            layoutParams = LinearLayout.LayoutParams(0, 120).apply {
                this.weight = weight
                setMargins(2, 2, 2, 2)
            }
            setOnClickListener { action() }
        }
    }
    
    private fun handleKeyPress(key: String) {
        val inputConnection = currentInputConnection ?: return
        inputConnection.commitText(key.lowercase(), 1)
        
        // Trigger tone analysis for the current text
        triggerToneAnalysis()
    }
    
    private fun handleBackspace() {
        val inputConnection = currentInputConnection ?: return
        inputConnection.deleteSurroundingText(1, 0)
        triggerToneAnalysis()
    }
    
    private fun handleSpace() {
        val inputConnection = currentInputConnection ?: return
        inputConnection.commitText(" ", 1)
        triggerToneAnalysis()
    }
    
    private fun handleReturn() {
        val inputConnection = currentInputConnection ?: return
        inputConnection.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_ENTER))
        inputConnection.sendKeyEvent(KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_ENTER))
    }
    
    private fun handleShift() {
        // For now, just a placeholder
        // In a full implementation, this would toggle case
    }
    
    private fun triggerToneAnalysis() {
        val inputConnection = currentInputConnection ?: return
        val beforeCursor = inputConnection.getTextBeforeCursor(1000, 0) ?: ""
        val afterCursor = inputConnection.getTextAfterCursor(1000, 0) ?: ""
        val fullText = beforeCursor.toString() + afterCursor.toString()
        
        if (fullText.isNotBlank()) {
            // Send to Flutter app for analysis
            val intent = Intent("com.unsaid.keyboard.REQUEST_ANALYSIS")
            intent.putExtra("text", fullText)
            sendBroadcast(intent)
        }
    }
    
    private fun updateToneDisplay(analysis: JSONObject) {
        try {
            val tone = analysis.optString("dominant_tone", "balanced")
            val confidence = analysis.optDouble("confidence", 0.5)
            
            currentTone = tone
            
            // Update tone indicator color
            val toneColor = when (tone.lowercase()) {
                "gentle" -> Color.parseColor("#4CAF50")    // Green
                "direct" -> Color.parseColor("#FF9800")    // Orange  
                "balanced" -> Color.parseColor("#2196F3")  // Blue
                else -> Color.parseColor("#9E9E9E")        // Gray
            }
            
            currentToneView.setBackgroundColor(toneColor)
            
            // Update tone text
            val toneLabel = tone.replaceFirstChar { it.uppercase() }
            val confidencePercent = (confidence * 100).toInt()
            toneIndicator.text = "$toneLabel tone ($confidencePercent%)"
            
        } catch (e: Exception) {
            Log.e(TAG, "Error updating tone display", e)
        }
    }
    
    private fun registerToneAnalysisReceiver() {
        val filter = IntentFilter("com.unsaid.keyboard.TONE_ANALYSIS")
        registerReceiver(toneAnalysisReceiver, filter)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        try {
            unregisterReceiver(toneAnalysisReceiver)
        } catch (e: Exception) {
            // Receiver may not be registered
        }
    }
    
    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        
        // Load keyboard settings
        loadKeyboardSettings()
    }
    
    private fun loadKeyboardSettings() {
        val prefs = getSharedPreferences("unsaid_keyboard_settings", Context.MODE_PRIVATE)
        // Load any saved settings and apply them
        val toneAnalysisEnabled = prefs.getBoolean("tone_analysis_enabled", true)
        // Apply settings to keyboard behavior
    }
}
