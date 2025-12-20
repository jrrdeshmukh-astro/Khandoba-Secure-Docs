package com.khandoba.securedocs.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import com.khandoba.securedocs.ui.authentication.WelcomeView
import com.khandoba.securedocs.ui.vaults.VaultListView
import com.khandoba.securedocs.ui.vaults.ClientMainView

sealed class Screen(val route: String) {
    object Welcome : Screen("welcome")
    object VaultList : Screen("vaults")
    object ClientMain : Screen("client_main")
    object AntiVaultManagement : Screen("anti_vault_management")
    object AntiVaultDetail : Screen("anti_vault_detail/{antiVaultId}") {
        fun createRoute(antiVaultId: String) = "anti_vault_detail/$antiVaultId"
    }
    object CreateAntiVault : Screen("create_anti_vault")
}

@Composable
fun NavGraph(
    navController: NavHostController,
    startDestination: String = Screen.Welcome.route
) {
    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        composable(Screen.Welcome.route) {
            WelcomeView(
                onSignInSuccess = {
                    navController.navigate(Screen.ClientMain.route) {
                        popUpTo(Screen.Welcome.route) { inclusive = true }
                    }
                }
            )
        }
        
        composable(Screen.ClientMain.route) {
            ClientMainView()
        }
        
        composable(Screen.VaultList.route) {
            VaultListView(
                onVaultSelected = { vaultId ->
                    // Navigate to vault detail
                }
            )
        }
    }
}

