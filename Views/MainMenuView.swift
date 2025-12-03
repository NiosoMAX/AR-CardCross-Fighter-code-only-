//
//  MainMenuView.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 17/11/24.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

struct MainMenuView: View {
    @StateObject var viewModel = MainMenuViewModel()
    
    var body: some View {
        ZStack {
            NavigationStack{
                // Menú principal
                VStack {
                    Text(TextConstants.title)
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .padding()
                    
                    
                    Spacer()
                    
                    HStack {
                        MenuNavButton(color: .indigo, text: TextConstants.mainButtonBattleMSG){
                            ZStack {
                                ARViewContainer(isBattleViewActive: .constant(true), isLoading: $viewModel.isLoading, session: ARSessionManager.shared.session)
                                    .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                                    .onAppear() {
                                        ARBattleDelegate.shared.freeMemory()
                                    }
                                    .onDisappear {
                                        ARBattleDelegate.shared.freeMemory()
                                        ARSessionManager.shared.arView?.session.pause()
                                        ARSessionManager.shared.arView?.scene.anchors.removeAll()
                                        ARSessionManager.shared.arView?.removeFromSuperview()
                                        ARSessionManager.shared.arView = nil
                                    }
                                
                                BattleUI()
                            }
                        }
                        .padding()
                        
                        VStack {
                            MenuNavButton(color: .green, text: TextConstants.mainButtonInfoMSG){
                                ZStack {
                                    ARViewContainer(isBattleViewActive: .constant(false), isLoading: $viewModel.isLoading, session: ARSessionManager.shared.session)
                                        .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                                        .onDisappear {
                                            ARSessionManager.shared.arView?.session.pause()
                                            ARSessionManager.shared.arView?.scene.anchors.removeAll()
                                            ARSessionManager.shared.arView?.removeFromSuperview()
                                            ARSessionManager.shared.arView = nil
                                        }
                                    
                                    InfoUI()
                                }
                            }
                        }.padding()
                    }
                }
            }
            // Pantalla de carga
            if (viewModel.isLoading) {
                LoadingScreen()
            }
        }
        
    }
}

// MARK: Aux views

struct MenuNavButton<V: View>: View{
    var color: Color
    var text: String
    var icon: Bool = false
    var destination: () -> V

    
    var body: some View {
        NavigationLink {
            destination()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .foregroundColor(color)
                if icon {
                    Image(systemName: text)
                } else {
                    Text(text)
                        .foregroundColor(.white)
                        .bold()
                        .font(/*@START_MENU_TOKEN@*/.title3/*@END_MENU_TOKEN@*/)
                }
            }
           
        }
    }
}

struct BattleUI: View {
    @StateObject private var gameUIManager = GameUIManager()
    @State private var gameUIOpacity: Double = 0.0

    var body: some View {
        if (gameUIManager.showGameUI){
            GameUI(
                gameActive: gameUIManager.isGameActive,
                gameFinished: gameUIManager.isGameFinished,
                joystickMonitor: ARBattleDelegate.shared.joystickMonitor,
                player1: gameUIManager.player1,
                player2: gameUIManager.player2,
                controllable: gameUIManager.controllableChar,
                player1HP: gameUIManager.playerHP,
                player2HP: gameUIManager.rivalHP,
                winnerMSG: gameUIManager.winnerMSG,
                cooldown: gameUIManager.playerSkillCd,
                showCountdown: gameUIManager.showCountdown
            )
                .padding(/*@START_MENU_TOKEN@*/EdgeInsets()/*@END_MENU_TOKEN@*/)
                .opacity(gameUIOpacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 0.8)) {
                        gameUIOpacity = 1.0
                    }
                }
        } else {
            Group {
                HStack {
                    ARMessage(msg: TextConstants.initBattleMSG)
                }
            }.frame(maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .bottom)
                .padding()
        }
    }
}

struct InfoUI: View {
    var body: some View {
        Group {
            ARMessage(msg: TextConstants.initInfoMSG)
        }.frame(maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .bottom)
            .padding()
    }
}


// MARK: ARContainer
struct ARViewContainer: UIViewRepresentable {
    @Binding var isBattleViewActive: Bool
    @Binding var isLoading: Bool
    
    var session: ARSession
    let infoDelegate = ARInfoDelegate()
    
    func makeUIView(context: Context) -> UIView {
        let globalARContainerView = UIView(frame: .zero)
        ARSessionManager.shared.showLoadingScreen(activate: true)
        
        if isBattleViewActive {
            DispatchQueue.main.async{
                // Escena RealityKit
                let battleARView = ARView(frame: .zero)
                battleARView.session = session
                globalARContainerView.addSubview(battleARView)
                battleARView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    battleARView.topAnchor.constraint(equalTo: globalARContainerView.topAnchor),
                    battleARView.bottomAnchor.constraint(equalTo: globalARContainerView.bottomAnchor),
                    battleARView.leadingAnchor.constraint(equalTo: globalARContainerView.leadingAnchor),
                    battleARView.trailingAnchor.constraint(equalTo: globalARContainerView.trailingAnchor)
                ])
                
                battleARView.session.delegate = ARBattleDelegate.shared
                ARSessionManager.shared.arView = battleARView
                ARSessionManager.shared.loadRealityKitSystems()
                
                context.coordinator.arView = battleARView
                //context.coordinator.setupCollisions()
                
                ARSessionManager.shared.showLoadingScreen(activate: false)
            }
        } else {
            DispatchQueue.main.async {
                // Escena ARKit
                let infoARView = ARSCNView(frame: .zero)
                infoARView.session = session
                globalARContainerView.addSubview(infoARView)
                infoARView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    infoARView.topAnchor.constraint(equalTo: globalARContainerView.topAnchor),
                    infoARView.bottomAnchor.constraint(equalTo: globalARContainerView.bottomAnchor),
                    infoARView.leadingAnchor.constraint(equalTo: globalARContainerView.leadingAnchor),
                    infoARView.trailingAnchor.constraint(equalTo: globalARContainerView.trailingAnchor)
                ])
                
                let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTapGesture(_:)))
                infoARView.addGestureRecognizer(tapGesture)
                
                infoARView.delegate = infoDelegate
                ARSessionManager.shared.showLoadingScreen(activate: false)
            }
        }
        
        return globalARContainerView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        if isBattleViewActive {
            if let infoARView = uiView.subviews.first(where: { $0 is ARSCNView }) as? ARSCNView {
                infoARView.session.pause()
                infoARView.isHidden = true
            }
            if let battleARView = uiView.subviews.first(where: { $0 is ARView }) as? ARView {
                let conf = ARSessionManager.shared.getImgTrackingConfiguration()
                battleARView.session.run(conf, options: [.resetTracking, .removeExistingAnchors])
                battleARView.isHidden = false
                ARSessionManager.shared.arView = battleARView
            }
        } else {
            if let battleARView = uiView.subviews.first(where: { $0 is ARView }) as? ARView {
                battleARView.session.pause()
                battleARView.isHidden = true
                ARSessionManager.shared.arView = battleARView
            }
            if let infoARView = uiView.subviews.first(where: { $0 is ARSCNView }) as? ARSCNView {
                let conf = ARSessionManager.shared.getImgTrackingConfiguration()
                infoARView.session.run(conf, options: [.resetTracking, .removeExistingAnchors])
                infoARView.isHidden = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(infoDelegate: infoDelegate)
    }
    
    class Coordinator: NSObject{
        var infoDelegate: ARInfoDelegate
        weak var arView: ARView?
        
        init(infoDelegate: ARInfoDelegate) {
            self.infoDelegate = infoDelegate
        }
        
        @objc func handleTapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
            guard let arSCNView = gestureRecognizer.view as? ARSCNView else { return }

            // Llamar al método de raycasting
            infoDelegate.handleTap(gestureRecognizer, in: arSCNView)
        }
    }
}

#Preview {
    MainMenuView()
}
