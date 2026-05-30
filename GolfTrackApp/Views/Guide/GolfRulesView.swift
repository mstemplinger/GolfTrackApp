import SwiftUI

// MARK: - Rules Overview

struct GolfRulesView: View {
    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Regelwerk 2023 – R&A / USGA")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.textSec)
                        Text("Die aktuellen Golfregeln gelten seit dem 1. Januar 2023. Lokale Platzregeln können einzelne Punkte abweichen.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSec)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(AppTheme.card)
                }

                ForEach(GolfRulesContent.categories) { category in
                    Section {
                        NavigationLink {
                            RulesCategoryView(category: category)
                        } label: {
                            RulesCategoryRow(category: category)
                        }
                        .listRowBackground(AppTheme.card)
                    }
                }

                Section {
                    Text("Quelle: R&A Rules of Golf 2023 (r-a.org) · USGA (usga.org)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTer)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(AppTheme.card)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle("Golfregeln 2023")
        }
    }
}

// MARK: - Category Row

private struct RulesCategoryRow: View {
    let category: GolfRulesCategory

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(category.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: category.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(category.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(category.title)
                    .font(.headline)
                Text(category.subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSec)
                    .lineLimit(1)
                Text("\(category.rules.count) Regeln")
                    .font(.caption2)
                    .foregroundStyle(category.color)
                    .fontWeight(.semibold)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Category Detail

struct RulesCategoryView: View {
    let category: GolfRulesCategory

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            List {
                ForEach(category.rules) { rule in
                    Section {
                        NavigationLink {
                            RuleDetailView(rule: rule, color: category.color)
                        } label: {
                            RuleRow(rule: rule, color: category.color)
                        }
                        .listRowBackground(AppTheme.card)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationTitle(category.title)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Rule Row

private struct RuleRow: View {
    let rule: GolfRule
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(rule.title)
                .font(.subheadline.bold())
            Text(rule.ruleNumber)
                .font(.caption)
                .foregroundStyle(color)
                .fontWeight(.semibold)
            HStack(spacing: 8) {
                if rule.penalty != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text("Strafschlag")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                if rule.diagram != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.gold)
                        Text("Abbildung")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.gold)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Rule Detail

struct RuleDetailView: View {
    let rule: GolfRule
    let color: Color

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                // Rule number badge
                HStack {
                    Text(rule.ruleNumber)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(color.opacity(0.15), in: Capsule())
                        .foregroundStyle(color)
                    Spacer()
                }

                // Diagram (if available)
                if let diagram = rule.diagram {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.fill")
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textSec)
                            Text("Abbildung")
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textSec)
                        }
                        diagramView(for: diagram)
                    }
                }

                // Body
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(rule.body.components(separatedBy: "\n\n"), id: \.self) { paragraph in
                        Text(paragraph)
                            .font(.body)
                            .padding(.bottom, 12)
                    }
                }
                .padding()
                .background(AppTheme.cardAlt, in: RoundedRectangle(cornerRadius: 14))

                // Penalty
                if let penalty = rule.penalty {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.title3)
                            .padding(.top, 1)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Strafe")
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textSec)
                            Text(penalty)
                                .font(.subheadline.bold())
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                }

                // Tip
                if let tip = rule.tip {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(AppTheme.gold)
                            .font(.title3)
                            .padding(.top, 1)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Praxis-Tipp")
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textSec)
                            Text(tip)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding()
                    .background(AppTheme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding()
        }
        .navigationTitle(rule.title)
        .navigationBarTitleDisplayMode(.large)
        .background(AppTheme.bg)
    }

    @ViewBuilder
    private func diagramView(for diagram: RuleDiagram) -> some View {
        switch diagram {
        case .teeBox:
            TeeBoxDiagram()
        case .penaltyArea:
            PenaltyAreaDiagram()
        case .bunker:
            BunkerDiagram()
        case .unplayable:
            UnplayableDiagram()
        case .puttingGreen:
            PuttingGreenDiagram()
        case .outOfBounds:
            OutOfBoundsDiagram()
        case .dropProcedure:
            DropProcedureDiagram()
        case .ballSearch:
            BallSearchDiagram()
        case .scoringTable:
            ScoringTableDiagram()
        case .matchplay:
            MatchplayDiagram()
        }
    }
}
