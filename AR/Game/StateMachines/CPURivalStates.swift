//
//  CPURivalStates.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 25/1/25.
//

import Foundation
import GameplayKit
import RealityKit

class IdleAIState: GKState {
    unowned let model: ModelEntity
    let context: CPURivalStateContext
    var letsThink: Bool = false
    var timer: Timer?
    
    init(model: ModelEntity, context: CPURivalStateContext) {
        self.model = model
        self.context = context
    }
    
    override func didEnter(from previousState: GKState?) {
        print("Entrando en Idle")
        context.isMoving = false
        context.updateAllpositions(newSelfPosition: model.worldPosition)
        
        switch(context.nextAction){
        case .attack:
            context.nextAction = .move
            stateMachine?.enter(AttackAIState.self)
        case .skill:
            context.nextAction = .move
            stateMachine?.enter(SkillAIState.self)
        case .move:
            if letsThink {
                let thinkingTime = TimeInterval.random(in: Constants.thinkingTimeRange)
                timer = Timer.scheduledTimer(withTimeInterval: thinkingTime, repeats: false) {_ in
                    self.stateMachine?.enter(MoveAIState.self)
                }
            } else {
                letsThink = true
                timer = Timer.scheduledTimer(withTimeInterval: Constants.noThinkingTime, repeats: false) {_ in 
                    self.stateMachine?.enter(MoveAIState.self)
                }
            }
            break
        }
    }
    
    override func willExit(to nextState: GKState) {
        timer?.invalidate()
        timer = nil
    }
    
    private func rotateToPlayer() {
        let dirXZ = SIMD3<Float>(context.direction.x, 0, context.direction.z)
        let angle = atan2(dirXZ.x, dirXZ.z)
        let rotation = simd_quatf(angle: angle, axis: simd_float3(0, 1, 0))
        
        var myTransform = model.worldTransform
        myTransform.rotation = rotation
        
        model.move(to: myTransform, relativeTo: nil, duration: Constants.rotationDuration)
    }
}

class MoveAIState: GKState {
    unowned let model: ModelEntity
    let context: CPURivalStateContext
    var timer: Timer?
    
    init(model: ModelEntity, context: CPURivalStateContext) {
        self.model = model
        self.context = context
    }
    
    override func didEnter(from previousState: GKState?) {
        print("Entrando en Move")
        context.isMoving = true
        context.updateAllpositions(newSelfPosition: model.worldPosition)
        timer = Timer.scheduledTimer(withTimeInterval: Constants.maxMoveTime, repeats: false) { _ in
            self.context.nextAction = .move
            self.stateMachine?.enter(IdleAIState.self)
        }
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        calculateCurrentDistance()
        
        if context.currentDistance >= Constants.HardMaxDistance {
            model.position = .zero
            context.nextAction = .move
            stateMachine?.enter(IdleAIState.self)
        }
        
        if context.currentDistance >= Constants.SoftMaxDistance && context.currentDistance < Constants.SoftMaxDistance {
            context.nextAction = .move
            stateMachine?.enter(IdleAIState.self)
        }

        moveCharacter(deltaTime: seconds, direction: context.direction, backwards: context.movingBackwards)
        
        switch (context.myID){
        case .hitomi:
            if context.currentDistance < Constants.HitomiMinDistance {
                self.attackModusOperandi()
            }
            break
        case .miki:
            break
        }
        
        if context.currentDistance <= Constants.AbsoluteMinDistance {
            nextAction()
        }
    }
    
    override func willExit(to nextState: GKState) {
        print("Exiting move")
        context.isMoving = false
        context.updateAllpositions(newSelfPosition: model.worldPosition)
        rotateToPlayer()
        timer?.invalidate()
        timer = nil
    }
    
    private func calculateCurrentDistance(){
        context.currentDistance = simd_length(context.referencePos - model.worldTransform.translation)
        //print("Current distance: \(context.currentDistance) - Pos: \(model.worldPosition.debugDescription) - Looking for: \(context.referencePos.debugDescription)")
    }
    
    private func moveCharacter(deltaTime: TimeInterval, direction: SIMD3<Float>, backwards: Bool = false){
        let movSpd = Constants.playerSpeed * Float(deltaTime)
        
        // Calcular dirección
        var rotDir = simd_float3(direction.x, 0, direction.z)
        if length(rotDir) > 0 {
            rotDir = normalize(rotDir)
        }
        
        if (backwards) {
            rotDir *= -1
        }
        
        // Posición
        var newPosition = model.position
        newPosition += rotDir * movSpd
        model.position = newPosition
        
        // Rotación
        let angle = atan2(rotDir.x, rotDir.z)
        if (angle != 0) {
            context.lastRotation = angle
        }
        let rotation = simd_quatf(angle: context.lastRotation, axis: simd_float3(0, 1, 0))
        
        model.transform.rotation = rotation
    }
    
    private func nextAction(){
        switch (context.myID){
        case .hitomi:
            if context.currentDistance < Constants.HitomiMinDistance {
                attackModusOperandi()
            } else {
                context.nextAction = .move
            }
        case .miki:
            if context.currentDistance <= Constants.MikiMinDistance {
                attackModusOperandi()
            } else {
                context.nextAction = .move
            }
            break
        }
        stateMachine?.enter(IdleAIState.self)
    }
    
    private func attackModusOperandi() {
        guard let skillComp = model.components[SkillComponent.self] else {
            print("Error: No skill component for rival!")
            return
        }
        
        if !skillComp.isInCooldown() {
            context.nextAction = .skill
            
            let chanceToAttack = Double.random(in: Constants.probabilityRange)
            
            if chanceToAttack <= Constants.chanceToAttack {
                context.nextAction = .attack
            }
        } else {
            context.nextAction = .attack
        }
    }
    
    private func rotateToPlayer() {
        let dirXZ = SIMD3<Float>(context.direction.x, 0, context.direction.z)
        let angle = atan2(dirXZ.x, dirXZ.z)
        let rotation = simd_quatf(angle: angle, axis: simd_float3(0, 1, 0))
        
        model.transform.rotation = rotation
    }
}

class AttackAIState: GKState {
    unowned let model: ModelEntity
    let context: CPURivalStateContext
    var timer: Timer?
    
    init(model: ModelEntity, context: CPURivalStateContext) {
        self.model = model
        self.context = context
    }
    
    override func didEnter(from previousState: GKState?) {
        print("Take this!")
        context.isMoving = false
        guard let attackComp = model.components[NormalAttackComponent.self] else { return }
        ARBattleDelegate.shared.attack(to: .toPlayer)
        
        timer = Timer.scheduledTimer(withTimeInterval: attackComp.attack.totalDuration, repeats: false) { _ in
            self.stateMachine?.enter(IdleAIState.self)
        }
    }
    
    override func willExit(to nextState: GKState) {
        timer?.invalidate()
        timer = nil
    }
}

class SkillAIState: GKState {
    unowned let model: ModelEntity
    let context: CPURivalStateContext
    var timer: Timer?
    
    init(model: ModelEntity, context: CPURivalStateContext) {
        self.model = model
        self.context = context
    }
    
    override func didEnter(from previousState: GKState?) {
        print("Coaxial Edge!")
        context.isMoving = false
        guard let skillComp = model.components[SkillComponent.self] else { return }
        ARBattleDelegate.shared.skill(to: .toPlayer)
        
        timer = Timer.scheduledTimer(withTimeInterval: skillComp.skill.totalDuration, repeats: false) { _ in
            self.stateMachine?.enter(IdleAIState.self)
        }
    }
    
    override func willExit(to nextState: GKState) {
        timer?.invalidate()
        timer = nil
    }
}

class DefeatAIState: GKState {
    unowned let model: ModelEntity
    let context: CPURivalStateContext
    var isOver: Bool = false
    
    init(model: ModelEntity, context: CPURivalStateContext) {
        self.model = model
        self.context = context
    }
    
    override func didEnter(from previousState: GKState?) {
        guard !isOver else { return }
        isOver = true
    }
}
