//
//  Constants.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 12/12/24.
//

import Foundation

struct Constants {
    // Game
    static let defaultMaxHP: Double = 200
    static let defaultCountdown = 3
    static let playerSpeed: Float = 5
    static let cpuSpeed: Float = 1.5
    
    // Animations
    static let defaultTransitionValue = 0.2
    static let rotationDuration: TimeInterval = 0.75
    static let rotationSpd: Float = 0.8
    static let attackAnimationOffset: TimeInterval = 0.35
    static let victoryAnimationDelay: TimeInterval = 2.5
    static let showScreenDelay: TimeInterval = 3.0
    static let knockbackSmallDistance: Float = 0.5
    static let knockbackBigDistance: Float = 1.5
    static let knockbackDuration: TimeInterval = 0.15
    static let hitomiAnimOffset: TimeInterval = 1.25 // For reasons I cannot understand, with the sword model the animations go slower
    
    // Model sizes
    static let defaultModelScale: Float = 0.02
    static let selectMeshSize: Float = 80
    static let hitboxWidth: Float = 50
    static let hitboxDepth: Float = 50
    static let hitboxHeight: Float = 95
    static let hitboxOffset: Float = 50
    static let aoeSize: Float = 120
    static let aoeOffset: Float = 50
    static let defaultTextBoxSize = 200
    static let voiceTextHeight = 100
    
    // Beam
    static let beamLength: Float = 10
    static let beamSize: Float = 0.95
    static let beamOffset: Float = beamLength / 2
    
    // Projectile
    static let projectileRadius: Float = 0.05 // El tamaño es independiente de los modelos de personaje
    static let projectileSpd: Float = 350
    static let projectileAcceleration: Float = 7.5
    static let projectileHeight: Float = 2
    
    // Behaviour
    static let HitomiMinDistance: Float = 2
    static let MikiMinDistance: Float = 3.5
    static let MikiMaxDistance: Float = 8
    static let SoftMaxDistance: Float = 15
    static let HardMaxDistance: Float = 20
    static let AbsoluteMinDistance: Float = 1.5
    static let chanceToAttack: Double = 0.6
    static let noThinkingTime: TimeInterval = 0.35
    static let maxMoveTime: TimeInterval = 2.5
    
    // Ranges
    static let rotationSaltRange: Range<Float> = Float(0)..<Float(2.5)
    static let thinkingTimeRange: Range<TimeInterval> = 1.15..<2.5
    static let probabilityRange: ClosedRange<Double> = 0.0...1.0
}

struct SkeletonConstants {
    static let rightHandIndex = 40
}

struct TextConstants {
    static let title = "AR CardCross Fighter"
    static let mainButtonBattleMSG = "Battle"
    static let mainButtonInfoMSG = "Character Info"
    static let loading = "Loading..."
    static let initInfoMSG = "Scan a compatible character card to learn more about them."
    static let initBattleMSG = "Scan and gather 2 compatible character cards to start a battle."
    static let hp = "HP"
    static let player1 = "Player 1"
    static let player2 = "Player 2"
    static let msg_winner_end = "wins!"
    static let normal_attack = "Attack"
    static let skill = "Skill"
    static let restart = "Restart"
    static let hitbox = "Hitbox"
    static let melee = "Melee"
    static let projectile = "Projectile"
    static let aoe = "AoE"
    static let beam = "Beam"
    static let go = "FIGHT!"
    static let changeChar = "Change character"
    static let yourFighter = "Your Fighter"
    static let fight = "Fight!"
    static let modelSufix = "Full"
    static let modelExtension = "usdz"
    static let modelRightHand = "RightHand"
    static let characterVoice = "CV"
}

struct VoiceLinesConstants {
    static let presentation = "Presentation"
}

struct SoundConstants {
    static let musicVolume: Float = 0.2
    static let musicVolumeBattle: Float = 0.05
    static let musicVolumeBattleEnd: Float = 0.02
    static let SFXVolume: Float = 0.4
    static let beamVolume: Float = 0.1
}

struct GameState {
    static let detectCharacters = 0       // Buscar dos personajes
    static let combatConfirmation = 1     // Confirmar a los combatientes y ajustar parámetros de batalla
    static let aboutToBattle = 2          // Cuenta atrás antes del combate
    static let combatPlay = 3             // Combate
    static let victory = 4                // Victoria de un personaje
}

struct InfoActions {
    static let infoPoint = "Info Dot_"
}
