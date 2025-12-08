//
//  ContentView.swift
//  Mischungsrechner
//
//  Copyright © 2025 Marvin Mieth. All rights reserved.
//

import SwiftUI

// MARK: - Localization

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    func localized(_ args: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: args)
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

    var localizedCategory: String {
        categoryKey?.localized ?? category
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
}

enum CalculatorMode: String, CaseIterable {
    case normal
    case reverse

    var localizedName: String {
        switch self {
        case .normal: return "mode.normal".localized
        case .reverse: return "mode.reverse".localized
        }
    }
}

// MARK: - Main View

struct ContentView: View {
    @State private var part1: String = "1"
    @State private var part2: String = "1"
    @State private var bottleSize: String = "100"
    @State private var productAmount: String = "50"
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var logoTapCount = 0
    @State private var showingSecretMode = false
    @State private var useOunces = false
    @State private var showConfetti = false
    @State private var calculatorMode: CalculatorMode = .normal
    @State private var showingPresets = false
    @State private var showingSavePreset = false
    @State private var showingHistory = false
    @State private var showingCostCalculator = false
    @State private var selectedPreset: ProductPreset?
    @State private var customPresetName = ""
    @State private var pricePerLiter: String = ""

    @AppStorage("customPresets") private var customPresetsData: Data = Data()
    @AppStorage("calculationHistory") private var historyData: Data = Data()

    @FocusState private var focusedField: Field?

    enum Field {
        case part1, part2, bottleSize, productAmount, presetName, price
    }

    private var unitLabel: String {
        useOunces ? "fl oz" : "ml"
    }

    private var customPresets: [ProductPreset] {
        get {
            (try? JSONDecoder().decode([ProductPreset].self, from: customPresetsData)) ?? []
        }
        set {
            customPresetsData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    private var history: [CalculationHistory] {
        get {
            (try? JSONDecoder().decode([CalculationHistory].self, from: historyData)) ?? []
        }
        set {
            historyData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    private var calculatedResult: (part1: Int, part2: Int)? {
        guard let p1 = Double(part1),
              let p2 = Double(part2),
              p1 > 0, p2 > 0 else {
            return nil
        }

        if calculatorMode == .normal {
            guard let bottle = Double(bottleSize), bottle > 0 else { return nil }
            let totalParts = p1 + p2
            let partPerUnit = bottle / totalParts
            return (Int((p1 * partPerUnit).rounded()), Int((p2 * partPerUnit).rounded()))
        } else {
            guard let product = Double(productAmount), product > 0 else { return nil }
            let waterAmount = (product / p1) * p2
            return (Int(product.rounded()), Int(waterAmount.rounded()))
        }
    }

    private var costPerBottle: Double? {
        guard let price = Double(pricePerLiter),
              let result = calculatedResult,
              price > 0 else { return nil }
        let productMl = Double(result.part1)
        return (productMl / 1000.0) * price
    }

    var body: some View {
        NavigationStack {
            Form {
                // Mode Picker
                Section {
                    Picker("Modus", selection: $calculatorMode) {
                        ForEach(CalculatorMode.allCases, id: \.self) { mode in
                            Text(mode.localizedName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Product Presets
                Section {
                    Button {
                        haptic()
                        showingPresets = true
                    } label: {
                        HStack {
                            Image(systemName: "flask")
                            Text(selectedPreset?.localizedName ?? "product.select".localized)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text("section.product".localized)
                }

                // Ratio Section
                Section("section.ratio".localized) {
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            TextField("1", text: $part1)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .font(.system(.title, design: .rounded, weight: .medium))
                                .focused($focusedField, equals: .part1)

                            Text(":")
                                .font(.title)
                                .foregroundStyle(.tertiary)

                            TextField("1", text: $part2)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .font(.system(.title, design: .rounded, weight: .medium))
                                .focused($focusedField, equals: .part2)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ratioPresets, id: \.self) { preset in
                                    ChipButton(
                                        title: preset,
                                        isSelected: "\(part1):\(part2)" == preset
                                    ) {
                                        let parts = preset.split(separator: ":")
                                        part1 = String(parts[0])
                                        part2 = String(parts[1])
                                        selectedPreset = nil
                                        haptic()
                                        checkRatioEasterEggs()
                                        triggerConfettiIfNeeded()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Volume/Amount Section
                if calculatorMode == .normal {
                    Section("section.totalAmount".localized) {
                        VStack(spacing: 12) {
                            HStack {
                                TextField("100", text: $bottleSize)
                                    .keyboardType(.decimalPad)
                                    .font(.system(.title, design: .rounded, weight: .medium))
                                    .focused($focusedField, equals: .bottleSize)
                                    .onChange(of: bottleSize) { newValue in
                                        checkForEasterEggs(newValue)
                                        triggerConfettiIfNeeded()
                                    }

                                Picker("", selection: $useOunces) {
                                    Text("ml").tag(false)
                                    Text("fl oz").tag(true)
                                }
                                .pickerStyle(.segmented)
                                .fixedSize()
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(useOunces ? ozPresets : mlPresets, id: \.self) { preset in
                                        ChipButton(
                                            title: "\(preset) \(unitLabel)",
                                            isSelected: bottleSize == preset
                                        ) {
                                            bottleSize = preset
                                            haptic()
                                            checkForEasterEggs(preset)
                                            triggerConfettiIfNeeded()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    Section("section.productAmount".localized) {
                        VStack(spacing: 12) {
                            HStack {
                                TextField("50", text: $productAmount)
                                    .keyboardType(.decimalPad)
                                    .font(.system(.title, design: .rounded, weight: .medium))
                                    .focused($focusedField, equals: .productAmount)

                                Text(unitLabel)
                                    .foregroundStyle(.secondary)
                                    .font(.title3)
                            }

                            Text("reverse.hint".localized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Result Section
                Section {
                    if let result = calculatedResult {
                        VStack(spacing: 16) {
                            HStack(spacing: 0) {
                                VStack(spacing: 4) {
                                    Text("result.product".localized)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("\(result.part1)")
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                    Text(unitLabel)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)

                                Text("+")
                                    .font(.largeTitle)
                                    .foregroundStyle(.quaternary)

                                VStack(spacing: 4) {
                                    Text("result.water".localized)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text("\(result.part2)")
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                    Text(unitLabel)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }

                            // Action buttons
                            HStack(spacing: 24) {
                                Button {
                                    haptic()
                                    shareResult()
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.title2)
                                        Text("button.share".localized)
                                            .font(.caption)
                                    }
                                }

                                Button {
                                    haptic()
                                    saveToHistory()
                                } label: {
                                    VStack(spacing: 6) {
                                        Image(systemName: "bookmark")
                                            .font(.title2)
                                        Text("button.save".localized)
                                            .font(.caption)
                                    }
                                }
                            }
                            .foregroundStyle(.tint)
                        }
                        .padding(.vertical, 12)
                    } else {
                        Text("result.invalid".localized)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    }
                } header: {
                    HStack {
                        Text("section.result".localized)
                        if showingSecretMode {
                            Spacer()
                            Text("partyMode".localized)
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                // Cost Calculator
                Section("section.costCalculator".localized) {
                    HStack {
                        TextField("cost.pricePerLiter".localized, text: $pricePerLiter)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .price)

                        Text("€/L")
                            .foregroundStyle(.secondary)
                    }

                    if let cost = costPerBottle {
                        HStack {
                            Text("cost.perFill".localized)
                            Spacer()
                            Text(String(format: "%.2f €", cost))
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle("app.title".localized)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("button.done".localized) {
                        focusedField = nil
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        haptic()
                        showingHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        haptic()
                        showingSavePreset = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Image("5-3d-1024px")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 28)
                        .padding(.trailing, 4)
                        .onTapGesture {
                            logoTapCount += 1
                            handleLogoTap()
                        }
                }
            }
            .overlay {
                if showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }
            }
            .sheet(isPresented: $showingPresets) {
                PresetsView(
                    selectedPreset: $selectedPreset,
                    customPresets: customPresets,
                    onSelect: { preset in
                        part1 = preset.part1
                        part2 = preset.part2
                        selectedPreset = preset
                        haptic()
                        showingPresets = false
                    },
                    onDelete: { preset in
                        var presets = customPresets
                        presets.removeAll { $0.id == preset.id }
                        customPresetsData = (try? JSONEncoder().encode(presets)) ?? Data()
                    }
                )
            }
            .sheet(isPresented: $showingSavePreset) {
                SavePresetView(
                    name: $customPresetName,
                    part1: part1,
                    part2: part2,
                    onSave: {
                        let newPreset = ProductPreset(
                            name: customPresetName,
                            part1: part1,
                            part2: part2,
                            category: "presets.custom".localized,
                            isCustom: true
                        )
                        var presets = customPresets
                        presets.append(newPreset)
                        customPresetsData = (try? JSONEncoder().encode(presets)) ?? Data()
                        customPresetName = ""
                        showingSavePreset = false
                        haptic(.success)
                    }
                )
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView(
                    history: history,
                    onSelect: { item in
                        part1 = item.part1
                        part2 = item.part2
                        bottleSize = item.bottleSize
                        useOunces = item.useOunces
                        showingHistory = false
                        haptic()
                    },
                    onClear: {
                        historyData = Data()
                    }
                )
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Presets

    private var ratioPresets: [String] {
        ["1:1", "1:2", "1:4", "1:5", "1:10", "1:15", "1:20", "1:50", "1:100", "1:500"]
    }

    private var mlPresets: [String] {
        ["100", "200", "250", "500", "750", "1000"]
    }

    private var ozPresets: [String] {
        ["4", "8", "16", "24", "32"]
    }

    // MARK: - Actions

    private func haptic(_ type: UINotificationFeedbackGenerator.FeedbackType? = nil) {
        if let type = type {
            UINotificationFeedbackGenerator().notificationOccurred(type)
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func shareResult() {
        guard let result = calculatedResult else { return }

        var text = "\("share.ratio".localized) \(part1):\(part2)\n"
        if let preset = selectedPreset {
            text += "\("result.product".localized): \(preset.localizedName)\n"
        }
        text += "\n"
        text += "\("result.product".localized): \(result.part1) \(unitLabel)\n"
        text += "\("result.water".localized): \(result.part2) \(unitLabel)\n"

        if calculatorMode == .normal {
            text += "\("share.totalAmount".localized): \(bottleSize) \(unitLabel)"
        }

        if let cost = costPerBottle {
            text += "\n\("share.cost".localized): \(String(format: "%.2f €", cost))"
        }

        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func saveToHistory() {
        guard let result = calculatedResult else { return }

        let entry = CalculationHistory(
            date: Date(),
            part1: part1,
            part2: part2,
            bottleSize: bottleSize,
            useOunces: useOunces,
            result1: result.part1,
            result2: result.part2,
            productName: selectedPreset?.localizedName
        )

        var currentHistory = history
        currentHistory.insert(entry, at: 0)
        if currentHistory.count > 50 {
            currentHistory = Array(currentHistory.prefix(50))
        }
        historyData = (try? JSONEncoder().encode(currentHistory)) ?? Data()

        alertTitle = "alert.saved".localized
        alertMessage = "alert.savedMessage".localized
        showingAlert = true
    }

    private func triggerConfettiIfNeeded() {
        guard showingSecretMode, calculatedResult != nil else { return }

        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showConfetti = false
        }
    }

    private func handleLogoTap() {
        haptic()
        switch logoTapCount {
        case 5:
            alertTitle = "🤔"
            alertMessage = "easter.keepTapping".localized
            showingAlert = true
        case 10:
            withAnimation {
                showingSecretMode.toggle()
            }
            if showingSecretMode {
                alertTitle = "🎉 " + "easter.secretUnlocked".localized
                alertMessage = "easter.secretMessage".localized
            } else {
                alertTitle = "👋 " + "easter.partyOver".localized
                alertMessage = "easter.partyOverMessage".localized
            }
            showingAlert = true
            logoTapCount = 0
        case 15:
            alertTitle = "🤯"
            alertMessage = "easter.tooMuchTapping".localized
            showingAlert = true
            logoTapCount = 0
        default:
            break
        }
    }

    private func checkForEasterEggs(_ value: String) {
        guard !value.isEmpty, let intValue = Int(value) else { return }

        switch intValue {
        case 2014:
            alertTitle = "🎉"
            alertMessage = "easter.coupon".localized
            showingAlert = true
        case 69:
            alertTitle = "😏"
            alertMessage = "easter.nice".localized
            showingAlert = true
        case 420:
            alertTitle = "🌿"
            alertMessage = "easter.420".localized
            showingAlert = true
        case 1337:
            alertTitle = "🤓"
            alertMessage = "easter.leet".localized
            showingAlert = true
        case 9999:
            alertTitle = "📱"
            alertMessage = "easter.over9000".localized
            showingAlert = true
        case 1000000...:
            alertTitle = "🐋"
            alertMessage = "easter.whale".localized(intValue/1000)
            showingAlert = true
        case 0:
            alertTitle = "🤷‍♀️"
            alertMessage = "easter.zeroBottle".localized
            showingAlert = true
        default:
            break
        }
    }

    private func checkRatioEasterEggs() {
        if part1 == "42" && part2 == "42" {
            alertTitle = "🤖"
            alertMessage = "easter.42".localized
            showingAlert = true
        } else if part1 == "3" && part2 == "14" {
            alertTitle = "🥧"
            alertMessage = "easter.pi".localized
            showingAlert = true
        } else if part1 == "13" && part2 == "37" {
            alertTitle = "👨‍💻"
            alertMessage = "easter.leetRatio".localized
            showingAlert = true
        }
    }
}

// MARK: - Presets View

struct PresetsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPreset: ProductPreset?
    let customPresets: [ProductPreset]
    let onSelect: (ProductPreset) -> Void
    let onDelete: (ProductPreset) -> Void

    private let defaultPresets: [ProductPreset] = [
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

    private var groupedPresets: [(String, [ProductPreset])] {
        var result: [(String, [ProductPreset])] = []

        if !customPresets.isEmpty {
            result.append(("presets.custom".localized, customPresets))
        }

        let categoryKeys = ["category.apc", "category.glass", "category.detailer", "category.interior", "category.wheels", "category.wash", "category.other"]
        for categoryKey in categoryKeys {
            let presets = defaultPresets.filter { $0.categoryKey == categoryKey }
            if !presets.isEmpty {
                result.append((categoryKey.localized, presets))
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedPresets, id: \.0) { category, presets in
                    Section(category) {
                        ForEach(presets) { preset in
                            Button {
                                onSelect(preset)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(preset.localizedName)
                                        Text("\(preset.part1):\(preset.part2)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedPreset?.id == preset.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.tint)
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if preset.isCustom {
                                    Button(role: .destructive) {
                                        onDelete(preset)
                                    } label: {
                                        Label("button.delete".localized, systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("presets.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("button.done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Save Preset View

struct SavePresetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String
    let part1: String
    let part2: String
    let onSave: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("save.newProduct".localized) {
                    TextField("save.name".localized, text: $name)
                        .focused($isFocused)

                    HStack {
                        Text("section.ratio".localized)
                        Spacer()
                        Text("\(part1):\(part2)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("save.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("button.cancel".localized) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("button.save".localized) {
                        onSave()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}

// MARK: - History View

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let history: [CalculationHistory]
    let onSelect: (CalculationHistory) -> Void
    let onClear: () -> Void

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        NavigationStack {
            Group {
                if history.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("history.empty".localized)
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("history.emptyDescription".localized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(history) { item in
                            Button {
                                onSelect(item)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        if let name = item.productName {
                                            Text(name)
                                                .fontWeight(.medium)
                                        }
                                        Spacer()
                                        Text(dateFormatter.string(from: item.date))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Text("\(item.part1):\(item.part2) → \(item.result1) + \(item.result2) \(item.useOunces ? "fl oz" : "ml")")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle("history.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !history.isEmpty {
                        Button("button.delete".localized, role: .destructive) {
                            onClear()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("button.done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Chip Button

struct ChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.tertiarySystemFill))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var animate = false

    private let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan]

    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { index in
                Circle()
                    .fill(colors[index % colors.count])
                    .frame(width: CGFloat.random(in: 6...14))
                    .scaleEffect(animate ? 0 : 1)
                    .offset(
                        x: animate ? CGFloat.random(in: -400...400) : 0,
                        y: animate ? CGFloat.random(in: -600...600) : 0
                    )
                    .opacity(animate ? 0 : 1)
                    .rotationEffect(.degrees(animate ? Double.random(in: 0...360) : 0))
                    .animation(
                        .easeOut(duration: 1.0)
                        .delay(Double(index) * 0.02),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    ContentView()
}
