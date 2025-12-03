//
//  CharacterStateMachine.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 24/1/25.
//

import Foundation
import RealityKit
import GameplayKit

class CharacterStateMachine {
    var stateMachine: GKStateMachine
    
    var idleState: IdleAnimState
    var idleToActionState: IdleToActionAnimState
    var battleIdleState: BattleIdleAnimState
    var runState: RunAnimState
    var attackState: AttackAnimState
    var skillState: SkillAnimState
    var victoryState: VictoryAnimState
    var defeatState: DefeatAnimState
    
    init(entity: ModelEntity, anims: AnimationLibraryComponent) {
        self.idleState = IdleAnimState(model: entity, animation: anims)
        self.idleToActionState = IdleToActionAnimState(model: entity, animation: anims)
        self.battleIdleState = BattleIdleAnimState(model: entity, animation: anims)
        self.runState = RunAnimState(model: entity, animation: anims)
        self.attackState = AttackAnimState(model: entity, animation: anims)
        self.skillState = SkillAnimState(model: entity, animation: anims)
        self.victoryState = VictoryAnimState(model: entity, animation: anims)
        self.defeatState = DefeatAnimState(model: entity, animation: anims)
        
        self.stateMachine = GKStateMachine(states: [
            idleState, idleToActionState, battleIdleState,
            runState, attackState, skillState,
            victoryState, defeatState
        ])
        
        self.stateMachine.enter(IdleAnimState.self)
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
        if currentState is IdleAnimState {
            if newState == IdleToActionAnimState.self {
                return true
            }
        }
        
        if currentState is IdleToActionAnimState {
            if newState == BattleIdleAnimState.self {
                return true
            }
        }
        
        if currentState is BattleIdleAnimState {
            if newState == RunAnimState.self {
                return true
            }
            
            if newState == AttackAnimState.self {
                return true
            }
            
            if newState == SkillAnimState.self {
                return true
            }
            
            if newState == VictoryAnimState.self {
                return true
            }
            
            if newState == DefeatAnimState.self {
                return true
            }
        }
        
        if currentState is RunAnimState {
            if newState == BattleIdleAnimState.self {
                return true
            }
            
            if newState == AttackAnimState.self {
                return true
            }
            
            if newState == SkillAnimState.self {
                return true
            }
            
            if newState == VictoryAnimState.self {
                return true
            }
            
            if newState == DefeatAnimState.self {
                return true
            }
        }
        
        if currentState is AttackAnimState {
            if newState == BattleIdleAnimState.self {
                return true
            }
            
            if newState == RunAnimState.self {
                return true
            }
            
            if newState == VictoryAnimState.self {
                return true
            }
            
            if newState == DefeatAnimState.self {
                return true
            }
        }
        
        if currentState is SkillAnimState {
            if newState == BattleIdleAnimState.self {
                return true
            }
            
            if newState == RunAnimState.self {
                return true
            }
            
            if newState == VictoryAnimState.self {
                return true
            }
            
            if newState == DefeatAnimState.self {
                return true
            }
        }
        
        if currentState is VictoryAnimState {
            if newState == IdleAnimState.self {
                return true
            }
        }
        
        if currentState is DefeatAnimState {
            if newState == IdleAnimState.self {
                return true
            }
        }
        
        return false
    }
}
