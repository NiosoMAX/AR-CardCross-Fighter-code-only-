//
//  Countdown.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 10/1/25.
//

import SwiftUI

struct Countdown: View {
    @State private var time = Constants.defaultCountdown
    @State private var finalText = TextConstants.go
    @State private var timer: Timer?
    
    var body: some View {
        VStack {
            if (time > 0) {
                Text(String(time))
                    .font(.system(size: 80))
                    .fontWeight(.bold)
                    .padding()
                    .foregroundStyle(.green)
            } else if time == 0 {
                Text(finalText)
                    .font(.system(size: 100))
                    .transition(.scale)
                    .id(UUID())
                    .foregroundStyle(.red)
            }
        }
        .onAppear {
            startSequence()
        }
    }
    
    private func startSequence() {
        //print("Starting countdown")
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            time -= 1
            if time < 0 {
                ARBattleDelegate.shared.startGame()
                stopSequence()
            }
        }
    }
    
    private func stopSequence() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    Countdown()
}
