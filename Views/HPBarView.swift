//
//  HPBar.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 10/12/24.
//

import SwiftUI

struct HPBarView: View {
    var textFirst = true
    var user: String = ""
    var maxHP: Double = Constants.defaultMaxHP
    var valHP: Double
    
    init(textFirst: Bool = true, user: String, valHP: Double = Constants.defaultMaxHP) {
        self.textFirst = textFirst
        self.user = user
        self.valHP = valHP
    }
    
    var body: some View {
        VStack {
            HStack{
                if (textFirst){
                    NameLabel(user: user)
                }
                
                Spacer()
                
                GeometryReader { proxy in
                    HStack (alignment: .center) {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 50)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(valHP > maxHP * 0.2 ? .green : .red)
                                .frame(width: max(0, proxy.size.width * min(1, CGFloat(valHP) / CGFloat(maxHP))), height: 30)
                                .animation(.easeOut(duration: 0.5), value: valHP)
                            
                            //Text("Debug: \(valHP)")
                        }
                    }
                }
                .frame(height: 50)
                
                Spacer()
                
                if (!textFirst){
                    NameLabel(user: user)
                }
            }
        }
        
    }
}

struct NameLabel: View {
    var user: String = ""
    var body: some View {
        Text(user)
            .font(.headline)
            .padding()
            .background(Color.white.opacity(0.3))
            .cornerRadius(10)
            .padding(.leading, 10)
    }
}

#Preview {
    HPBarView(textFirst: false, user: "HP", valHP: Constants.defaultMaxHP)
}
