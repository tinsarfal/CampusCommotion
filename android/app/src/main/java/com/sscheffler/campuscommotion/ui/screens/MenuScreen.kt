package com.sscheffler.campuscommotion.ui.screens

import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.viewinterop.AndroidView
import androidx.hilt.navigation.compose.hiltViewModel
import com.sscheffler.campuscommotion.R
import com.sscheffler.campuscommotion.ui.viewmodel.MenuViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MenuScreen(
    viewModel: MenuViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.todays_menu)) },
                actions = {
                    IconButton(onClick = { viewModel.refreshMenu() }) {
                        Icon(
                            Icons.Default.Refresh,
                            contentDescription = stringResource(R.string.refresh)
                        )
                    }
                }
            )
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            AndroidView(
                factory = { context ->
                    WebView(context).apply {
                        webViewClient = object : WebViewClient() {
                            override fun onPageFinished(view: WebView?, url: String?) {
                                super.onPageFinished(view, url)
                                // Inject dark mode CSS
                                val darkModeCSS = """
                                    javascript:(function() {
                                        var css = 'html {background-color: black !important; color: #ffffff;} .epicure-branding {display: none !important} .navbar-brand {display: none !important} .logo-container {display: none !important;} .NavigationBar {background-color:#1a1a1a !important} body {background: black !important} .MenuList h3 span {color:white !important;} .MenuList h3 {color:white !important;} .MenuListCard {background-color: #141414 !important;} .card-title{color:white !important;} .nutrients-list small {color:white !important;} .btn.active {background-color:#8d1b1d !important; color:white !important;}.form-select {background-color:black !important; color:white !important;}.feedback-switch button {color:white !important;}.view-switch button {color:white !important;}.sidebar{background-color:black !important; color:white !important;}.SidebarMeal .mb-title {background-color: black !important; color:white !important;}.form-control {background-color: black !important; color:white !important;}';
                                        var style = document.createElement('style');
                                        style.innerHTML = css;
                                        document.head.appendChild(style);
                                    })();
                                """.trimIndent()
                                
                                evaluateJavascript(darkModeCSS, null)
                            }
                        }
                        settings.javaScriptEnabled = true
                        settings.domStorageEnabled = true
                    }
                },
                update = { webView ->
                    val url = if (uiState.useOldMenu) {
                        "https://epicuremenus.com/clients/exeter/online"
                    } else {
                        "https://epicuremenus.com/clients/ion/exeter/nn"
                    }
                    
                    if (uiState.shouldRefresh) {
                        webView.loadUrl(url)
                        viewModel.onRefreshComplete()
                    } else if (webView.url != url) {
                        webView.loadUrl(url)
                    }
                },
                modifier = Modifier.fillMaxSize()
            )
            
            if (uiState.isLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.align(Alignment.Center)
                )
            }
        }
    }
}