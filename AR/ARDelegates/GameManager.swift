//
//  GameManager.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 30/12/24.
//

import Foundation
import RealityKit
import Combine
import SwiftUIJoystick

class GameManager {
    // MARK: Variables
    private var _player1: PlayableCharacterModel? = nil
    private var _player2: PlayableCharacterModel? = nil
    private var _isPaused = false
    private var _gameState: Int = GameState.detectCharacters
    private var _lastActiveGameState: Int = GameState.combatConfirmation
    private var _selectedPlayableCharacter: PlayableCharacterID = .hitomi
    
    // MARK: Public variables
    var player1: PlayableCharacterModel? {
        get {
            return _player1
        }
        set {
            _player1 = newValue
        }
    }
    
    var player2: PlayableCharacterModel? {
        get {
            return _player2
        }
        set {
            _player2 = newValue
        }
    }
    
    var isPaused: Bool {
        get {
            return _isPaused
        }
        set {
            _isPaused = newValue
        }
    }
    
    var playerHP: Double {
        get {
            return player1!.hp
        }
    }
    
    var rivalHP: Double {
        get {
            return player2!.hp
        }
    }
    
    var gameState: Int {
        get {
            return _gameState
        }
        set {
            _gameState = newValue
        }
    }
    
    var lastActiveGameState: Int {
        get {
            return _lastActiveGameState
        }
        set {
            _lastActiveGameState = newValue
        }
    }
    
    var selectedPlayableCharacter: PlayableCharacterID {
        get {
            return _selectedPlayableCharacter
        }
        set {
            _selectedPlayableCharacter = newValue
        }
    }
    
    // MARK: Combine: Streams and publishers
    private var streamShowGameUI = PassthroughSubject<Bool, Never>()
    private var streamIsGameActive = PassthroughSubject<Bool, Never>()
    private var streamIsGameFinished = PassthroughSubject<Bool, Never>()
    private var streamPlayerNamePosition = PassthroughSubject<FighterPositionName, Never>()
    private var streamPlayableChar = PassthroughSubject<String, Never>()
    private var streamAttack = PassthroughSubject<AttackDMGTarget, Never>()
    private var streamHPUpdate = PassthroughSubject<(FighterPosition, Double), Never>()
    private var streamWinner = PassthroughSubject<FighterPositionName, Never>()
    private var streamCooldown = PassthroughSubject<TimeInterval, Never>()
    private var streamStartCountdown = PassthroughSubject<Bool, Never>()
    
    var publisherShowGameUI: AnyPublisher<Bool, Never> {
        return streamShowGameUI.eraseToAnyPublisher()
    }
    
    var publisherIsGameActive: AnyPublisher<Bool, Never> {
        return streamIsGameActive.eraseToAnyPublisher()
    }
    
    var publisherIsGameFinished: AnyPublisher<Bool, Never> {
        return streamIsGameFinished.eraseToAnyPublisher()
    }
    
    var publisherPlayerNamePosition: AnyPublisher<FighterPositionName, Never> {
        return streamPlayerNamePosition.eraseToAnyPublisher()
    }
    
    var publisherPlayableChar: AnyPublisher<String, Never> {
        return streamPlayableChar.eraseToAnyPublisher()
    }
    
    var publisherAttack: AnyPublisher<AttackDMGTarget, Never> {
        return streamAttack.eraseToAnyPublisher()
    }
    
    var publisherHP: AnyPublisher<(FighterPosition, Double), Never> {
        return streamHPUpdate.eraseToAnyPublisher()
    }
    
    var publisherWinner: AnyPublisher<FighterPositionName, Never> {
        return streamWinner.eraseToAnyPublisher()
    }
    
    var publisherCooldown: AnyPublisher<TimeInterval, Never> {
        return streamCooldown.eraseToAnyPublisher()
    }
    
    var publisherStartCountdown: AnyPublisher<Bool, Never> {
        return streamStartCountdown.eraseToAnyPublisher()
    }
    
    // MARK: Combine senders
    func sendShowGameUI(_ isShown: Bool){
        streamShowGameUI.send(isShown)
        
        if (isShown) {
            _gameState = _lastActiveGameState
        }
    }
    
    func sendIsGameActive(_ isActive: Bool){
        streamIsGameActive.send(isActive)
    }
    
    func sendIsGameFinished(_ isFinished: Bool) {
        streamIsGameFinished.send(isFinished)
    }
    
    func sendPlayerNamePosition(_ data: FighterPositionName){
        streamPlayerNamePosition.send(data)
    }
    
    func sendAllPlayerData(player1: String, player2: String){
        streamPlayerNamePosition.send(.player1Name(name: player1))
        streamPlayerNamePosition.send(.player2Name(name: player2))
    }
    
    func sendPlayableChar(){
        streamPlayableChar.send(_selectedPlayableCharacter.name)
    }
    
    func sendAttack(_ attack: AttackDMGTarget, type: DMGType) {
        var strength: Float
        switch(type) {
        case .normalAttackDMG:
            strength = Constants.knockbackSmallDistance
        case .skillDMG:
            strength = Constants.knockbackBigDistance
        }
        
        switch(attack){
        case .toPlayer(let dmg):
            let rotation = getKnockbackAngle(model: player2!.model)
            self.player1?.receiveAttack(dmg: dmg, strength: strength, angle: rotation)
            self.streamAttack.send(.toPlayer(amount: player1!.hp))
            break
        case .toRival(let dmg):
            let rotation = getKnockbackAngle(model: player1!.model)
            self.player2?.receiveAttack(dmg: dmg, strength: strength, angle: rotation)
            self.streamAttack.send(.toRival(amount: player2!.hp))
            break
        }
    }
    
    private func getKnockbackAngle(model: ModelEntity) -> Float {
        let rotation = model.orientation
        let angleY = rotation.axis.y
        return -angleY
    }
    
    func sendCooldown(_ cd: TimeInterval){
        streamCooldown.send(cd)
    }
    
    func sendHPUpdate(_ player: FighterPosition, hp: Double){
        streamHPUpdate.send((player, hp))
    }
    
    func sendStartCountdown(){
        _gameState = GameState.aboutToBattle
        _lastActiveGameState = GameState.aboutToBattle
        streamStartCountdown.send(true)
        AudioManager.shared.playMusic(track: .battle)
        AudioManager.shared.playCountdown()
    }
    
    // MARK: Game logic
    
    func startGame(player1Model: ModelEntity, player2Model: ModelEntity, monitor: JoystickMonitor) {
        _player1 = PlayableCharacterModel(model: player1Model, jsMonitor: monitor)
        _player2 = PlayableCharacterModel(model: player2Model)
        _gameState = GameState.combatPlay
        _lastActiveGameState = GameState.combatPlay
        sendIsGameActive(true)
        sendAllPlayerData(player1: player1Model.name, player2: player2Model.name)
        streamStartCountdown.send(false)
    }
    
    func attack(to target: AttackTarget){
        switch(target){
        case .toPlayer:
            player2?.attack()
        case .toRival:
            player1?.attack()
        }
    }
    
    func skill(to target: AttackTarget) {
        switch(target){
        case .toPlayer:
            player2?.skill()
        case .toRival:
            player1?.skill()
        }
    }
    
    func win(loserPosition: FighterPosition, loserID: PlayableCharacterID){
        if gameState == GameState.combatPlay {
            gameState = GameState.victory
            _lastActiveGameState = GameState.victory
            AudioManager.shared.setMusicVolume(volume: SoundConstants.musicVolumeBattleEnd)
            
            switch(loserPosition) {
            case .player1:
                player2!.victoryAnimation()
                Timer.scheduledTimer(withTimeInterval: Constants.showScreenDelay, repeats: false) { _ in
                    self.streamWinner.send(.player1Name(name: self.player2!.name))
                }
            case .player2:
                player1!.victoryAnimation()
                Timer.scheduledTimer(withTimeInterval: Constants.showScreenDelay, repeats: false) { _ in
                    self.streamWinner.send(.player2Name(name: self.player1!.name))
                }
            }
        }
    }
    
    func restart(){
        _player1?.reset()
        _player2?.reset()
        _player1 = nil
        _player2 = nil
        _isPaused = false
        _gameState = GameState.detectCharacters
        _lastActiveGameState = GameState.combatConfirmation
        sendHPUpdate(.player1, hp: Constants.defaultMaxHP)
        sendHPUpdate(.player2, hp: Constants.defaultMaxHP)
        sendIsGameActive(false)
        sendIsGameFinished(false)
        AudioManager.shared.playMusic(track: .theme)
        sendCooldown(0)
    }
}
