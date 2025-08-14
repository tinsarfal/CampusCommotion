package com.sscheffler.campuscommotion.util

import androidx.compose.ui.graphics.Color

object BlockStyling {
    
    fun applyStyling(letter: String): String {
        // Check if the letter contains any of the special cases first
        if (letter.contains("PEG") || letter.contains("PEB") || 
            letter.contains("PEM") || letter.contains("DAN")) {
            return "#E1E2E2" // Special case color
        }
        
        // Define the color mapping for base letters
        return when (letter) {
            "A", "T", "A Short", "A Long" -> "#f25c5a" // Red
            "B", "U", "B Long", "B Short" -> "#f7a877" // Orange
            "C", "V", "C Long", "C Short" -> "#3cb371" // Green
            "D", "W", "D Long", "D Short" -> "#6495ed" // Blue
            "E", "X", "E Long", "E Short" -> "#fff44f" // Yellow
            "F", "Y", "F Long", "F Short" -> "#9370db" // Purple
            "G", "Z", "G Long", "G Short" -> "#ff69b4" // Pink
            "Q", "H", "H Long", "H Short" -> "#07ABD7" // Aqua
            "ME" -> "#90EE90" // Light Green
            "PE1", "PE2", "PE3", "PE4", "PE5" -> "#c0c0c0" // Gray
            "Advising", "Assembly" -> "#ffffff"
            else -> {
                // Extract the base letter from the input if it contains a number
                val baseLetter = letter.takeWhile { it.isLetter() }
                when (baseLetter) {
                    "A", "T", "AT" -> "#f25c5a" // Red
                    "B", "U", "BU" -> "#f7a877" // Orange
                    "C", "V", "CV" -> "#3cb371" // Green
                    "D", "W", "DW" -> "#6495ed" // Blue
                    "E", "X", "EX" -> "#fff44f" // Yellow
                    "F", "Y", "FY" -> "#9370db" // Purple
                    "G", "Z", "GZ" -> "#ff69b4" // Pink
                    "Q", "H", "HQ" -> "#07ABD7" // Aqua
                    else -> "#ffffff" // White
                }
            }
        }
    }
    
    fun getBlockColor(letter: String): Color {
        val hexColor = applyStyling(letter)
        return Color(android.graphics.Color.parseColor(hexColor))
    }
}