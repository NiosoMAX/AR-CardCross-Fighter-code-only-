//
//  WinnerMSG.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 5/1/25.
//

import SwiftUI

struct WinnerMSGWindow: View {
    var message = ""
    
    init(message: String) {
        self.message = message
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.yellow.opacity(0.7))
                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: .infinity)
            
            VStack {
                Text(message)
                    .font(.system(size: 60, weight: .bold))
                
                
                FilledButton(color: .green, text: TextConstants.restart) {
                    ARBattleDelegate.shared.restart()
                }
                .frame(width: 200, height: 50)
            }
        }
        .padding()
    }
}

#Preview {
    WinnerMSGWindow(message: "Hitomi wins!")
}
