package com.khandoba.securedocs

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.khandoba.securedocs.ui.theme.KhandobaSecureDocsTheme
import com.khandoba.securedocs.ui.ContentView
import com.khandoba.securedocs.ui.ShareToVaultView

class MainActivity : ComponentActivity() {
    private var sharedUri: Uri? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        
        // Handle share intent (ACTION_SEND or ACTION_SEND_MULTIPLE)
        handleShareIntent(intent)
        
        setContent {
            KhandobaSecureDocsTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    if (sharedUri != null) {
                        // Show vault selection for shared content
                        ShareToVaultHandler(sharedUri = sharedUri!!)
                    } else {
                        ContentView()
                    }
                }
            }
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleShareIntent(intent)
        // Re-compose will happen automatically
    }
    
    private fun handleShareIntent(intent: Intent?) {
        if (intent == null) return
        
        when (intent.action) {
            Intent.ACTION_SEND -> {
                // Single file/share
                val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                sharedUri = uri
                Log.d("MainActivity", "Received share: $uri")
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                // Multiple files - for now, handle first one
                val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                sharedUri = uris?.firstOrNull()
                Log.d("MainActivity", "Received multiple shares: ${uris?.size} files")
            }
        }
    }
}

@Composable
private fun ShareToVaultHandler(sharedUri: Uri) {
    // This composable will handle the vault selection and document upload
    // For now, show a placeholder - actual implementation would integrate with
    // DocumentService and navigation
    Text("Share to Vault: $sharedUri")
    // TODO: Integrate with ContentView navigation to show ShareToVaultView
}
