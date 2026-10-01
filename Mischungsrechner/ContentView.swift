//
//  ContentView.swift
//  Mischungsrechner
//
//  Copyright © 2025 Marvin Mieth. All rights reserved.
//

import SwiftUI
import Observation

// MARK: - Localization

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    func localized(_ args: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: args)
    }

    /// Parses user input. The German decimal pad emits a comma, so accept both separators.
    var number: Double? {
        Double(trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
    }
}

// MARK: - Data Models

struct ProductPreset: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var nameKey: String?
    var part1: String
    var part2: String
    var category: String
    var categoryKey: String?
    var isCustom: Bool = false

    var localizedName: String {
        nameKey?.localized ?? name
    }

    var ratio: String {
        "\(part1):\(part2)"
    }
}

struct CalculationHistory: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var part1: String
    var part2: String
    var bottleSize: String
    var useOunces: Bool
    var result1: Int
    var result2: Int
    var productName: String?
    var mode: CalculatorMode?
    var productAmount: String?
}

enum CalculatorMode: String, CaseIterable, Codable {
    case normal
    case reverse

    var localizedName: String {
        switch self {
        case .normal: return "mode.normal".localized
        case .reverse: return "mode.reverse".localized
        }
    }
}

// MARK: - Storage

/// Decodes persisted data once at launch instead of on every view update.
@MainActor
@Observable
final class AppData {
    private(set) var customPresets: [ProductPreset]
    private(set) var history: [CalculationHistory]

    private static let presetsKey = "customPresets"
    private static let historyKey = "calculationHistory"
    private static let historyLimit = 50

    init() {
        customPresets = Self.load(Self.presetsKey)
        history = Self.load(Self.historyKey)
    }

    func addPreset(_ preset: ProductPreset) {
        customPresets.append(preset)
        Self.save(customPresets, Self.presetsKey)
    }

    func deletePreset(_ preset: ProductPreset) {
        customPresets.removeAll { $0.id == preset.id }
        Self.save(customPresets, Self.presetsKey)
    }

    func addHistory(_ entry: CalculationHistory) {
        history.insert(entry, at: 0)
        if history.count > Self.historyLimit {
            history.removeLast(history.count - Self.historyLimit)
        }
        Self.save(history, Self.historyKey)
    }

    func deleteHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        Self.save(history, Self.historyKey)
    }

    func clearHistory() {
        history.removeAll()
        Self.save(history, Self.historyKey)
    }

    private static func load<T: Decodable>(_ key: String) -> [T] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([T].self, from: data)) ?? []
    }

    private static func save<T: Encodable>(_ value: T, _ key: String) {
        UserDefaults.standard.set(try? JSONEncoder().encode(value), forKey: key)
    }
}

// MARK: - Main View

struct ContentView: View {
    @Environment(AppData.self) private var data

    @AppStorage("calculatorMode") private var mode: CalculatorMode = .normal
    @AppStorage("useOunces") private var useOunces = false
    @State private var part1 = "1"
    @State private var part2 = "10"
    @State private var bottleSize = "500"
    @State private var productAmount = "50"
    @State private var pricePerLiter = ""
    @State private var selectedPreset: ProductPreset?
    @State private var showingHistory = false
    @State private var lastSavedKey: String?
    @State private var easterEgg: EasterEgg?

    @FocusState private var focusedField: Field?

    private enum Field {
        case part1, part2, amount, price
    }

    private struct EasterEgg {
        let title: String
        let message: String
    }

    private static let ratioPresets = ["1:1", "1:2", "1:4", "1:5", "1:10", "1:15", "1:20", "1:50", "1:100", "1:500"]
    private static let mlPresets = ["100", "200", "250", "500", "750", "1000"]
    private static let ozPresets = ["4", "8", "16", "24", "32"]

    private var unitLabel: String {
        useOunces ? "fl oz" : "ml"
    }

    private var result: (product: Double, water: Double)? {
        guard let p1 = part1.number, let p2 = part2.number, p1 > 0, p2 > 0 else { return nil }

        switch mode {
        case .normal:
            guard let total = bottleSize.number, total > 0 else { return nil }
            return (total * p1 / (p1 + p2), total * p2 / (p1 + p2))
        case .reverse:
            guard let product = productAmount.number, product > 0 else { return nil }
            return (product, product / p1 * p2)
        }
    }

    private var costPerFill: Double? {
        guard let price = pricePerLiter.number, price > 0, let result else { return nil }
        let liters = useOunces ? result.product * 0.0295735 : result.product / 1000
        return liters * price
    }

    /// Identifies the current inputs so "Save" can show that this exact calculation is already saved.
    private var calculationKey: String {
        [mode.rawValue, part1, part2, bottleSize, productAmount, String(useOunces), selectedPreset?.id.uuidString ?? ""]
            .joined(separator: "|")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Modus", selection: $mode) {
                        ForEach(CalculatorMode.allCases, id: \.self) { mode in
                            Text(mode.localizedName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    NavigationLink {
                        PresetsView(selectedPreset: selectedPreset, part1: part1, part2: part2) { preset in
                            part1 = preset.part1
                            part2 = preset.part2
                            selectedPreset = preset
                        }
                    } label: {
                        Label(selectedPreset?.localizedName ?? "product.select".localized, systemImage: "flask")
                    }
                }

                ratioSection
                amountSection
                resultSection
                costSection
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("app.title".localized)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("history.title".localized, systemImage: "clock.arrow.circlepath") {
                        showingHistory = true
                    }
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("button.done".localized) {
                        focusedField = nil
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView { item in
                    mode = item.mode ?? .normal
                    part1 = item.part1
                    part2 = item.part2
                    bottleSize = item.bottleSize
                    productAmount = item.productAmount ?? productAmount
                    useOunces = item.useOunces
                    selectedPreset = nil
                    showingHistory = false
                }
            }
        }
        .sensoryFeedback(.selection, trigger: mode)
        .sensoryFeedback(.success, trigger: lastSavedKey) { _, new in new != nil }
        .onChange(of: bottleSize) { _, newValue in
            checkAmountEasterEggs(newValue)
        }
        .onChange(of: "\(part1):\(part2)") { _, newValue in
            if selectedPreset?.ratio != newValue {
                selectedPreset = nil
            }
            checkRatioEasterEggs(newValue)
        }
        .alert(
            easterEgg?.title ?? "",
            isPresented: Binding(get: { easterEgg != nil }, set: { if !$0 { easterEgg = nil } }),
            presenting: easterEgg
        ) { _ in
            Button("OK") { }
        } message: { egg in
            Text(egg.message)
        }
    }

    // MARK: - Sections

    private var ratioSection: some View {
        Section("section.ratio".localized) {
            HStack(spacing: 12) {
                TextField("1", text: $part1)
                    .focused($focusedField, equals: .part1)
                Text(":")
                    .foregroundStyle(.tertiary)
                TextField("10", text: $part2)
                    .focused($focusedField, equals: .part2)
            }
            .font(.system(.title, design: .rounded, weight: .semibold))
            .multilineTextAlignment(.center)
            .keyboardType(.decimalPad)
            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }

            Picker("ratio.common".localized, selection: presetBinding(
                current: "\(part1):\(part2)",
                options: Self.ratioPresets
            ) { preset in
                let parts = preset.split(separator: ":")
                part1 = String(parts[0])
                part2 = String(parts[1])
            }) {
                Text("ratio.custom".localized).tag("")
                ForEach(Self.ratioPresets, id: \.self) { Text($0).tag($0) }
            }
        }
    }

    private var amountSection: some View {
        Section {
            HStack {
                TextField(
                    mode == .normal ? "500" : "50",
                    text: mode == .normal ? $bottleSize : $productAmount
                )
                .font(.system(.title, design: .rounded, weight: .semibold))
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .amount)

                Text(unitLabel)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }

            if mode == .normal {
                let sizes = useOunces ? Self.ozPresets : Self.mlPresets
                Picker("amount.common".localized, selection: presetBinding(current: bottleSize, options: sizes) {
                    bottleSize = $0
                }) {
                    Text("ratio.custom".localized).tag("")
                    ForEach(sizes, id: \.self) { Text("\($0) \(unitLabel)").tag($0) }
                }
            }

            Picker("unit.title".localized, selection: $useOunces) {
                Text("ml").tag(false)
                Text("fl oz").tag(true)
            }
        } header: {
            Text(mode == .normal ? "section.totalAmount".localized : "section.productAmount".localized)
        } footer: {
            if mode == .reverse {
                Text("reverse.hint".localized)
            }
        }
    }

    private var resultSection: some View {
        Section("section.result".localized) {
            if let result {
                HStack(alignment: .top) {
                    resultColumn("result.product".localized, value: result.product)
                    Divider()
                    resultColumn("result.water".localized, value: result.water)
                }
                .padding(.vertical, 8)
                .animation(.snappy, value: result.product)
                .animation(.snappy, value: result.water)

                ShareLink(item: shareText(result)) {
                    Label("button.share".localized, systemImage: "square.and.arrow.up")
                }

                let isSaved = lastSavedKey == calculationKey
                Button {
                    saveToHistory(result)
                } label: {
                    Label(
                        isSaved ? "alert.saved".localized : "button.saveHistory".localized,
                        systemImage: isSaved ? "checkmark" : "bookmark"
                    )
                    .contentTransition(.symbolEffect(.replace))
                }
                .disabled(isSaved)
            } else {
                Text("result.invalid".localized)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var costSection: some View {
        Section("section.costCalculator".localized) {
            LabeledContent("cost.pricePerLiter".localized) {
                HStack(spacing: 4) {
                    TextField("0,00", text: $pricePerLiter)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedField, equals: .price)
                    Text("€/L")
                        .foregroundStyle(.secondary)
                }
            }

            if let cost = costPerFill {
                LabeledContent("cost.perFill".localized) {
                    Text(cost, format: .currency(code: "EUR"))
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText(value: cost))
                }
            }
        }
    }

    private func resultColumn(_ title: String, value: Double) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(format(value))
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
                .contentTransition(.numericText(value: value))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(unitLabel)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    /// Selection for a "common values" menu: shows the matching option, or "Custom" when the input is free-form.
    private func presetBinding(current: String, options: [String], apply: @escaping (String) -> Void) -> Binding<String> {
        Binding(
            get: { options.contains(current) ? current : "" },
            set: { if !$0.isEmpty { apply($0) } }
        )
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(useOunces ? 0...1 : 0...0)))
    }

    private func shareText(_ result: (product: Double, water: Double)) -> String {
        var lines = ["\("share.ratio".localized) \(part1):\(part2)"]
        if let preset = selectedPreset {
            lines.append(preset.localizedName)
        }
        lines.append("")
        lines.append("\("result.product".localized): \(format(result.product)) \(unitLabel)")
        lines.append("\("result.water".localized): \(format(result.water)) \(unitLabel)")
        if mode == .normal {
            lines.append("\("share.totalAmount".localized): \(bottleSize) \(unitLabel)")
        }
        if let cost = costPerFill {
            lines.append("\("share.cost".localized): \(cost.formatted(.currency(code: "EUR")))")
        }
        return lines.joined(separator: "\n")
    }

    private func saveToHistory(_ result: (product: Double, water: Double)) {
        data.addHistory(CalculationHistory(
            date: .now,
            part1: part1,
            part2: part2,
            bottleSize: bottleSize,
            useOunces: useOunces,
            result1: Int(result.product.rounded()),
            result2: Int(result.water.rounded()),
            productName: selectedPreset?.localizedName,
            mode: mode,
            productAmount: productAmount
        ))
        withAnimation {
            lastSavedKey = calculationKey
        }
    }

    // MARK: - Easter Eggs

    private func checkAmountEasterEggs(_ value: String) {
        guard let intValue = Int(value) else { return }

        switch intValue {
        case 2014: easterEgg = EasterEgg(title: "🎉", message: "easter.coupon".localized)
        case 69: easterEgg = EasterEgg(title: "😏", message: "easter.nice".localized)
        case 420: easterEgg = EasterEgg(title: "🌿", message: "easter.420".localized)
        case 1337: easterEgg = EasterEgg(title: "🤓", message: "easter.leet".localized)
        case 9999: easterEgg = EasterEgg(title: "📱", message: "easter.over9000".localized)
        case 1_000_000...: easterEgg = EasterEgg(title: "🐋", message: "easter.whale".localized(intValue / 1000))
        default: break
        }
    }

    private func checkRatioEasterEggs(_ ratio: String) {
        switch ratio {
        case "42:42": easterEgg = EasterEgg(title: "🤖", message: "easter.42".localized)
        case "3:14": easterEgg = EasterEgg(title: "🥧", message: "easter.pi".localized)
        case "13:37": easterEgg = EasterEgg(title: "👨‍💻", message: "easter.leetRatio".localized)
        default: break
        }
    }
}

// MARK: - Presets View

struct PresetsView: View {
    @Environment(AppData.self) private var data
    @Environment(\.dismiss) private var dismiss
    let selectedPreset: ProductPreset?
    let part1: String
    let part2: String
    let onSelect: (ProductPreset) -> Void

    @State private var searchText = ""
    @State private var showingSave = false

    private static let defaultPresets: [ProductPreset] = [
        // APC
        ProductPreset(name: "APC leicht", nameKey: "preset.apcLight", part1: "1", part2: "20", category: "APC", categoryKey: "category.apc"),
        ProductPreset(name: "APC mittel", nameKey: "preset.apcMedium", part1: "1", part2: "10", category: "APC", categoryKey: "category.apc"),
        ProductPreset(name: "APC stark", nameKey: "preset.apcStrong", part1: "1", part2: "4", category: "APC", categoryKey: "category.apc"),

        // Glass
        ProductPreset(name: "Glasreiniger", nameKey: "preset.glassCleaner", part1: "1", part2: "4", category: "Glas", categoryKey: "category.glass"),
        ProductPreset(name: "Glasreiniger stark", nameKey: "preset.glassCleanerStrong", part1: "1", part2: "2", category: "Glas", categoryKey: "category.glass"),

        // Detailer
        ProductPreset(name: "Quick Detailer", nameKey: "preset.quickDetailer", part1: "1", part2: "16", category: "Detailer", categoryKey: "category.detailer"),
        ProductPreset(name: "Sprühversiegelung", nameKey: "preset.spraySealant", part1: "1", part2: "8", category: "Detailer", categoryKey: "category.detailer"),

        // Interior
        ProductPreset(name: "Innenraumreiniger leicht", nameKey: "preset.interiorLight", part1: "1", part2: "10", category: "Innenraum", categoryKey: "category.interior"),
        ProductPreset(name: "Innenraumreiniger stark", nameKey: "preset.interiorStrong", part1: "1", part2: "4", category: "Innenraum", categoryKey: "category.interior"),
        ProductPreset(name: "Lederreiniger", nameKey: "preset.leatherCleaner", part1: "1", part2: "5", category: "Innenraum", categoryKey: "category.interior"),

        // Wheels
        ProductPreset(name: "Felgenreiniger leicht", nameKey: "preset.wheelCleanerLight", part1: "1", part2: "5", category: "Felgen", categoryKey: "category.wheels"),
        ProductPreset(name: "Felgenreiniger stark", nameKey: "preset.wheelCleanerStrong", part1: "1", part2: "1", category: "Felgen", categoryKey: "category.wheels"),

        // Wash
        ProductPreset(name: "Autoshampoo", nameKey: "preset.carShampoo", part1: "1", part2: "500", category: "Wäsche", categoryKey: "category.wash"),
        ProductPreset(name: "Snow Foam leicht", nameKey: "preset.snowFoamLight", part1: "1", part2: "20", category: "Wäsche", categoryKey: "category.wash"),
        ProductPreset(name: "Snow Foam stark", nameKey: "preset.snowFoamStrong", part1: "1", part2: "10", category: "Wäsche", categoryKey: "category.wash"),

        // Other
        ProductPreset(name: "Insektenentferner", nameKey: "preset.bugRemover", part1: "1", part2: "4", category: "Sonstiges", categoryKey: "category.other"),
        ProductPreset(name: "Teerentferner", nameKey: "preset.tarRemover", part1: "1", part2: "1", category: "Sonstiges", categoryKey: "category.other"),
        ProductPreset(name: "Iron Remover", nameKey: "preset.ironRemover", part1: "1", part2: "1", category: "Sonstiges", categoryKey: "category.other"),
    ]

    private static let categoryKeys = ["category.apc", "category.glass", "category.detailer", "category.interior", "category.wheels", "category.wash", "category.other"]

    private var groupedPresets: [(String, [ProductPreset])] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        let matches: (ProductPreset) -> Bool = { query.isEmpty || $0.localizedName.localizedStandardContains(query) }

        var result: [(String, [ProductPreset])] = []
        let custom = data.customPresets.filter(matches)
        if !custom.isEmpty {
            result.append(("presets.custom".localized, custom))
        }
        for key in Self.categoryKeys {
            let presets = Self.defaultPresets.filter { $0.categoryKey == key && matches($0) }
            if !presets.isEmpty {
                result.append((key.localized, presets))
            }
        }
        return result
    }

    var body: some View {
        let groups = groupedPresets
        List {
            ForEach(groups, id: \.0) { category, presets in
                Section(category) {
                    ForEach(presets) { preset in
                        Button {
                            onSelect(preset)
                            dismiss()
                        } label: {
                            LabeledContent {
                                if selectedPreset?.id == preset.id {
                                    Image(systemName: "checkmark")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.tint)
                                }
                            } label: {
                                Text(preset.localizedName)
                                Text(preset.ratio)
                                    .monospacedDigit()
                            }
                        }
                        .tint(.primary)
                        .swipeActions {
                            if preset.isCustom {
                                Button("button.delete".localized, systemImage: "trash", role: .destructive) {
                                    data.deletePreset(preset)
                                }
                            }
                        }
                    }
                }
            }
        }
        .overlay {
            if groups.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("presets.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("presets.saveCurrent".localized, systemImage: "plus") {
                    showingSave = true
                }
            }
        }
        .sheet(isPresented: $showingSave) {
            SavePresetView(part1: part1, part2: part2) { name in
                let preset = ProductPreset(
                    name: name,
                    part1: part1,
                    part2: part2,
                    category: "presets.custom".localized,
                    isCustom: true
                )
                data.addPreset(preset)
                onSelect(preset)
                dismiss()
            }
        }
    }
}

// MARK: - Save Preset View

struct SavePresetView: View {
    @Environment(\.dismiss) private var dismiss
    let part1: String
    let part2: String
    let onSave: (String) -> Void

    @State private var name = ""
    @FocusState private var isFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("save.name".localized, text: $name)
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit(save)

                    LabeledContent("section.ratio".localized, value: "\(part1):\(part2)")
                }
            }
            .navigationTitle("save.newProduct".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.cancel".localized) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("button.save".localized, action: save)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        onSave(trimmedName)
        dismiss()
    }
}

// MARK: - History View

struct HistoryView: View {
    @Environment(AppData.self) private var data
    @Environment(\.dismiss) private var dismiss
    let onSelect: (CalculationHistory) -> Void

    @State private var showingClearConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(data.history) { item in
                    Button {
                        onSelect(item)
                    } label: {
                        LabeledContent {
                            Text(item.date, format: .dateTime.day().month().hour().minute())
                                .font(.footnote)
                        } label: {
                            Text(item.productName ?? "\(item.part1):\(item.part2)")
                            Text("\(item.part1):\(item.part2) · \(item.result1) + \(item.result2) \(item.useOunces ? "fl oz" : "ml")")
                                .monospacedDigit()
                        }
                    }
                    .tint(.primary)
                }
                .onDelete { data.deleteHistory(at: $0) }
            }
            .overlay {
                if data.history.isEmpty {
                    ContentUnavailableView(
                        "history.empty".localized,
                        systemImage: "clock.arrow.circlepath",
                        description: Text("history.emptyDescription".localized)
                    )
                }
            }
            .navigationTitle("history.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !data.history.isEmpty {
                        Button("history.clear".localized, role: .destructive) {
                            showingClearConfirmation = true
                        }
                        .confirmationDialog(
                            "history.clearConfirm".localized,
                            isPresented: $showingClearConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("history.clear".localized, role: .destructive) {
                                data.clearHistory()
                            }
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("button.done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppData())
}
