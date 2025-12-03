//
//  ARAction.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 19/11/24.
//

import Foundation
import ARKit
import RealityCollisions

enum PlayableCharacterID: String, CaseIterable {
    case hitomi = "Hitomi"
    case miki = "Miki"
    
    var name: String {
        return self.rawValue
    }
    
    static func idFromName(_ name: String) -> PlayableCharacterID? {
        return PlayableCharacterID.allCases.first { $0.name == name }
    }
}

enum FighterPositionName {
    case player1Name(name: String)
    case player2Name(name: String)
}

enum FighterPosition {
    case player1
    case player2
}

enum Weapons: String {
    case katana = "Katana"
}

// MARK: Game

enum AttackTarget {
    case toRival
    case toPlayer
}

enum AttackDMGTarget {
    case toRival(amount: Double)
    case toPlayer(amount: Double)
}

enum DMGType {
    case normalAttackDMG
    case skillDMG
    //case ultDMG
}

enum NormalAttackType: String, Codable {
    case melee = "melee"
    case projectile = "projectile"
}

enum SkillType: String, Codable {
    case aoe = "aoe"
    case beam = "beam"
}

enum CPUActionType {
    case attack
    case skill
    case move
}

public enum GameCollisionGroups: Int, HasCollisionGroups {
    case player, rival, playerAtk, rivalAtk
}

// MARK: Sound
enum CharacterVoiceLines: String {
    case start = "Start"
    case attack = "Attack"
    case skill = "Skill"
    case damage = "Damage"
    case victory = "Victory"
    case defeat = "Defeat"
}

enum GameMusic: String {
    case theme = "Bloodline"
    case battle = "extremeaction"
}

enum GameSFX: String {
    case countdown = "DeepCountdown"
    case sword1 = "sword-slash-1"
    case sword2 = "sword-slash-2"
    case shot = "laser-shot"
    case beam = "laser-beam"
}

// MARK: Animations

enum CharacterAnimationType: String, CaseIterable {
    case idle = "Idle"
    case idle_to_action = "IdleToAction"
    case battle_idle = "BattleIdle"
    case run = "Run"
    case normal_attack = "NormalAttack"
    case skill = "Skill"
    case defeat = "Defeat"
    case victory = "Victory"
    
    func startTime(_ character: PlayableCharacterID) -> TimeInterval {
        let start = Double(startFrame(character)) / 30.0
        
        if character == .hitomi {
            return start * Constants.hitomiAnimOffset
        }
        
        return start
    }
    
    func duration(_ character: PlayableCharacterID) -> TimeInterval {
        let duration = Double(endFrame(character) - startFrame(character)) / 30.0
        
        if character == .hitomi {
            return duration * Constants.hitomiAnimOffset
        }
        return duration
    }
    
    func startFrame(_ character: PlayableCharacterID) -> Int {
        guard let timestamps = ARSessionManager.shared.getStartFrames(from: character.name) else {
            return 0
        }
        
        switch self {
        case .idle:
            return timestamps.idle
        case .run:
            return timestamps.run
        case .idle_to_action:
            return timestamps.idle_to_action
        case .battle_idle:
            return timestamps.battle_idle
        case .normal_attack:
            return timestamps.normal_attack
        case .skill:
            return timestamps.skill
        case .defeat:
            return timestamps.defeat
        case .victory:
            return timestamps.victory
        }
    }
    
    func endFrame(_ character: PlayableCharacterID) -> Int {
        guard let timestamps = ARSessionManager.shared.getEndFrames(from: character.name) else {
            return 0
        }
        
        switch self {
        case .idle:
            return timestamps.idle
        case .run:
            return timestamps.run
        case .idle_to_action:
            return timestamps.idle_to_action
        case .battle_idle:
            return timestamps.battle_idle
        case .normal_attack:
            return timestamps.normal_attack
        case .skill:
            return timestamps.skill
        case .defeat:
            return timestamps.defeat
        case .victory:
            return timestamps.victory
        }
    }

    func animId(character: String) -> String {
        return "\(character)_\(self.rawValue)"
    }
}

