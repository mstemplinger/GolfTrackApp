package app.golftrack.feature.guide

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import app.golftrack.ui.common.AppScaffold
import app.golftrack.ui.theme.AppTheme

// MARK: - Regelübersicht

/** Inhalt von GolfRulesView – als Tab (ohne Zurück) oder als Unterseite. */
@Composable
fun GolfRulesScreen(nav: NavController, onBack: (() -> Unit)?) {
    AppScaffold("Golfregeln 2023", onBack = onBack) { m ->
        LazyColumn(m.background(AppTheme.bg)) {
            item {
                ReadableWidth {
                    Column(
                        Modifier.padding(horizontal = 16.dp, vertical = 8.dp).fillMaxWidth()
                            .rounded(AppTheme.card, 12.dp).padding(horizontal = 16.dp, vertical = 14.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        T("Regelwerk 2023 – R&A / USGA", IosFont.caption, AppTheme.textSec, FontWeight.Bold)
                        T(
                            "Die aktuellen Golfregeln gelten seit dem 1. Januar 2023. Lokale Platzregeln können einzelne Punkte abweichen.",
                            IosFont.subheadline, AppTheme.textSec,
                        )
                    }
                }
            }
            itemsIndexed(GolfRulesContent.categories) { i, category ->
                ReadableWidth {
                    Box(Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
                        ListCardRow(onClick = { nav.navigate(GuideNav.rulesCategory(i)) }) {
                            RulesCategoryRow(category, Modifier)
                        }
                    }
                }
            }
            item {
                ReadableWidth {
                    T(
                        "Quelle: R&A Rules of Golf 2023 (r-a.org) · USGA (usga.org)",
                        IosFont.caption, AppTheme.textTer, align = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp).fillMaxWidth()
                            .rounded(AppTheme.card, 12.dp).padding(14.dp),
                    )
                }
                Spacer(Modifier.height(24.dp))
            }
        }
    }
}

@Composable
private fun RulesCategoryRow(category: GolfRulesCategory, modifier: Modifier) {
    Row(modifier.padding(vertical = 4.dp), horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically) {
        IconTile(category.icon, category.color, iconSize = 22.dp)
        Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
            T(category.title, IosFont.headline, weight = FontWeight.SemiBold)
            T(category.subtitle, IosFont.caption, AppTheme.textSec, maxLines = 1)
            T("${category.rules.size} Regeln", IosFont.caption2, category.color, FontWeight.SemiBold)
        }
    }
}

// MARK: - Kategorie

@Composable
fun RulesCategoryScreen(nav: NavController, categoryIndex: Int) {
    val category = GolfRulesContent.categories.getOrNull(categoryIndex) ?: return
    AppScaffold(category.title, onBack = { nav.popBackStack() }) { m ->
        LazyColumn(m.background(AppTheme.bg)) {
            itemsIndexed(category.rules) { i, rule ->
                ReadableWidth {
                    Box(Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
                        ListCardRow(onClick = { nav.navigate(GuideNav.rule(categoryIndex, i)) }) {
                            RuleRow(rule, category.color, Modifier)
                        }
                    }
                }
            }
            item { Spacer(Modifier.height(24.dp)) }
        }
    }
}

@Composable
private fun RuleRow(rule: GolfRule, color: Color, modifier: Modifier) {
    Column(modifier.padding(vertical = 2.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        T(rule.title, IosFont.subheadline, weight = FontWeight.Bold)
        T(rule.ruleNumber, IosFont.caption, color, FontWeight.SemiBold)
        if (rule.penalty != null || rule.diagram != null) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                if (rule.penalty != null) {
                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
                        SfIcon("exclamationmark.triangle.fill", IosColor.orange, 12.dp)
                        T("Strafschlag", IosFont.caption2, IosColor.orange)
                    }
                }
                if (rule.diagram != null) {
                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp), verticalAlignment = Alignment.CenterVertically) {
                        SfIcon("photo", AppTheme.gold, 12.dp)
                        T("Abbildung", IosFont.caption2, AppTheme.gold)
                    }
                }
            }
        }
    }
}

// MARK: - Regel im Detail

@Composable
fun RuleDetailScreen(nav: NavController, categoryIndex: Int, ruleIndex: Int) {
    val category = GolfRulesContent.categories.getOrNull(categoryIndex) ?: return
    val rule = category.rules.getOrNull(ruleIndex) ?: return
    val color = category.color
    AppScaffold(rule.title, onBack = { nav.popBackStack() }) { m ->
        Column(m.background(AppTheme.bg).verticalScroll(rememberScrollState())) {
            ReadableWidth {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                    // Regelnummer
                    T(
                        rule.ruleNumber, IosFont.caption, color, FontWeight.Bold,
                        modifier = Modifier.background(color.copy(alpha = 0.15f), RoundedCornerShape(50))
                            .padding(horizontal = 10.dp, vertical = 5.dp),
                    )

                    // Abbildung
                    rule.diagram?.let { diagram ->
                        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                                SfIcon("photo.fill", AppTheme.textSec, 13.dp)
                                T("Abbildung", IosFont.caption, AppTheme.textSec, FontWeight.Bold)
                            }
                            RuleDiagramView(diagram)
                        }
                    }

                    // Text
                    Column(Modifier.fillMaxWidth().rounded(AppTheme.cardAlt).padding(16.dp)) {
                        rule.body.split("\n\n").forEach { paragraph ->
                            T(paragraph, IosFont.body, modifier = Modifier.padding(bottom = 12.dp))
                        }
                    }

                    // Strafe
                    rule.penalty?.let { penalty ->
                        Row(
                            Modifier.fillMaxWidth().rounded(IosColor.orange.copy(alpha = 0.1f)).padding(16.dp),
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            SfIcon("exclamationmark.triangle.fill", IosColor.orange, 22.dp, Modifier.padding(top = 1.dp))
                            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                T("Strafe", IosFont.caption, AppTheme.textSec, FontWeight.Bold)
                                T(penalty, IosFont.subheadline, IosColor.orange, FontWeight.Bold)
                            }
                        }
                    }

                    // Praxis-Tipp
                    rule.tip?.let { tip ->
                        Row(
                            Modifier.fillMaxWidth().rounded(AppTheme.gold.copy(alpha = 0.12f)).padding(16.dp),
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            SfIcon("lightbulb.fill", AppTheme.gold, 22.dp, Modifier.padding(top = 1.dp))
                            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                                T("Praxis-Tipp", IosFont.caption, AppTheme.textSec, FontWeight.Bold)
                                T(tip, IosFont.subheadline)
                            }
                        }
                    }
                    Spacer(Modifier.height(16.dp))
                }
            }
        }
    }
}

@Composable
fun RuleDiagramView(diagram: RuleDiagram) {
    when (diagram) {
        RuleDiagram.teeBox -> TeeBoxDiagram()
        RuleDiagram.penaltyArea -> PenaltyAreaDiagram()
        RuleDiagram.bunker -> BunkerDiagram()
        RuleDiagram.unplayable -> UnplayableDiagram()
        RuleDiagram.puttingGreen -> PuttingGreenDiagram()
        RuleDiagram.outOfBounds -> OutOfBoundsDiagram()
        RuleDiagram.dropProcedure -> DropProcedureDiagram()
        RuleDiagram.ballSearch -> BallSearchDiagram()
        RuleDiagram.scoringTable -> ScoringTableDiagram()
        RuleDiagram.matchplay -> MatchplayDiagram()
    }
}
