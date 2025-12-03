//
//  InfoView.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 17/11/24.
//

import SwiftUI
import ARKit

struct ARInfoView: View {
    @Environment(\.isPresented) var isPresented
    
    var body: some View {
        ARInfoViewContainer()
            .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            .onChange(of: isPresented) {
                if !isPresented {
                    ARManager.shared.sceneView.session.pause()
                }
            }
    }
}

struct ARInfoViewContainer: UIViewRepresentable {

    typealias UIViewType = ARSCNView
    
    func makeUIView(context: Context) -> ARSCNView {
        ARInfoDelegateCoordinator.shared.startARSession()
        
        return ARSessionManager.shared.sceneView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
}
    

#Preview {
    ARInfoView()
}
