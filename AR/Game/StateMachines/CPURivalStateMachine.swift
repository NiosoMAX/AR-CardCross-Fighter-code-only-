//
//  CPURivalStateMachine.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 25/1/25.
//

import Foundation
import RealityKit
import GameplayKit

class CPURivalStateContext {
    var myID: PlayableCharacterID
    var referencePos: SIMD3<Float> = .zero
    var myPos: SIMD3<Float> = .zero
    var referenceDistance: Float = 0.0
    var currentDistance: Float = 0.0
    var direction: SIMD3<Float> = .zero
    var lastRotation: Float = 0.0
    var nextAction: CPUActionType = .move
    
    var isMoving: Bool = false
    var movingBackwards: Bool = false
    
    init(myID: PlayableCharacterID) {
        self.myID = myID
    }
    
    func updateAllpositions(newSelfPosition: SIMD3<Float>) {
        myPos = newSelfPosition
        referencePos = ARBattleDelegate.shared.gameManager.player1!.model.worldPosition
        calculatePositionVariables()
    }
    
    func calculatePositionVariables() {
        guard referencePos != .zero, myPos != .zero else { return }
        
        direction = referencePos - myPos
        referenceDistance = simd_length(direction)
    }
}

class CPURivalStateMachine {
    var stateMachine: GKStateMachine
    var stateContext: CPURivalStateContext
    
    var idleState: IdleAIState
    var moveState: MoveAIState
    var attackState: AttackAIState
    var skillState: SkillAIState
    var defeatState: DefeatAIState
    
    init(model: ModelEntity, id: PlayableCharacterID) {
        self.stateContext = CPURivalStateContext(myID: id)
        
        self.idleState = IdleAIState(model: model, context: stateContext)
        self.moveState = MoveAIState(model: model, context: stateContext)
        self.attackState = AttackAIState(model: model, context: stateContext)
        self.skillState = SkillAIState(model: model, context: stateContext)
        self.defeatState = DefeatAIState(model: model, context: stateContext)
        
        self.stateMachine = GKStateMachine(states: [
            idleState, moveState, attackState, skillState, defeatState
        ])
        
        self.stateMachine.enter(IdleAIState.self)
    }
    
    func update(deltaTime: TimeInterval) {
        stateMachine.update(deltaTime: deltaTime)
    }
    
    func changeState(to state: GKState.Type) {
        guard let currentState = stateMachine.currentState else {
            print("State machine has no current state")
            return
        }
        
        guard validateTransition(from: currentState, to: state) else {
            //print("Transition from \(currentState.description) to \(state.description()) is not valid")
            return
        }
        
        stateMachine.enter(state)
    }
    
    private func validateTransition(from currentState: GKState, to newState: GKState.Type) -> Bool {
        if currentState is IdleAIState {
            if newState == MoveAIState.self {
                return true
            }
            
            if newState == AttackAIState.self {
                return true
            }
            
            if newState == SkillAIState.self {
                return true
            }
            
            if newState == DefeatAIState.self {
                return true
            }
        }
        
        if currentState is MoveAIState {
            if newState == IdleAIState.self {
                return true
            }
            
            if newState == DefeatAIState.self {
                return true
            }
        }
        
        if currentState is AttackAIState {
            if newState == IdleAIState.self {
                return true
            }
            
            if newState == DefeatAIState.self {
                return true
            }
        }
        
        if currentState is SkillAIState {
            if newState == IdleAIState.self {
                return true
            }
            
            if newState == DefeatAIState.self {
                return true
            }
        }
        
        if currentState is DefeatAIState {
            if newState == IdleAIState.self {
                return true
            }
        }
        
        return false
    }
}
