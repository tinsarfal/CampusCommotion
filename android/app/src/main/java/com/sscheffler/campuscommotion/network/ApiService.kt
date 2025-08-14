package com.sscheffler.campuscommotion.network

import com.sscheffler.campuscommotion.data.model.CourseData
import com.sscheffler.campuscommotion.data.model.StudentImage
import kotlinx.serialization.Serializable
import retrofit2.Response
import retrofit2.http.GET
import retrofit2.http.Path
import retrofit2.http.Query
import retrofit2.http.Url

@Serializable
data class EnrollmentResponse(
    val course_id: Int,
    val course_section_id: Int
)

@Serializable
data class CourseResponse(
    val course_code: String
)

@Serializable
data class StudentEnrollmentResponse(
    val user: UserResponse
)

@Serializable
data class UserResponse(
    val id: Int,
    val name: String,
    val avatar_url: String
)

interface ApiService {
    
    @GET
    suspend fun getCalendar(@Url url: String): Response<String>
    
    @GET("https://canvas.exeter.edu/api/v1/users/self/enrollments")
    suspend fun getEnrollments(
        @Query("per_page") perPage: Int = 100
    ): Response<List<EnrollmentResponse>>
    
    @GET("https://canvas.exeter.edu/api/v1/courses/{courseId}")
    suspend fun getCourse(
        @Path("courseId") courseId: Int,
        @Query("per_page") perPage: Int = 100
    ): Response<CourseResponse>
    
    @GET("https://canvas.exeter.edu/api/v1/sections/{sectionId}/enrollments")
    suspend fun getSectionEnrollments(
        @Path("sectionId") sectionId: Int,
        @Query("include") include: String = "avatar_url",
        @Query("per_page") perPage: Int = 100,
        @Query("type") type: String = "StudentEnrollment"
    ): Response<List<StudentEnrollmentResponse>>
}