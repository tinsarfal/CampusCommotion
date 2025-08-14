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

data class MenuUiState(
    val isLoading: Boolean = false,
    val shouldRefresh: Boolean = false,
    val useOldMenu: Boolean = false
)

@HiltViewModel
class MenuViewModel @Inject constructor(
    private val secureStorage: SecureStorage
) : ViewModel() {
    
    private val _uiState = MutableStateFlow(MenuUiState())
    val uiState: StateFlow<MenuUiState> = _uiState.asStateFlow()
    
    init {
        loadMenuPreference()
    }
    
    private fun loadMenuPreference() {
        _uiState.value = _uiState.value.copy(
            useOldMenu = secureStorage.oldMenu
        )
    }
    
    fun refreshMenu() {
        _uiState.value = _uiState.value.copy(shouldRefresh = true, isLoading = true)
    }
    
    fun onRefreshComplete() {
        _uiState.value = _uiState.value.copy(shouldRefresh = false, isLoading = false)
    }
}