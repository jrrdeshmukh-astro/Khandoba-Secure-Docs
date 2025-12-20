package com.khandoba.securedocs.ui.store

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.khandoba.securedocs.service.SubscriptionService

@Composable
fun StoreView(
    subscriptionService: SubscriptionService,
    onDismiss: () -> Unit
) {
    val subscriptionStatus by subscriptionService.subscriptionStatus.collectAsState()
    val products by subscriptionService.products.collectAsState()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Premium Subscription") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(24.dp)
        ) {
            // Header
            Icon(
                Icons.Default.Star,
                contentDescription = null,
                modifier = Modifier.size(64.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            
            Text(
                text = "Upgrade to Premium",
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold
            )
            
            Text(
                text = "Unlock unlimited vaults and all premium features",
                fontSize = 14.sp,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Features list
            FeatureRow(icon = "🔒", text = "Unlimited vaults")
            FeatureRow(icon = "🤖", text = "AI-powered intelligence")
            FeatureRow(icon = "☁️", text = "Cloud backup")
            FeatureRow(icon = "👥", text = "Family sharing (6 members)")
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Subscription options
            products.forEach { product ->
                SubscriptionCard(
                    product = product,
                    onClick = {
                        subscriptionService.purchaseSubscription(product)
                    }
                )
            }
            
            // Current status
            if (subscriptionStatus == SubscriptionService.SubscriptionStatus.Premium) {
                Surface(
                    color = MaterialTheme.colorScheme.primaryContainer,
                    shape = MaterialTheme.shapes.medium
                ) {
                    Text(
                        text = "You have an active premium subscription",
                        modifier = Modifier.padding(16.dp),
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
            }
        }
    }
}

@Composable
private fun FeatureRow(icon: String, text: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text = icon, fontSize = 20.sp)
        Text(
            text = text,
            fontSize = 14.sp
        )
    }
}

@Composable
private fun SubscriptionCard(
    product: com.android.billingclient.api.ProductDetails,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        onClick = onClick
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = product.name,
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
            
            // Get price from subscription offer details
            val price = product.subscriptionOfferDetails?.firstOrNull()?.pricingPhases
                ?.pricingPhaseList?.firstOrNull()?.formattedPrice
            
            if (price != null) {
                Text(
                    text = price,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary
                )
            }
        }
    }
}
