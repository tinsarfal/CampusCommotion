package com.sscheffler.campuscommotion.data.repository

import com.sscheffler.campuscommotion.data.local.SecureStorage
import com.sscheffler.campuscommotion.data.model.ScheduleResponse
import com.sscheffler.campuscommotion.network.ApiService
import com.sscheffler.campuscommotion.util.ICalendarParser
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ScheduleRepository @Inject constructor(
    private val apiService: ApiService,
    private val secureStorage: SecureStorage,
    private val iCalendarParser: ICalendarParser,
    private val json: Json
) {
    
    suspend fun fetchAndParseSchedule(calUrl: String, clubUrl: String, token: String) {
        withContext(Dispatchers.IO) {
            try {
                // Fetch calendar data
                val calendarResponse = apiService.getCalendar(calUrl)
                val calendarData = calendarResponse.body() ?: ""
                
                val clubData = if (clubUrl.isNotEmpty()) {
                    val clubResponse = apiService.getCalendar(clubUrl)
                    clubResponse.body() ?: ""
                } else {
                    ""
                }
                
                // Parse iCalendar data
                val (weekSchedules, uniqueClubs, startWeek) = iCalendarParser.parseICalendar(
                    calendarData, clubData
                )
                
                // Save parsed data
                saveScheduleData(weekSchedules, startWeek)
                
                // Fetch Canvas course data if token is provided
                if (token.isNotEmpty()) {
                    fetchCanvasCourses()
                }
                
            } catch (e: Exception) {
                throw e
            }
        }
    }
    
    private fun saveScheduleData(weekSchedules: List<List<List<Map<String, Any>>>>, startWeek: Int) {
        val dateFormat = SimpleDateFormat("yyyy/MM/dd, HH:mm:ss.SSS", Locale.getDefault())
        val timestamp = dateFormat.format(Date())
        
        val dayFormat = SimpleDateFormat("dd", Locale.getDefault())
        val retrievedDay = dayFormat.format(Date())
        
        val scheduleResponse = ScheduleResponse(
            success = true,
            all_weeks_blocks = weekSchedules.map { week ->
                week.map { day ->
                    day.map { block ->
                        com.sscheffler.campuscommotion.data.model.ScheduleBlock(
                            date = block["date"] as? String ?: "",
                            blockid = block["blockid"] as? String ?: "",
                            color = block["color"] as? String ?: "",
                            starttime = block["starttime"] as? String ?: "",
                            pmstart = block["pmstart"] as? Boolean ?: false,
                            endtime = block["endtime"] as? String ?: "",
                            pmend = block["pmend"] as? Boolean ?: false,
                            classname = block["classname"] as? String ?: "",
                            location = block["location"] as? String ?: ""
                        )
                    }
                }
            },
            timestamp = timestamp,
            day_retrieved = retrievedDay,
            startweek = startWeek
        )
        
        val jsonData = json.encodeToString(ScheduleResponse.serializer(), scheduleResponse)
        secureStorage.requestData = jsonData
    }
    
    private suspend fun fetchCanvasCourses() {
        try {
            val enrollmentsResponse = apiService.getEnrollments()
            if (enrollmentsResponse.isSuccessful) {
                val enrollments = enrollmentsResponse.body() ?: emptyList()
                
                val validEnrollments = enrollments.filter { 
                    it.course_id > 0 && it.course_section_id > 0 
                }
                
                // For now, just log the course data
                // In a full implementation, you would process and store course/student data
                println("Found ${validEnrollments.size} valid enrollments")
            }
        } catch (e: Exception) {
            // Canvas course fetching is optional, don't fail the whole operation
            println("Failed to fetch Canvas courses: ${e.message}")
        }
    }
}