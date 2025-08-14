package com.sscheffler.campuscommotion.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sscheffler.campuscommotion.data.local.SecureStorage
import com.sscheffler.campuscommotion.data.model.ScheduleBlock
import com.sscheffler.campuscommotion.data.model.ScheduleResponse
import com.sscheffler.campuscommotion.data.repository.ScheduleRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import java.text.SimpleDateFormat
import java.util.*
import javax.inject.Inject

data class ScheduleUiState(
    val isLoading: Boolean = false,
    val scheduleBlocks: List<ScheduleBlock> = emptyList(),
    val dateSelected: String = "",
    val error: String? = null
)

@HiltViewModel
class ScheduleViewModel @Inject constructor(
    private val scheduleRepository: ScheduleRepository,
    private val secureStorage: SecureStorage,
    private val json: Json
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(ScheduleUiState())
    val uiState: StateFlow<ScheduleUiState> = _uiState.asStateFlow()
    
    init {
        loadCachedSchedule()
        refreshSchedule()
    }
    
    fun refreshSchedule() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            
            try {
                val calUrl = secureStorage.calUrl
                val clubUrl = secureStorage.clubUrl
                val token = secureStorage.token
                
                if (calUrl.isNotEmpty()) {
                    scheduleRepository.fetchAndParseSchedule(calUrl, clubUrl, token)
                    loadCachedSchedule()
                } else {
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = "Calendar URL not configured"
                    )
                }
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.message ?: "Unknown error occurred"
                )
            }
        }
    }
    
    private fun loadCachedSchedule() {
        try {
            val requestData = secureStorage.requestData
            if (requestData.isNotEmpty()) {
                val scheduleResponse = json.decodeFromString<ScheduleResponse>(requestData)
                val todaysBlocks = getTodaysBlocks(scheduleResponse)
                val todayDate = getCurrentDateString()
                
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    scheduleBlocks = todaysBlocks,
                    dateSelected = todayDate,
                    error = null
                )
            }
        } catch (e: Exception) {
            // Ignore cache loading errors, just set empty state
            _uiState.value = _uiState.value.copy(
                isLoading = false,
                scheduleBlocks = emptyList(),
                dateSelected = "",
                error = null
            )
        }
    }
    
    private fun getTodaysBlocks(scheduleResponse: ScheduleResponse): List<ScheduleBlock> {
        val todayDate = getCurrentDateString()
        
        for (week in scheduleResponse.all_weeks_blocks) {
            for (day in week) {
                if (day.isNotEmpty() && day.first().date.contains(todayDate)) {
                    return day
                }
            }
        }
        
        return emptyList()
    }
    
    private fun getCurrentDateString(): String {
        val dateFormat = SimpleDateFormat("M/d", Locale.getDefault())
        return dateFormat.format(Date())
    }
}