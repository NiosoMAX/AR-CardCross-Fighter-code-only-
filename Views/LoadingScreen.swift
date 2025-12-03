//
//  LoadingScreen.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 22/12/24.
//

import SwiftUI

struct LoadingScreen: View {
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(colors: [.green, .white, .blue, .yellow], startPoint: .topTrailing, endPoint: .bottomLeading).opacity(0.5))
                .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            
            ProgressView(TextConstants.loading)
                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                .scaleEffect(3)
        }
    }
}

#Preview {
    LoadingScreen()
}
