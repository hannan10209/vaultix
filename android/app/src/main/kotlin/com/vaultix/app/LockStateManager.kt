package com.vaultix.app

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.security.MessageDigest

data class LockHistoryEntry(
    val packageNames: List<String>,
    val appNames: List<String>,
    val startEpoch: Long,
    val endEpoch: Long,
    val wasHard: Boolean,
    val wasInterrupted: Boolean
) {
    fun toJson(): JSONObject {
        return JSONObject().apply {
            put("packageNames", JSONArray(packageNames))
            put("appNames", JSONArray(appNames))
            put("startEpoch", startEpoch)
            put("endEpoch", endEpoch)
            put("wasHard", wasHard)
            put("wasInterrupted", wasInterrupted)
        }
    }

    companion object {
        fun fromJson(json: JSONObject): LockHistoryEntry {
            val pkgArray = json.getJSONArray("packageNames")
            val nameArray = json.getJSONArray("appNames")
            val pkgs = mutableListOf<String>()
            val names = mutableListOf<String>()
            for (i in 0 until pkgArray.length()) pkgs.add(pkgArray.getString(i))
            for (i in 0 until nameArray.length()) names.add(nameArray.getString(i))
            return LockHistoryEntry(
                packageNames = pkgs,
                appNames = names,
                startEpoch = json.getLong("startEpoch"),
                endEpoch = json.getLong("endEpoch"),
                wasHard = json.getBoolean("wasHard"),
                wasInterrupted = json.getBoolean("wasInterrupted")
            )
        }
    }
}

object LockStateManager {

    private const val PREFS_NAME = "vaultix_prefs"
    private const val KEY_LOCKED_APPS = "locked_apps"
    private const val KEY_LOCKED_APP_NAMES = "locked_app_names"
    private const val KEY_LOCK_ACTIVE = "lock_active"
    private const val KEY_HARD_LOCK = "hard_lock"
    private const val KEY_LOCK_END_TIME = "lock_end_time"
    private const val KEY_APP_END_TIMES = "app_end_times"
    private const val KEY_LOCK_START_TIME = "lock_start_time"
    private const val KEY_PIN_HASH = "vault_pin_hash"
    private const val KEY_LOCK_HISTORY = "lock_history"
    private const val MAX_HISTORY = 50

    private fun prefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    fun setLockedApps(context: Context, packages: List<String>) {
        val jsonArray = JSONArray(packages)
        prefs(context).edit().putString(KEY_LOCKED_APPS, jsonArray.toString()).apply()
    }

    fun getLockedApps(context: Context): List<String> {
        val json = prefs(context).getString(KEY_LOCKED_APPS, "[]") ?: "[]"
        return jsonArrayToList(json)
    }

    fun setLockedAppNames(context: Context, names: List<String>) {
        val jsonArray = JSONArray(names)
        prefs(context).edit().putString(KEY_LOCKED_APP_NAMES, jsonArray.toString()).apply()
    }

    fun getLockedAppNames(context: Context): List<String> {
        val json = prefs(context).getString(KEY_LOCKED_APP_NAMES, "[]") ?: "[]"
        return jsonArrayToList(json)
    }

    fun setLockActive(context: Context, active: Boolean) {
        prefs(context).edit().putBoolean(KEY_LOCK_ACTIVE, active).apply()
    }

    fun isLockActive(context: Context): Boolean {
        return prefs(context).getBoolean(KEY_LOCK_ACTIVE, false)
    }

    fun setHardLock(context: Context, isHard: Boolean) {
        prefs(context).edit().putBoolean(KEY_HARD_LOCK, isHard).apply()
    }

    fun isHardLock(context: Context): Boolean {
        return prefs(context).getBoolean(KEY_HARD_LOCK, false)
    }

    fun saveLockStartTime(context: Context, epochMillis: Long) {
        prefs(context).edit().putLong(KEY_LOCK_START_TIME, epochMillis).apply()
    }

    fun getLockStartTime(context: Context): Long {
        return prefs(context).getLong(KEY_LOCK_START_TIME, 0L)
    }

    fun saveLockEndTime(context: Context, epochMillis: Long) {
        prefs(context).edit().putLong(KEY_LOCK_END_TIME, epochMillis).apply()
    }

    fun getLockEndTime(context: Context): Long {
        return prefs(context).getLong(KEY_LOCK_END_TIME, 0L)
    }

    fun setAppEndTimes(context: Context, appEndTimes: Map<String, Long>) {
        val json = JSONObject()
        for ((pkg, time) in appEndTimes) {
            json.put(pkg, time)
        }
        prefs(context).edit().putString(KEY_APP_END_TIMES, json.toString()).apply()
    }

    fun getAppEndTimes(context: Context): Map<String, Long> {
        val json = prefs(context).getString(KEY_APP_END_TIMES, "{}") ?: "{}"
        val obj = JSONObject(json)
        val map = mutableMapOf<String, Long>()
        for (key in obj.keys()) {
            map[key] = obj.getLong(key)
        }
        return map
    }

    fun clearAll(context: Context) {
        val pinHash = prefs(context).getString(KEY_PIN_HASH, null)
        val history = prefs(context).getString(KEY_LOCK_HISTORY, null)
        prefs(context).edit().clear().apply()
        // Preserve PIN and history across clears
        if (pinHash != null) {
            prefs(context).edit().putString(KEY_PIN_HASH, pinHash).apply()
        }
        if (history != null) {
            prefs(context).edit().putString(KEY_LOCK_HISTORY, history).apply()
        }
    }

    // ── PIN ──

    fun savePin(context: Context, pin: String) {
        val hash = sha256(pin)
        prefs(context).edit().putString(KEY_PIN_HASH, hash).apply()
    }

    fun verifyPin(context: Context, pin: String): Boolean {
        val savedHash = prefs(context).getString(KEY_PIN_HASH, null) ?: return false
        return sha256(pin) == savedHash
    }

    fun hasPin(context: Context): Boolean {
        val hash = prefs(context).getString(KEY_PIN_HASH, null)
        return !hash.isNullOrEmpty()
    }

    fun clearPin(context: Context) {
        prefs(context).edit().remove(KEY_PIN_HASH).apply()
    }

    private fun sha256(input: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val hashBytes = digest.digest(input.toByteArray(Charsets.UTF_8))
        return hashBytes.joinToString("") { "%02x".format(it) }
    }

    // ── Lock History ──

    fun appendLockHistory(context: Context, entry: LockHistoryEntry) {
        val history = getLockHistoryInternal(context).toMutableList()
        history.add(entry)
        // Keep only last MAX_HISTORY entries
        while (history.size > MAX_HISTORY) {
            history.removeAt(0)
        }
        val jsonArray = JSONArray()
        for (e in history) {
            jsonArray.put(e.toJson())
        }
        prefs(context).edit().putString(KEY_LOCK_HISTORY, jsonArray.toString()).apply()
    }

    fun clearHistory(context: Context) {
        prefs(context).edit().remove(KEY_LOCK_HISTORY).apply()
    }

    fun completeAllOpenHistoryEntries(context: Context): Boolean {
        val history = getLockHistoryInternal(context).toMutableList()
        var changed = false
        for (i in history.indices) {
            if (history[i].endEpoch == 0L) {
                history[i] = history[i].copy(
                    endEpoch = System.currentTimeMillis(),
                    wasInterrupted = false
                )
                changed = true
            }
        }
        if (!changed) return false
        val jsonArray = JSONArray()
        for (e in history) {
            jsonArray.put(e.toJson())
        }
        prefs(context).edit().putString(KEY_LOCK_HISTORY, jsonArray.toString()).apply()
        return true
    }

    fun getLockHistory(context: Context): List<LockHistoryEntry> {
        return getLockHistoryInternal(context)
    }

    private fun getLockHistoryInternal(context: Context): List<LockHistoryEntry> {
        val json = prefs(context).getString(KEY_LOCK_HISTORY, "[]") ?: "[]"
        val jsonArray = JSONArray(json)
        val list = mutableListOf<LockHistoryEntry>()
        for (i in 0 until jsonArray.length()) {
            try {
                list.add(LockHistoryEntry.fromJson(jsonArray.getJSONObject(i)))
            } catch (_: Exception) {}
        }
        return list
    }

    private fun jsonArrayToList(json: String): List<String> {
        val jsonArray = JSONArray(json)
        val list = mutableListOf<String>()
        for (i in 0 until jsonArray.length()) {
            list.add(jsonArray.getString(i))
        }
        return list
    }
}
