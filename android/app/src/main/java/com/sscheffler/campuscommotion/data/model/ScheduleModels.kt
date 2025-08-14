package com.sscheffler.campuscommotion.data.model

import kotlinx.serialization.Serializable

@Serializable
data class ScheduleDate(
    val id: Int,
    val name: String
)

@Serializable
data class ScheduleLink(
    val username: String,
    val url: String
)

@Serializable
data class StudentImage(
    val studentname: String,
    val image: String,
    val studentID: Int
)

@Serializable
data class CourseData(
    val coursecode: String,
    val students: List<StudentImage>,
    val courseid: Int,
    val sectionid: Int
)

@Serializable
data class ScheduleBlock(
    val date: String,
    val blockid: String,
    val color: String,
    val starttime: String,
    val pmstart: Boolean,
    val endtime: String,
    val pmend: Boolean,
    val classname: String,
    val location: String
)

@Serializable
data class ScheduleResponse(
    val success: Boolean,
    val all_weeks_blocks: List<List<List<ScheduleBlock>>>,
    val timestamp: String,
    val day_retrieved: String,
    val startweek: Int
)