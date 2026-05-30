import SwiftUI
import SwiftData

struct AddCourseView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var location = ""
    @State private var numberOfHoles = 18
    @State private var parValues: [Int] = Course.defaultPars(for: 18)
    @State private var courseRating: Double = 72.0
    @State private var slopeRating: Int = 113

    var body: some View {
        NavigationStack {
            Form {
                Section("Platzinformationen") {
                    TextField("Platzname *", text: $name)
                    TextField("Ort (optional)", text: $location)
                    Picker("Löcher", selection: $numberOfHoles) {
                        Text("9 Löcher").tag(9)
                        Text("18 Löcher").tag(18)
                    }
                    .onChange(of: numberOfHoles) { _, new in
                        parValues = Course.defaultPars(for: new)
                    }
                }

                Section {
                    HStack {
                        Text("Course Rating (CR)")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("72.0", value: $courseRating, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                    }
                    HStack {
                        Text("Slope Rating")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Stepper("\(slopeRating)", value: $slopeRating, in: 55...155)
                    }
                } header: {
                    Text("Handicap-Daten")
                } footer: {
                    Text("CR und Slope stehen auf der Scorekarte oder der Club-Website. Standard: CR 72.0 / Slope 113.")
                        .font(.caption)
                }

                Section("Par pro Loch") {
                    ForEach(0..<numberOfHoles, id: \.self) { i in
                        HStack {
                            Text("Loch \(i + 1)").foregroundStyle(.secondary)
                            Spacer()
                            Stepper(
                                "\(parValues[i])",
                                value: Binding(
                                    get: { parValues[i] },
                                    set: { parValues[i] = $0 }
                                ),
                                in: 3...5
                            )
                        }
                    }
                }
            }
            .navigationTitle("Neuer Platz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let course = Course(
            name: name.trimmingCharacters(in: .whitespaces),
            location: location.trimmingCharacters(in: .whitespaces),
            numberOfHoles: numberOfHoles,
            parValues: parValues,
            courseRating: courseRating,
            slopeRating: slopeRating
        )
        context.insert(course)
        dismiss()
    }
}
