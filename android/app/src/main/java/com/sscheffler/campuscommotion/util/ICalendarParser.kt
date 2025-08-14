package com.sscheffler.campuscommotion.util

import com.sscheffler.campuscommotion.util.BlockStyling
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ICalendarParser @Inject constructor() {
    
    fun parseICalendar(icalString: String, clubsString: String): Triple<List<List<List<Map<String, Any>>>>, List<String>, Int> {
        val allBlocks = mutableListOf<Map<String, Any>>()
        val uniqueClubs = mutableListOf<String>()
        
        // Parse main calendar
        allBlocks.addAll(parseEvents(icalString, false))
        
        // Parse clubs calendar
        if (clubsString.isNotEmpty()) {
            val clubBlocks = parseEvents(clubsString, true)
            allBlocks.addAll(clubBlocks)
            
            // Extract unique club names
            clubBlocks.forEach { block ->
                val clubName = block["classname"] as? String ?: ""
                if (clubName.isNotEmpty() && !uniqueClubs.contains(clubName)) {
                    uniqueClubs.add(clubName)
                }
            }
        }
        
        // Group blocks by weeks
        val weekSchedules = groupByWeeks(allBlocks)
        val startWeek = findStartWeek(weekSchedules)
        
        return Triple(weekSchedules, uniqueClubs, startWeek)
    }
    
    private fun parseEvents(icalString: String, isClub: Boolean): List<Map<String, Any>> {
        val blocks = mutableListOf<Map<String, Any>>()
        val lines = icalString.split("\n")
        var inEvent = false
        var currentEvent = mutableMapOf<String, Any>()
        
        for (line in lines) {
            val trimmedLine = line.trim()
            
            when {
                trimmedLine.contains("BEGIN:VEVENT") -> {
                    inEvent = true
                    currentEvent = mutableMapOf()
                }
                trimmedLine.contains("END:VEVENT") -> {
                    inEvent = false
                    if (currentEvent.isNotEmpty()) {
                        processEvent(currentEvent, isClub)?.let { blocks.add(it) }
                    }
                }
                inEvent -> {
                    parseEventLine(trimmedLine, currentEvent)
                }
            }
        }
        
        return blocks
    }
    
    private fun parseEventLine(line: String, currentEvent: MutableMap<String, Any>) {
        when {
            line.startsWith("DTSTART") -> {
                val dateTime = extractDateTime(line)
                if (dateTime != null) {
                    val (date, time, isPM) = dateTime
                    currentEvent["date"] = date
                    currentEvent["starttime"] = time
                    currentEvent["pmstart"] = isPM
                }
            }
            line.startsWith("DTEND") -> {
                val dateTime = extractDateTime(line)
                if (dateTime != null) {
                    val (_, time, isPM) = dateTime
                    currentEvent["endtime"] = time
                    currentEvent["pmend"] = isPM
                }
            }
            line.startsWith("SUMMARY:") -> {
                val summary = line.substringAfter("SUMMARY:")
                currentEvent["classname"] = summary
                currentEvent["blockLetter"] = extractBlockLetter(summary)
            }
            line.startsWith("LOCATION:") -> {
                currentEvent["location"] = line.substringAfter("LOCATION:")
            }
            line.startsWith("UID:") -> {
                currentEvent["uid"] = line.substringAfter("UID:")
            }
        }
    }
    
    private fun extractDateTime(line: String): Triple<String, String, Boolean>? {
        try {
            val dateTimeString = when {
                line.contains(":") -> line.substringAfter(":")
                else -> return null
            }
            
            // Handle TZID parameter
            val actualDateTime = if (dateTimeString.contains(":")) {
                dateTimeString.substringAfter(":")
            } else {
                dateTimeString
            }
            
            // Parse date-time
            val inputFormat = SimpleDateFormat("yyyyMMdd'T'HHmmss", Locale.getDefault())
            val date = inputFormat.parse(actualDateTime.take(15)) ?: return null
            
            // Format date
            val dateFormat = SimpleDateFormat("EEEE M/d", Locale.getDefault())
            val formattedDate = dateFormat.format(date)
            
            // Format time
            val timeFormat = SimpleDateFormat("h:mm", Locale.getDefault())
            val formattedTime = timeFormat.format(date)
            
            // Check if PM
            val calendar = Calendar.getInstance()
            calendar.time = date
            val isPM = calendar.get(Calendar.HOUR_OF_DAY) >= 12
            
            return Triple(formattedDate, formattedTime, isPM)
        } catch (e: Exception) {
            return null
        }
    }
    
    private fun extractBlockLetter(summary: String): String {
        // Simplified block letter extraction
        when {
            summary.contains("Advising") -> return "ADV"
            summary.contains("Assembly") -> return "Assembly"
            summary.contains("First Day") -> return "First Day"
        }
        
        // Look for pattern in parentheses
        val regex = """\(([^)]+)\)""".toRegex()
        val match = regex.findAll(summary).lastOrNull()
        if (match != null) {
            val blockLetter = match.groupValues[1]
            if (blockLetter != "Phillips Exeter Academy") {
                return blockLetter
            }
        }
        
        // Look for pattern before parentheses
        val dashIndex = summary.lastIndexOf("-")
        val parenIndex = summary.lastIndexOf("(")
        if (dashIndex != -1 && parenIndex != -1 && dashIndex < parenIndex) {
            val extracted = summary.substring(dashIndex + 1, parenIndex).trim()
            return extracted.replace(Regex("\\d+$"), "").trim()
        }
        
        return ""
    }
    
    private fun processEvent(event: Map<String, Any>, isClub: Boolean): Map<String, Any>? {
        val blockLetter = event["blockLetter"] as? String ?: ""
        val className = event["classname"] as? String ?: ""
        
        return mapOf(
            "date" to (event["date"] ?: ""),
            "blockid" to if (isClub) "CLB" else blockLetter,
            "color" to if (isClub) "#6A5ACD" else BlockStyling.applyStyling(blockLetter),
            "starttime" to (event["starttime"] ?: ""),
            "pmstart" to (event["pmstart"] ?: false),
            "endtime" to (event["endtime"] ?: ""),
            "pmend" to (event["pmend"] ?: false),
            "classname" to className,
            "location" to (event["location"] ?: "")
        )
    }
    
    private fun groupByWeeks(blocks: List<Map<String, Any>>): List<List<List<Map<String, Any>>>> {
        // Simplified week grouping - group by date and assume 7-day weeks
        val dateGroups = blocks.groupBy { it["date"] as String }
        val sortedDates = dateGroups.keys.sorted()
        
        val weeks = mutableListOf<List<List<Map<String, Any>>>>()
        var currentWeek = mutableListOf<List<Map<String, Any>>>()
        
        for (date in sortedDates) {
            currentWeek.add(dateGroups[date] ?: emptyList())
            
            if (currentWeek.size >= 7) {
                weeks.add(currentWeek.toList())
                currentWeek = mutableListOf()
            }
        }
        
        if (currentWeek.isNotEmpty()) {
            weeks.add(currentWeek.toList())
        }
        
        return weeks
    }
    
    private fun findStartWeek(weeks: List<List<List<Map<String, Any>>>>): Int {
        // Find first week with non-club blocks
        weeks.forEachIndexed { index, week ->
            val hasNonClubBlock = week.flatten().any { block ->
                val blockId = block["blockid"] as? String ?: ""
                blockId != "CLB" && blockId.isNotEmpty()
            }
            if (hasNonClubBlock) {
                return index
            }
        }
        return -1
    }
}