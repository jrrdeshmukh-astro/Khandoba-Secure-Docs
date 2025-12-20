package com.khandoba.securedocs.ui

import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.material3.Text
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.khandoba.securedocs.KhandobaApplication
import com.khandoba.securedocs.data.repository.UserRepository
import com.khandoba.securedocs.data.repository.VaultRepository
import com.khandoba.securedocs.data.supabase.SupabaseService
import com.khandoba.securedocs.service.AuthenticationService
import com.khandoba.securedocs.service.VaultService
import com.khandoba.securedocs.service.DocumentService
import com.khandoba.securedocs.service.DocumentIndexingService
import com.khandoba.securedocs.service.EncryptionService
import com.khandoba.securedocs.data.repository.DocumentRepository
import com.khandoba.securedocs.data.repository.VaultRepository
import com.khandoba.securedocs.ui.authentication.WelcomeView
import com.khandoba.securedocs.ui.vaults.ClientMainView
import com.khandoba.securedocs.ui.vaults.VaultDetailView
import com.khandoba.securedocs.ui.documents.DocumentPreviewView
import com.khandoba.securedocs.ui.profile.NotificationsSettingsView
import com.khandoba.securedocs.ui.profile.SecuritySettingsView
import com.khandoba.securedocs.ui.profile.AboutView
import com.khandoba.securedocs.ui.security.AntiVaultManagementView
import com.khandoba.securedocs.ui.security.AntiVaultDetailView
import com.khandoba.securedocs.ui.security.CreateAntiVaultView
import com.khandoba.securedocs.viewmodel.AuthenticationViewModel
import com.khandoba.securedocs.viewmodel.DocumentViewModel
import com.khandoba.securedocs.viewmodel.VaultViewModel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.UUID

@Composable
fun ContentView(
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val application = context.applicationContext as KhandobaApplication
    val navController = rememberNavController()
    
    // Initialize Supabase
    val supabaseService = remember {
        SupabaseService().also {
            CoroutineScope(Dispatchers.IO).launch {
                it.configure()
            }
        }
    }
    
    // Initialize repositories
    val userRepository = remember {
        UserRepository(
            userDao = application.database.userDao(),
            supabaseService = supabaseService
        )
    }
    
    val vaultRepository = remember {
        VaultRepository(
            vaultDao = application.database.vaultDao(),
            supabaseService = supabaseService
        )
    }
    
    // Initialize services
    val authService = remember {
        AuthenticationService(
            context = context,
            userRepository = userRepository,
            supabaseService = supabaseService
        )
    }
    
    val vaultService = remember {
        VaultService(vaultRepository)
    }
    
    val encryptionService = remember {
        EncryptionService()
    }
    
    val documentRepository = remember {
        DocumentRepository(
            documentDao = application.database.documentDao(),
            supabaseService = supabaseService
        )
    }
    
            val documentIndexingService = remember { DocumentIndexingService() }
            
            val documentService = remember {
                DocumentService(
                    context = context,
                    documentRepository = documentRepository,
                    supabaseService = supabaseService,
                    encryptionService = encryptionService,
                    documentIndexingService = documentIndexingService
                )
            }
    
    val nomineeRepository = remember {
        com.khandoba.securedocs.data.repository.NomineeRepository(
            nomineeDao = application.database.nomineeDao(),
            supabaseService = supabaseService
        )
    }
    
    val nomineeService = remember {
        com.khandoba.securedocs.service.NomineeService(nomineeRepository)
    }
    
    val threatMonitoringService = remember {
        com.khandoba.securedocs.service.ThreatMonitoringService()
    }
    
    val threatIndexService = remember {
        com.khandoba.securedocs.service.ThreatIndexService(supabaseService).also { service ->
            // Connect SupabaseService real-time updates to ThreatIndexService
            supabaseService.threatIndexUpdateCallback = { vaultId, threatIndex, threatLevel ->
                service.updateThreatIndex(vaultId, threatIndex, threatLevel)
            }
        }
    }
    
    val mlThreatAnalysisService = remember {
        com.khandoba.securedocs.service.MLThreatAnalysisService()
    }
    
    val vaultTransferService = remember {
        com.khandoba.securedocs.service.VaultTransferService(
            vaultRepository = vaultRepository,
            supabaseService = supabaseService,
            threatMonitoringService = threatMonitoringService,
            mlThreatAnalysisService = mlThreatAnalysisService
        )
    }
    
    val antiVaultService = remember {
        com.khandoba.securedocs.service.AntiVaultService(
            supabaseService = supabaseService,
            currentUserID = currentUser?.id ?: UUID.randomUUID() // Will be updated when user is available
        )
    }
    
    // Update antiVaultService when user is available
    LaunchedEffect(currentUser) {
        currentUser?.id?.let { userId ->
            // Recreate service with correct user ID
            // Note: In a real implementation, you might want to make currentUserID mutable
        }
    }
    
    // ViewModels
    val authViewModel: AuthenticationViewModel = viewModel {
        AuthenticationViewModel(authService)
    }
    
    val vaultViewModel: VaultViewModel = viewModel {
        VaultViewModel(vaultService)
    }
    
    val documentViewModel: DocumentViewModel = viewModel {
        DocumentViewModel(documentService)
    }
    
    val nomineeViewModel: com.khandoba.securedocs.viewmodel.NomineeViewModel = viewModel {
        com.khandoba.securedocs.viewmodel.NomineeViewModel(nomineeService)
    }
    
    // Check authentication state
    val isAuthenticated by authViewModel.isAuthenticated.collectAsState()
    val currentUser by authViewModel.currentUser.collectAsState()
    
    LaunchedEffect(currentUser) {
        currentUser?.id?.let { userId ->
            vaultViewModel.configure(userId)
            nomineeViewModel.configure(userId)
            vaultTransferService.configure(userId)
        }
    }
    
    // Navigation
    NavHost(
        navController = navController,
        startDestination = if (isAuthenticated) "client_main" else "welcome"
    ) {
        composable("welcome") {
            WelcomeView(
                authViewModel = authViewModel,
                onSignInSuccess = {
                    navController.navigate("client_main") {
                        popUpTo("welcome") { inclusive = true }
                    }
                }
            )
        }
        
        composable("client_main") {
            ClientMainView(
                vaultViewModel = vaultViewModel,
                authViewModel = authViewModel,
                documentViewModel = documentViewModel,
                onVaultSelected = { vaultId ->
                    navController.navigate("vault_detail/$vaultId")
                },
                onSignOut = {
                    navController.navigate("welcome") {
                        popUpTo("client_main") { inclusive = true }
                    }
                },
                onNavigateToNotifications = {
                    navController.navigate("notifications_settings")
                },
                onNavigateToSecurity = {
                    navController.navigate("security_settings")
                },
                onNavigateToAbout = {
                    navController.navigate("about")
                },
                onNavigateToAntiVaults = {
                    navController.navigate("anti_vault_management")
                }
            )
        }
        
        composable("anti_vault_management") {
            AntiVaultManagementView(
                antiVaultService = antiVaultService,
                vaultService = vaultService,
                onAntiVaultSelected = { antiVaultId ->
                    navController.navigate("anti_vault_detail/$antiVaultId")
                },
                onCreateAntiVault = {
                    navController.navigate("create_anti_vault")
                }
            )
        }
        
        composable(
            route = "anti_vault_detail/{antiVaultId}",
            arguments = listOf(
                androidx.navigation.NavArgument(
                    name = "antiVaultId",
                    builder = {
                        type = androidx.navigation.NavType.StringType
                    }
                )
            )
        ) { backStackEntry ->
            val antiVaultIdString = backStackEntry.arguments?.getString("antiVaultId")
            val antiVaultId = antiVaultIdString?.let { UUID.fromString(it) }
            
            if (antiVaultId != null) {
                AntiVaultDetailView(
                    antiVaultId = antiVaultId,
                    antiVaultService = antiVaultService,
                    onBack = { navController.popBackStack() },
                    onUnlock = { vaultId ->
                        // Navigate to vault detail or refresh
                    }
                )
            }
        }
        
        composable("create_anti_vault") {
            val vaults by vaultViewModel.vaults.collectAsState()
            CreateAntiVaultView(
                antiVaultService = antiVaultService,
                availableVaults = vaults,
                currentUserID = currentUser?.id ?: UUID.randomUUID(),
                onDismiss = { navController.popBackStack() },
                onCreated = { antiVaultId ->
                    navController.popBackStack()
                    navController.navigate("anti_vault_detail/$antiVaultId")
                }
            )
        }
        
        composable(
            route = "vault_detail/{vaultId}",
            arguments = listOf(
                androidx.navigation.NavArgument(
                    name = "vaultId",
                    builder = {
                        type = androidx.navigation.NavType.StringType
                    }
                )
            )
        ) { backStackEntry ->
            val vaultIdString = backStackEntry.arguments?.getString("vaultId")
            val vaultId = vaultIdString?.let { UUID.fromString(it) }
            
            if (vaultId != null) {
                VaultDetailView(
                    vaultId = vaultId,
                    vaultViewModel = vaultViewModel,
                    documentViewModel = documentViewModel,
                    nomineeViewModel = nomineeViewModel,
                    authViewModel = authViewModel,
                    vaultTransferService = vaultTransferService,
                    onBack = { navController.popBackStack() },
                    onNavigateToDocument = { documentId ->
                        navController.navigate("document_preview/$documentId")
                    }
                )
            } else {
                Text("Invalid vault ID")
            }
        }
    }
}
