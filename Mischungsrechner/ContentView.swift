//
//  ContentView.swift
//  Mischungsrechner
//
//  Updated by Claude on 23.08.25.
//  Copyright © 2025 Marvin Mieth. All rights reserved.
//

import SwiftUI
import Foundation

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
    @State private var calculatedResult: String = ""
    @State private var debounceTimer: Timer?
    @State private var showConfetti = false
    @State private var orb1Offset = CGSize(width: -100, height: -200)
    @State private var orb1Scale: CGFloat = 1.0
    @State private var orb1Blur: CGFloat = 0
    @State private var orb2Offset = CGSize(width: 150, height: 100)
    @State private var orb2Scale: CGFloat = 1.0
    @State private var orb2Blur: CGFloat = 0
    @State private var orb3Offset = CGSize(width: -50, height: 300)
    @State private var orb3Scale: CGFloat = 1.0
    @State private var orb3Blur: CGFloat = 0
    @State private var animationTimer: Timer?
    
    private func calculateResult() -> String {
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
    
    private func debounceCalculation() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            calculatedResult = calculateResult()
            triggerConfettiIfNeeded()
        }
    }
    
    private func triggerConfettiIfNeeded() {
        if showingSecretMode && calculatedResult != "Gib gültige Werte ein" {
            showConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showConfetti = false
            }
        }
    }
    
    private func startFloatingAnimations() {
        // Purple orb - smooth continuous movement that actually works
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            orb1Offset = CGSize(width: -200, height: -300)
        }
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            orb1Scale = 1.4
        }
        withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
            orb1Blur = 3.5
        }
        
        // Blue orb - smooth continuous movement
        withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
            orb2Offset = CGSize(width: 250, height: 50)
        }
        withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
            orb2Scale = 1.3
        }
        withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
            orb2Blur = 2.8
        }
        
        // Pink orb - smooth continuous movement
        withAnimation(.easeInOut(duration: 15).repeatForever(autoreverses: true)) {
            orb3Offset = CGSize(width: -10, height: 380)
        }
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            orb3Scale = 1.25
        }
        withAnimation(.easeInOut(duration: 11).repeatForever(autoreverses: true)) {
            orb3Blur = 2.2
        }
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
                    .scaleEffect(orb1Scale)
                    .blur(radius: orb1Blur)
                    .offset(orb1Offset)
                
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.blue.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 30,
                        endRadius: 120
                    ))
                    .frame(width: 250, height: 250)
                    .scaleEffect(orb2Scale)
                    .blur(radius: orb2Blur)
                    .offset(orb2Offset)
                
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.pink.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 25,
                        endRadius: 100
                    ))
                    .frame(width: 200, height: 200)
                    .scaleEffect(orb3Scale)
                    .blur(radius: orb3Blur)
                    .offset(orb3Offset)
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
                                .padding(20)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 24)
                                            .fill(.white)
                                            .opacity(0.09)
                                        
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.3), .clear, .white.opacity(0.2)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.0
                                            )
                                        
                                        RoundedRectangle(cornerRadius: 24)
                                            .fill(
                                                RadialGradient(
                                                    colors: [.white.opacity(0.1), .clear],
                                                    center: .topLeading,
                                                    startRadius: 0,
                                                    endRadius: 100
                                                )
                                            )
                                    }
                                )
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                .shadow(color: .white.opacity(0.1), radius: 0, x: 0, y: 1)
                                .onChange(of: part1) { _ in debounceCalculation() }
                                .onSubmit { 
                                    calculatedResult = calculateResult()
                                    triggerConfettiIfNeeded()
                                }
                            
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
                                .padding(20)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 24)
                                            .fill(.white)
                                            .opacity(0.09)
                                        
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.3), .clear, .white.opacity(0.2)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.0
                                            )
                                        
                                        RoundedRectangle(cornerRadius: 24)
                                            .fill(
                                                RadialGradient(
                                                    colors: [.white.opacity(0.1), .clear],
                                                    center: .topLeading,
                                                    startRadius: 0,
                                                    endRadius: 100
                                                )
                                            )
                                    }
                                )
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                .shadow(color: .white.opacity(0.1), radius: 0, x: 0, y: 1)
                                .onChange(of: part2) { _ in debounceCalculation() }
                                .onSubmit { 
                                    calculatedResult = calculateResult()
                                    triggerConfettiIfNeeded()
                                }
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
                                .padding(20)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 24)
                                            .fill(.white)
                                            .opacity(0.09)
                                        
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.3), .clear, .white.opacity(0.2)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.0
                                            )
                                        
                                        RoundedRectangle(cornerRadius: 24)
                                            .fill(
                                                RadialGradient(
                                                    colors: [.white.opacity(0.1), .clear],
                                                    center: .topLeading,
                                                    startRadius: 0,
                                                    endRadius: 100
                                                )
                                            )
                                    }
                                )
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                .shadow(color: .white.opacity(0.1), radius: 0, x: 0, y: 1)
                                .onChange(of: bottleSize) { newValue in
                                    let mlValue = convertFromDisplayValue(newValue)
                                    if !mlValue.isEmpty {
                                        checkForEasterEggs(mlValue)
                                    }
                                    debounceCalculation()
                                }
                                .onSubmit { 
                                    calculatedResult = calculateResult()
                                    triggerConfettiIfNeeded()
                                }
                            
                            // Unit Toggle
                            Button(action: { 
                                useOunces.toggle()
                                calculatedResult = calculateResult()
                                triggerConfettiIfNeeded()
                            }) {
                                Text(useOunces ? "fl oz" : "ml")
                                    .font(.callout)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(.white)
                                                .opacity(0.09)
                                            
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [.white.opacity(0.3), .clear, .white.opacity(0.2)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1.0
                                                )
                                            
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(
                                                    RadialGradient(
                                                        colors: [.white.opacity(0.1), .clear],
                                                        center: .topLeading,
                                                        startRadius: 0,
                                                        endRadius: 60
                                                    )
                                                )
                                        }
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                    .shadow(color: .white.opacity(0.1), radius: 0, x: 0, y: 1)
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
            
            // Confetti overlay for party mode
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea(.all)
            }
        }
        .preferredColorScheme(.dark)
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            calculatedResult = calculateResult()
            triggerConfettiIfNeeded()
            startFloatingAnimations()
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
        calculatedResult = calculateResult()
        triggerConfettiIfNeeded()
    }
    
    private func handleLogoTap() {
        switch logoTapCount {
        case 5:
            alertTitle = "🤔"
            alertMessage = "Hmm... weiter tippen..."
            showingAlert = true
        case 10:
            showingSecretMode.toggle()
            if showingSecretMode {
                alertTitle = "🎉 GEHEIMER MODUS FREIGESCHALTET!"
                alertMessage = "Du hast den geheimen Modus entdeckt! Die App ist jetzt im Party-Modus! 🎊"
            } else {
                alertTitle = "👋 PARTY VORBEI"
                alertMessage = "Du hast den Party-Modus verlassen. Zurück zur normalen Ansicht! 🙂"
            }
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
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.white)
                            .opacity(0.09)
                        
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear, .white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                        
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                RadialGradient(
                                    colors: [.white.opacity(0.1), .clear],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 40
                                )
                            )
                    }
                )
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .shadow(color: .white.opacity(0.1), radius: 0, x: 0, y: 1)
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
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.white)
                            .opacity(0.09)
                        
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear, .white.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                        
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                RadialGradient(
                                    colors: [.white.opacity(0.1), .clear],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 40
                                )
                            )
                    }
                )
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                .shadow(color: .white.opacity(0.1), radius: 0, x: 0, y: 1)
        }
    }
}

struct ConfettiView: View {
    @State private var animate = false
    let colors = [Color.red, Color.blue, Color.green, Color.yellow, Color.orange, Color.purple, Color.pink, Color.cyan]
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { index in
                Circle()
                    .fill(colors.randomElement() ?? Color.blue)
                    .frame(width: CGFloat.random(in: 4...12), height: CGFloat.random(in: 4...12))
                    .scaleEffect(animate ? 0 : 1)
                    .offset(
                        x: animate ? CGFloat.random(in: -400...400) : 0,
                        y: animate ? CGFloat.random(in: -600...600) : 0
                    )
                    .opacity(animate ? 0 : 1)
                    .rotationEffect(.degrees(animate ? Double.random(in: 0...360) : 0))
                    .animation(
                        .easeOut(duration: 1.0)
                        .delay(Double.random(in: 0...0.3)),
                        value: animate
                    )
                    .onAppear {
                        animate = true
                    }
                    .onDisappear {
                        animate = false
                    }
            }
        }
        .allowsHitTesting(false)
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
