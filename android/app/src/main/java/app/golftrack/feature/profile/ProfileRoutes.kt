package app.golftrack.feature.profile

import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.navigation.NavController
import androidx.navigation.NavGraphBuilder
import androidx.navigation.compose.composable
import app.golftrack.ui.common.Routes
import app.golftrack.ui.onboarding.LaunchKeys

/** Eigene Unterseiten des Profils (nicht in `Routes`, nur hier verlinkt). */
object ProfileExtraRoutes {
    const val BAG = "profile/clubbag/{bagId}"
    fun bag(id: String) = "profile/clubbag/${Uri.encode(id)}"
    const val ADD_CLUB = "profile/clubbag/{bagId}/add"
    fun addClub(id: String) = "profile/clubbag/${Uri.encode(id)}/add"
    const val ADD_DOCUMENT = "profile/documents/add"
    const val DOCUMENT = "profile/documents/view/{docId}"
    fun document(id: String) = "profile/documents/view/${Uri.encode(id)}"
    const val TRACKING = "profile/tracking"
    const val NOTIFICATIONS = "profile/notifications"
    const val PRIVACY = "profile/privacy"
    const val IMPRINT = "profile/imprint"
}

@Composable
fun ProfileTab(nav: NavController) = ProfileScreen(nav)

fun NavGraphBuilder.profileRoutes(nav: NavController) {
    composable(Routes.CLUB_BAG) { BagManagerScreen(nav) }
    composable(ProfileExtraRoutes.BAG) { ClubBagScreen(nav, it.arguments?.getString("bagId").orEmpty()) }
    composable(ProfileExtraRoutes.ADD_CLUB) { AddClubScreen(nav, it.arguments?.getString("bagId").orEmpty()) }
    composable(Routes.SETTINGS) { SettingsScreen(nav) }
    composable(Routes.DOCUMENTS) { DocumentsScreen(nav) }
    composable(ProfileExtraRoutes.ADD_DOCUMENT) { AddDocumentScreen(nav) }
    composable(ProfileExtraRoutes.DOCUMENT) { DocumentDetailScreen(nav, it.arguments?.getString("docId").orEmpty()) }
    composable(Routes.HELP) { HelpScreen(nav) }
    composable(ProfileExtraRoutes.TRACKING) { TrackingSettingsScreen(nav) }
    composable(ProfileExtraRoutes.NOTIFICATIONS) { NotificationSettingsScreen(nav) }
    composable(ProfileExtraRoutes.PRIVACY) { PrivacyScreen(nav) }
    composable(ProfileExtraRoutes.IMPRINT) { ImprintScreen(nav) }
    composable(LaunchKeys.WHATS_NEW_ROUTE) { WhatsNewScreen(nav) }
}
