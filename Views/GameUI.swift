//
//  GameUI.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 10/12/24.
//

import SwiftUI
import SwiftUIJoystick

struct GameUI: View {
    // Control states
    var gameActive: Bool
    var gameFinished: Bool
    var playerSkillCd: TimeInterval
    var showCountdown: Bool
    
    // Game
    var player1HP: Double
    var player2HP: Double
    var joystickMonitor: JoystickMonitor
    
    // Text
    var player1: String // Playable
    var player2: String // Rival
    var controllable: String
    var winnerMSG: String
    
    // Animations
    @State private var victoryWindowOpacity: Double = 0.0
    
    init(
        gameActive: Bool = false,
        gameFinished: Bool = false,
        joystickMonitor: JoystickMonitor,
        player1: String,
        player2: String,
        controllable: String = "",
        player1HP: Double = 1.0,
        player2HP: Double = 1.0,
        winnerMSG: String = "",
        cooldown: TimeInterval = .zero,
        showCountdown: Bool = false
    ) {
        self.gameActive = gameActive
        self.gameFinished = gameFinished
        self.joystickMonitor = joystickMonitor
        self.player1 = player1
        self.player2 = player2
        self.controllable = controllable
        self.player1HP = player1HP
        self.player2HP = player2HP
        self.winnerMSG = winnerMSG
        self.playerSkillCd = cooldown
        self.showCountdown = showCountdown
    }
    
    var body: some View {
        ZStack {
            if (gameFinished){
                WinnerMSGWindow(message: winnerMSG)
                    .onAppear(){
                        withAnimation(.easeIn(duration: 0.8)) {
                            victoryWindowOpacity = 1.0
                        }
                    }
            }
            
            VStack {
                VStack {
                    HPBarView(textFirst: true, user: player1, valHP: player1HP)
                        .padding(.vertical, 20)
                    HPBarView(textFirst: false, user: player2, valHP: player2HP)
                        .padding(.vertical, 20)
                }
                
                Spacer()
                
                if (!gameFinished && !showCountdown) {
                    if (gameActive) {
                        GameButtons(joystickMonitor: joystickMonitor, cooldown: playerSkillCd)
                    } else {
                        ConfirmButtons(controllable: controllable)
                    }
                }
                
            }
            .padding()
            
            if (showCountdown) {
                Countdown()
            }
        }
    }
}

struct ConfirmButtons: View {
    var controllable: String
    
    var body: some View {
        VStack {
            Group {
                FilledButton(color: .gray, text: TextConstants.changeChar) {
                    ARBattleDelegate.shared.togglePlayers()
                }
                .frame(width: 120, height: 60)
                
                ARMessage(msg: "\(TextConstants.yourFighter): \(controllable)")
                
                FilledButton(color: .red, text: TextConstants.fight, bigText: true) {
                    ARBattleDelegate.shared.startCountdown()

                }
                .frame(width: 200, height: 80)
            }
            .frame(maxHeight: 150, alignment: .bottom)
        }
    }
}

struct GameButtons: View {
    var joystickMonitor: JoystickMonitor
    var cooldown: TimeInterval
    
    init(joystickMonitor: JoystickMonitor, cooldown: TimeInterval) {
        self.joystickMonitor = joystickMonitor
        self.cooldown = cooldown
    }
    
    var body: some View {
        HStack {
            Joystick(monitor: joystickMonitor, width: 150)
            
            Spacer()
            
            HStack {
                FilledButton(color: .red, text: TextConstants.normal_attack) {
                    ARBattleDelegate.shared.attack(to: .toRival)
                }.frame(width: 100, height: 100)
                
                FilledButton(color: .blue, text: TextConstants.skill, icon: false, cooldown: cooldown) {
                    ARBattleDelegate.shared.skill(to: .toRival)
                }.frame(width: 100, height: 100)
            }
        }
        .padding()
    }
}

#Preview {
    GameUI(gameActive: false, gameFinished: true, joystickMonitor: JoystickMonitor(), player1: "HP", player2: "HP", winnerMSG: "Hitomi wins!")
}
