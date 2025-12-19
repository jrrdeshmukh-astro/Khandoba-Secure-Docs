package com.khandoba.securedocs.ui

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.sp

@Composable
fun ContentView(
    modifier: Modifier = Modifier
) {
    // TODO: Implement authentication check and navigation
    // For now, show a placeholder
    Text(
        text = "Khandoba Secure Docs\nAndroid App\n\nFoundation Complete!\n\nNext: Implement services and UI",
        modifier = modifier.fillMaxSize(),
        textAlign = TextAlign.Center,
        fontSize = 18.sp
    )
}
