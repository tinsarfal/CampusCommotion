package com.sscheffler.campuscommotion.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sscheffler.campuscommotion.data.local.SecureStorage
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ProfileUiState(
    val email: String = "",
    val calUrl: String = "",
    val clubUrl: String = "",
    val token: String = "",
    val showSuccessMessage: Boolean = false
)

@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val secureStorage: SecureStorage
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(ProfileUiState())
    val uiState: StateFlow<ProfileUiState> = _uiState.asStateFlow()
    
    init {
        loadSettings()
    }
    
    private fun loadSettings() {
        _uiState.value = _uiState.value.copy(
            email = secureStorage.email,
            calUrl = secureStorage.calUrl,
            clubUrl = secureStorage.clubUrl,
            token = secureStorage.token
        )
    }
    
    fun updateEmail(email: String) {
        _uiState.value = _uiState.value.copy(email = email, showSuccessMessage = false)
    }
    
    fun updateCalUrl(calUrl: String) {
        val cleanedUrl = calUrl.trim()
            .replace("webcal", "https")
            .replace("http://", "https://")
        _uiState.value = _uiState.value.copy(calUrl = cleanedUrl, showSuccessMessage = false)
    }
    
    fun updateClubUrl(clubUrl: String) {
        val cleanedUrl = clubUrl.trim()
            .replace("webcal", "https")
            .replace("http://", "https://")
        _uiState.value = _uiState.value.copy(clubUrl = cleanedUrl, showSuccessMessage = false)
    }
    
    fun updateToken(token: String) {
        _uiState.value = _uiState.value.copy(token = token.trim(), showSuccessMessage = false)
    }
    
    fun saveInformation() {
        viewModelScope.launch {
            val currentState = _uiState.value
            
            secureStorage.email = currentState.email.trim()
            secureStorage.calUrl = currentState.calUrl
            secureStorage.clubUrl = currentState.clubUrl
            secureStorage.token = currentState.token
            
            _uiState.value = _uiState.value.copy(showSuccessMessage = true)
        }
    }
}