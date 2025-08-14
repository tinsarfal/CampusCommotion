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

data class PreferencesUiState(
    val useOldMenu: Boolean = false
)

@HiltViewModel
class PreferencesViewModel @Inject constructor(
    private val secureStorage: SecureStorage
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(PreferencesUiState())
    val uiState: StateFlow<PreferencesUiState> = _uiState.asStateFlow()
    
    init {
        loadPreferences()
    }
    
    private fun loadPreferences() {
        _uiState.value = _uiState.value.copy(
            useOldMenu = secureStorage.oldMenu
        )
    }
    
    fun toggleOldMenu(useOld: Boolean) {
        viewModelScope.launch {
            secureStorage.oldMenu = useOld
            _uiState.value = _uiState.value.copy(useOldMenu = useOld)
        }
    }
}