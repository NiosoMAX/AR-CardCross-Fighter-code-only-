//
//  CharacterAnimationStates.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 24/1/25.
//

import Foundation
import RealityKit
import GameplayKit

class IdleAnimState: GKState {
    unowned let model: ModelEntity
    let animation: AnimationLibraryComponent
    
    init(model: ModelEntity, animation: AnimationLibraryComponent) {
        self.model = model
        self.animation = animation
    }
    
    override func didEnter(from previousState: GKState?) {
//        print("Entrando en Idle")
        model.playAnimation(animation.animations[CharacterAnimationType.idle.rawValue]!.repeat(duration: .infinity), transitionDuration: Constants.defaultTransitionValue, startsPaused: false)
    }
}

class IdleToActionAnimState: GKState {
    unowned let model: ModelEntity
    let animation: AnimationLibraryComponent
    
    init(model: ModelEntity, animation: AnimationLibraryComponent) {
        self.model = model
        self.animation = animation
    }
    
    override func didEnter(from previousState: GKState?) {
//        print("Entrando en Transition")
        let anim = animation.animations[CharacterAnimationType.idle_to_action.rawValue]
        model.playAnimation(anim!, transitionDuration: Constants.defaultTransitionValue, startsPaused: false)
        
        Timer.scheduledTimer(withTimeInterval: anim!.definition.duration, repeats: false) { _ in
            self.stateMachine!.enter(BattleIdleAnimState.self)
        }
    }
}

class BattleIdleAnimState: GKState {
    unowned let model: ModelEntity
    let animation: AnimationLibraryComponent
    
    init(model: ModelEntity, animation: AnimationLibraryComponent) {
        self.model = model
        self.animation = animation
    }
    
    override func didEnter(from previousState: GKState?) {
        //print("Entrando en Battle Idle")
        model.playAnimation(animation.animations[CharacterAnimationType.battle_idle.rawValue]!.repeat(duration: .infinity), transitionDuration: Constants.defaultTransitionValue, startsPaused: false)
    }
}

class RunAnimState: GKState {
    unowned let model: ModelEntity
    let animation: AnimationLibraryComponent
    
    init(model: ModelEntity, animation: AnimationLibraryComponent) {
        self.model = model
        self.animation = animation
    }
    
    override func didEnter(from previousState: GKState?) {
//        print("Entrando en Run")
        model.playAnimation(animation.animations[CharacterAnimationType.run.rawValue]!.repeat(duration: .infinity), transitionDuration: Constants.defaultTransitionValue, startsPaused: false)
    }
}

class AttackAnimState: GKState {
    unowned let model: ModelEntity
    let animation: AnimationLibraryComponent
    
    init(model: ModelEntity, animation: AnimationLibraryComponent) {
        self.model = model
        self.animation = animation
    }
    
    override func didEnter(from previousState: GKState?) {
        AudioManager.shared.playVoiceLine(for: model, line: .attack)
        model.playAnimation(animation.animations[CharacterAnimationType.normal_attack.rawValue]!, transitionDuration: Constants.defaultTransitionValue, startsPaused: false)
    }
}

class SkillAnimState: GKState {
    unowned let model: ModelEntity
    let animation: AnimationLibraryComponent
    
    init(model: ModelEntity, animation: AnimationLibraryComponent) {
        self.model = model
        self.animation = animation
    }
    
    override func didEnter(from previousState: GKState?) {
        AudioManager.shared.playVoiceLine(for: model, line: .skill)
        model.playAnimation(animation.animations[CharacterAnimationType.skill.rawValue]!, transitionDuration: Constants.defaultTransitionValue, startsPaused: false)
    }
}

class VictoryAnimState: GKState {
    unowned let model: ModelEntity
    let animation: AnimationLibraryComponent
    
    init(model: ModelEntity, animation: AnimationLibraryComponent) {
        self.model = model
        self.animation = animation
    }
    
    override func didEnter(from previousState: GKState?) {
        AudioManager.shared.playVoiceLine(for: model, line: .victory)
        model.playAnimation(animation.animations[CharacterAnimationType.victory.rawValue]!, transitionDuration: Constants.defaultTransitionValue, startsPaused: false)
    }
}

class DefeatAnimState: GKState {
    unowned let model: ModelEntity
    let animation: AnimationLibraryComponent
    
    init(model: ModelEntity, animation: AnimationLibraryComponent) {
        self.model = model
        self.animation = animation
    }
    
    override func didEnter(from previousState: GKState?) {
        AudioManager.shared.playVoiceLine(for: model, line: .defeat)
        model.playAnimation(animation.animations[CharacterAnimationType.defeat.rawValue]!, transitionDuration: Constants.defaultTransitionValue, startsPaused: false)
    }
}
