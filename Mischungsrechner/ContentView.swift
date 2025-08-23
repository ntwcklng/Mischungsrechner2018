//
//  ContentView.swift
//  Mischungsrechner
//
//  Updated by Claude on 23.08.25.
//  Copyright © 2025 Marvin Mieth. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var part1: String = "1"
    @State private var part2: String = "1"
    @State private var bottleSize: String = "100"
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var logoTapCount = 0
    @State private var showingSecretMode = false
    @State private var useOunces = false
    
    private var calculatedResult: String {
        guard let p1 = Double(part1),
              let p2 = Double(part2),
              let bottle = Double(bottleSize),
              p1 > 0, p2 > 0, bottle > 0 else {
            return "Gib gültige Werte ein"
        }
        
        let totalParts = p1 + p2
        let partPerUnit = bottle / totalParts
        let part1Output = (p1 * partPerUnit).rounded()
        let part2Output = (p2 * partPerUnit).rounded()
        
        let unit = useOunces ? "fl oz" : "ml"
        return "\(Int(part1Output))\(unit) : \(Int(part2Output))\(unit)"
    }
    
    private var unitLabel: String {
        useOunces ? "fl oz" : "ml"
    }
    
    private func convertToDisplayValue(_ value: String) -> String {
        guard !value.isEmpty, let mlValue = Double(value), useOunces else { return value }
        let ozValue = mlValue / 29.5735 // 1 fl oz = 29.5735 ml
        return String(format: "%.1f", ozValue)
    }
    
    private func convertFromDisplayValue(_ value: String) -> String {
        guard !value.isEmpty, let displayValue = Double(value), useOunces else { return value }
        let mlValue = displayValue * 29.5735
        return String(format: "%.0f", mlValue)
    }
    
    var body: some View {
        ZStack {
            // Dark gradient background with floating elements
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.15, green: 0.1, blue: 0.25),
                    Color(red: 0.2, green: 0.15, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(.all)
            
            // Floating gradient orbs in background
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.purple.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 150
                    ))
                    .frame(width: 300, height: 300)
                    .offset(x: -100, y: -200)
                
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.blue.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 30,
                        endRadius: 120
                    ))
                    .frame(width: 250, height: 250)
                    .offset(x: 150, y: 100)
                
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.pink.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 25,
                        endRadius: 100
                    ))
                    .frame(width: 200, height: 200)
                    .offset(x: -50, y: 300)
            }
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Image("5-3d-1024px")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 60)
                        .scaleEffect(showingSecretMode ? 1.2 : 1.0)
                        .rotationEffect(.degrees(showingSecretMode ? 360 : 0))
                        .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showingSecretMode)
                        .onTapGesture {
                            logoTapCount += 1
                            handleLogoTap()
                        }
                    
                    Text(showingSecretMode ? "🔥 GEHEIMER MODUS 🔥" : "Mischungsrechner")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .animation(.easeInOut, value: showingSecretMode)
                }
                .padding(.top, 20)
                
                VStack(spacing: 32) {
                    // Ratio Section
                    VStack(spacing: 20) {
                        HStack(spacing: 20) {
                            TextField("1", text: $part1)
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(.ultraThinMaterial.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            Text(":")
                                .font(.title)
                                .fontWeight(.light)
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextField("1", text: $part2)
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(.ultraThinMaterial.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                RatioButton(title: "1:1") { setParts("1", "1") }
                                RatioButton(title: "1:2") { setParts("1", "2") }
                                RatioButton(title: "1:4") { setParts("1", "4") }
                                RatioButton(title: "1:10") { setParts("1", "10") }
                                RatioButton(title: "1:15") { setParts("1", "15") }
                                RatioButton(title: "1:500") { setParts("1", "500") }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Bottle Size Section
                    VStack(spacing: 20) {
                        HStack(spacing: 12) {
                            TextField(useOunces ? "3.4" : "100", text: $bottleSize)
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(.ultraThinMaterial.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .onChange(of: bottleSize) { newValue in
                                    let mlValue = convertFromDisplayValue(newValue)
                                    if !mlValue.isEmpty {
                                        checkForEasterEggs(mlValue)
                                    }
                                }
                            
                            // Unit Toggle
                            Button(action: { useOunces.toggle() }) {
                                Text(useOunces ? "fl oz" : "ml")
                                    .font(.callout)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial.opacity(0.6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                if useOunces {
                                    BottleSizeButton(size: "1", unit: "fl oz") { bottleSize = "1" }
                                    BottleSizeButton(size: "3.4", unit: "fl oz") { bottleSize = "3.4" }
                                    BottleSizeButton(size: "6.8", unit: "fl oz") { bottleSize = "6.8" }
                                    BottleSizeButton(size: "8.5", unit: "fl oz") { bottleSize = "8.5" }
                                    BottleSizeButton(size: "12", unit: "fl oz") { bottleSize = "12" }
                                    BottleSizeButton(size: "16", unit: "fl oz") { bottleSize = "16" }
                                    BottleSizeButton(size: "20", unit: "fl oz") { bottleSize = "20" }
                                    BottleSizeButton(size: "33.8", unit: "fl oz") { bottleSize = "33.8" }
                                } else {
                                    BottleSizeButton(size: "100", unit: "ml") { bottleSize = "100" }
                                    BottleSizeButton(size: "200", unit: "ml") { bottleSize = "200" }
                                    BottleSizeButton(size: "250", unit: "ml") { bottleSize = "250" }
                                    BottleSizeButton(size: "473", unit: "ml") { bottleSize = "473" }
                                    BottleSizeButton(size: "500", unit: "ml") { bottleSize = "500" }
                                    BottleSizeButton(size: "1000", unit: "ml") { bottleSize = "1000" }
                                    BottleSizeButton(size: "1500", unit: "ml") { bottleSize = "1500" }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Result with gradient
                Text(calculatedResult)
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8), .cyan.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                    .padding(.top, 30)
                    .padding(.horizontal)
                    .padding(.bottom)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .ignoresSafeArea(.all, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onTapGesture {
            hideKeyboard()
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func setParts(_ p1: String, _ p2: String) {
        part1 = p1
        part2 = p2
    }
    
    private func handleLogoTap() {
        switch logoTapCount {
        case 5:
            alertTitle = "🤔"
            alertMessage = "Hmm... weiter tippen..."
            showingAlert = true
        case 10:
            showingSecretMode.toggle()
            alertTitle = "🎉 GEHEIMER MODUS FREIGESCHALTET!"
            alertMessage = "Du hast den geheimen Modus entdeckt! Die App ist jetzt im Party-Modus! 🎊"
            showingAlert = true
            logoTapCount = 0
        case 15:
            alertTitle = "🤯"
            alertMessage = "Okay okay, du tippst wirklich gerne auf Sachen!"
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
            alertTitle = "Glückwunsch!"
            alertMessage = "Dein Gutscheincode für den GLOSSBOSS-Shop lautet mischungsrechner10"
            showingAlert = true
        case 69:
            alertTitle = "😏"
            alertMessage = "Schön."
            showingAlert = true
        case 420:
            alertTitle = "🌿"
            alertMessage = "Alter... das sind viele ml, Mann..."
            showingAlert = true
        case 1337:
            alertTitle = "🤓"
            alertMessage = "L33T H4X0R erkannt! Du kennst die alten Wege..."
            showingAlert = true
        case 9999:
            alertTitle = "📱"
            alertMessage = "Über 9000!!! Diese Flaschengröße ist ÜBER 9000!!!"
            showingAlert = true
        case 1000000...:
            alertTitle = "🐋"
            alertMessage = "Das sind \(intValue/1000) Liter! Du planst wohl eine Wal-Party?"
            showingAlert = true
        case 0:
            alertTitle = "🤷‍♀️"
            alertMessage = "Eine 0ml Flasche? Das ist... philosophisch."
            showingAlert = true
        case 1:
            alertTitle = "🧪"
            alertMessage = "1ml? Das ist ein Tropfen für Ameisen!"
            showingAlert = true
        default:
            // Check for special ratio patterns
            checkRatioEasterEggs()
        }
    }
    
    private func checkRatioEasterEggs() {
        if part1 == "42" && part2 == "42" {
            alertTitle = "🤖"
            alertMessage = "42? Die Antwort auf die ultimative Frage des Lebens, des Universums und des ganzen Rests!"
            showingAlert = true
        } else if part1 == "3" && part2 == "14" {
            alertTitle = "🥧"
            alertMessage = "Pi erkannt! 3.14... mmm, Kuchen! 🍰"
            showingAlert = true
        } else if part1 == "13" && part2 == "37" {
            alertTitle = "👨‍💻"
            alertMessage = "1337 Verhältnis erkannt! Du mischst wie ein echter Hacker!"
            showingAlert = true
        }
    }
}

struct RatioButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct BottleSizeButton: View {
    let size: String
    let unit: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(size)\(unit)")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ContentView()
}
