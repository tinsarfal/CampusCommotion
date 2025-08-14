package com.sscheffler.campuscommotion.network

import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthInterceptor @Inject constructor(
    private val tokenProvider: () -> String
) : Interceptor {
    
    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()
        
        // Only add auth header for Canvas API requests
        if (originalRequest.url.host == "canvas.exeter.edu") {
            val token = tokenProvider()
            if (token.isNotEmpty()) {
                val authenticatedRequest = originalRequest.newBuilder()
                    .header("Authorization", "Bearer $token")
                    .build()
                return chain.proceed(authenticatedRequest)
            }
        }
        
        return chain.proceed(originalRequest)
    }
}