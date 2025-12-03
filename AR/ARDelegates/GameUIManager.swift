//
//  GameManager.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 12/12/24.
//

import Foundation
import RealityKit
import Combine
import SwiftUIJoystick

class GameUIManager: ObservableObject {
    
    // Status
    @Published var showGameUI: Bool = false
    @Published var isGameActive: Bool = false
    @Published var isGameFinished: Bool = false
    @Published var showCountdown: Bool = false
    private var cancellables: Set<AnyCancellable> = []
    
    // Players
    @Published var player1: String = TextConstants.hp
    @Published var player2: String = TextConstants.hp
    @Published var playerHP: Double = Constants.defaultMaxHP
    @Published var rivalHP: Double = Constants.defaultMaxHP
    @Published var controllableChar: String = ""
    @Published var winnerMSG: String = ""
    @Published var playerSkillCd: TimeInterval = .zero
    
    
    init() {
        // Stream activar game UI
        ARBattleDelegate.shared.gameManager.publisherShowGameUI
            .sink { [weak self] isActive in
                self?.showGameUI = isActive
            }
            .store(in: &cancellables)
        
        // Stream jugadores
        ARBattleDelegate.shared.gameManager.publisherPlayerNamePosition
            .sink{ [weak self] player in
                switch(player) {
                case .player1Name(let data):
                    self?.player1 = data
                case .player2Name(let data):
                    self?.player2 = data
                }
            }
            .store(in: &cancellables)
        
        // Stream activar juego
        ARBattleDelegate.shared.gameManager.publisherIsGameActive
            .sink { [weak self] status in
                self?.isGameActive = status
            }
            .store(in: &cancellables)
        
        // Stream activar victoria
        ARBattleDelegate.shared.gameManager.publisherIsGameFinished
            .sink { [weak self] status in
                self?.isGameFinished = status
            }
            .store(in: &cancellables)
        
        // Stream personaje a controlar
        ARBattleDelegate.shared.gameManager.publisherPlayableChar
            .sink { [weak self] char in
                self?.controllableChar = char
            }
            .store(in: &cancellables)
        
        // Stream ataques (aquí se envía el total de HP)
        ARBattleDelegate.shared.gameManager.publisherAttack
            .sink { [weak self] attack in
                switch(attack){
                case .toPlayer(let hp):
                    self?.playerHP = hp
                case .toRival(let hp):
                    self?.rivalHP = hp
                    //let tempHP = self?.rivalHP
                    //print("Rival receives \(dmg) DMG: \(String(describing: tempHP)) -> \(String(describing: self?.rivalHP))")
                }
            }
            .store(in: &cancellables)
        
        // Stream ganador
        ARBattleDelegate.shared.gameManager.publisherWinner
            .sink { [weak self] loser in
                switch(loser){
                case .player1Name(let name):
                    self?.winnerMSG = "\(TextConstants.player2) \(name) \(TextConstants.msg_winner_end)"
                    self?.isGameActive = false
                    self?.isGameFinished = true
                case .player2Name(let name):
                    self?.winnerMSG = "\(TextConstants.player1) \(name) \(TextConstants.msg_winner_end)"
                    self?.isGameActive = false
                    self?.isGameFinished = true
                }
            }
            .store(in: &cancellables)
        
        // Stream skill cooldown
        ARBattleDelegate.shared.gameManager.publisherCooldown
            .sink { [weak self] cd in
                self?.playerSkillCd = cd
            }
            .store(in: &cancellables)
        
        // Stream HP updates
        ARBattleDelegate.shared.gameManager.publisherHP
            .sink { [weak self] hpData in
                if (hpData.0 == .player1) {
                    self?.playerHP = hpData.1
                }
                if (hpData.0 == .player2) {
                    self?.rivalHP = hpData.1
                }
            }
            .store(in: &cancellables)
        
        // Stream countdown
        ARBattleDelegate.shared.gameManager.publisherStartCountdown
            .sink { [weak self] activate in
                self?.showCountdown = activate
            }
            .store(in: &cancellables)
    }
    
    func setPlayers(player1: String, player2: String) {
        self.player1 = player1
        self.player2 = player2
    }
}
