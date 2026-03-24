package com.vaultix.app

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class BlockOverlayActivity : ComponentActivity() {

    private var isHardLock: Boolean = true
    private var blockedPackage: String = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        isHardLock = intent.getBooleanExtra("is_hard_lock", true)
        blockedPackage = intent.getStringExtra("blocked_package") ?: ""

        val appName = try {
            val ai = packageManager.getApplicationInfo(blockedPackage, 0)
            packageManager.getApplicationLabel(ai).toString()
        } catch (_: Exception) {
            blockedPackage
        }

        val endTimeText = if (isHardLock) {
            val endEpoch = LockStateManager.getLockEndTime(this)
            if (endEpoch > 0) {
                val fmt = SimpleDateFormat("HH:mm", Locale.getDefault())
                "Hard locked until ${fmt.format(Date(endEpoch))}"
            } else {
                "Hard locked"
            }
        } else {
            ""
        }

        setContent {
            BlockOverlayScreen(
                appName = appName,
                isHardLock = isHardLock,
                hardLockTimeText = endTimeText,
                onGoToVaultix = {
                    val intent = Intent(this, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                }
            )
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Consume — do nothing
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        relaunchSelf()
    }

    private fun relaunchSelf() {
        val intent = Intent(this, BlockOverlayActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_HISTORY)
            putExtra("blocked_package", blockedPackage)
            putExtra("is_hard_lock", isHardLock)
        }
        startActivity(intent)
    }
}

@Composable
fun BlockOverlayScreen(
    appName: String,
    isHardLock: Boolean,
    hardLockTimeText: String,
    onGoToVaultix: () -> Unit
) {
    val bgColor = Color(0xFF0D0D0D)
    val greyText = Color(0xFF9E9E9E)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(bgColor),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.padding(32.dp)
        ) {
            Icon(
                painter = painterResource(id = R.drawable.ic_vaultix_lock),
                contentDescription = "Lock",
                tint = Color.White,
                modifier = Modifier.size(72.dp)
            )

            Spacer(modifier = Modifier.height(24.dp))

            Text(
                text = "App Locked",
                color = Color.White,
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "$appName is locked by Vaultix",
                color = greyText,
                fontSize = 16.sp,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(48.dp))

            if (isHardLock) {
                Text(
                    text = hardLockTimeText,
                    color = greyText,
                    fontSize = 14.sp
                )
            } else {
                OutlinedButton(onClick = onGoToVaultix) {
                    Text(text = "Go to Vaultix", color = Color.White)
                }
            }

            Spacer(modifier = Modifier.height(64.dp))

            Text(
                text = "Powered by Vaultix",
                color = Color(0xFF616161),
                fontSize = 12.sp
            )
        }
    }
}
