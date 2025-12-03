//
//  FilledButton.swift
//  SSB Teams
//
//  Created by Pablo on 19/4/24.
//

import SwiftUI

struct FilledButton: View {
    var color: Color
    var text: String
    var icon: Bool = false
    var bigText: Bool = false
    var cooldown: TimeInterval = .zero
    
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                FilledButtonBackground(cooldown: cooldown, color: color)
                
                if cooldown == .zero {
                    if icon {
                        Image(systemName: text)
                    } else {
                        FilledButtonLabel(text: text, bigText: bigText)
                    }
                }
                if cooldown != .zero {
                    Text(String(format: "%.1f", cooldown))
                        .foregroundColor(.white)
                        .bold()
                        .font(/*@START_MENU_TOKEN@*/.title3/*@END_MENU_TOKEN@*/)
                }
            }
        }
    }
}

struct FilledButtonBackground: View {
    var cooldown: TimeInterval = .zero
    var color: Color
    
    var body: some View {
        if (cooldown == .zero){
            RoundedRectangle(cornerRadius: 12)
                .foregroundColor(color)
        } else {
            RoundedRectangle(cornerRadius: 12)
                .foregroundColor(color).saturation(0.4)
        }
    }
}

struct FilledButtonLabel: View {
    var text: String
    var bigText: Bool = false
    
    var body: some View {
        if (bigText) {
            Text(text)
                .foregroundColor(.white)
                .bold()
                .font(.largeTitle)
        } else {
            Text(text)
                .foregroundColor(.white)
                .bold()
                .font(/*@START_MENU_TOKEN@*/.title3/*@END_MENU_TOKEN@*/)
        }
    }
}

#Preview {
    FilledButton(color: .blue, text: "Test"){
        
    }
}
