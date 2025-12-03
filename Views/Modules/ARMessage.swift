//
//  ARMessage.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 13/12/24.
//

import SwiftUI

struct ARMessage: View {
    var msg: String = ""
    
    var body: some View {
        Text(msg)
            .padding()
            .background(Color.white.opacity(0.3))
            .cornerRadius(10)
            .padding()
    }
}

#Preview {
    ARMessage()
}
