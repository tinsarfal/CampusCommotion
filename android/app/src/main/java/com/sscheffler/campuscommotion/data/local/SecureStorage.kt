package com.sscheffler.campuscommotion.data.local

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SecureStorage @Inject constructor(
    @ApplicationContext private val context: Context
) {
    
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()
    
    private val sharedPreferences: SharedPreferences = EncryptedSharedPreferences.create(
        context,
        "secure_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )
    
    fun getString(key: String, defaultValue: String = ""): String {
        return sharedPreferences.getString(key, defaultValue) ?: defaultValue
    }
    
    fun setString(key: String, value: String) {
        sharedPreferences.edit().putString(key, value).apply()
    }
    
    fun getBoolean(key: String, defaultValue: Boolean = false): Boolean {
        return sharedPreferences.getBoolean(key, defaultValue)
    }
    
    fun setBoolean(key: String, value: Boolean) {
        sharedPreferences.edit().putBoolean(key, value).apply()
    }
    
    fun clear() {
        sharedPreferences.edit().clear().apply()
    }
    
    fun remove(key: String) {
        sharedPreferences.edit().remove(key).apply()
    }
    
    // Specific getters and setters for app data
    var email: String
        get() = getString("email")
        set(value) = setString("email", value)
    
    var calUrl: String
        get() = getString("calurl")
        set(value) = setString("calurl", value)
    
    var clubUrl: String
        get() = getString("cluburl")
        set(value) = setString("cluburl", value)
    
    var token: String
        get() = getString("token")
        set(value) = setString("token", value)
    
    var requestData: String
        get() = getString("request_data")
        set(value) = setString("request_data", value)
    
    var lastColors: String
        get() = getString("lastColors")
        set(value) = setString("lastColors", value)
    
    var oldMenu: Boolean
        get() = getBoolean("oldMenu")
        set(value) = setBoolean("oldMenu", value)
}