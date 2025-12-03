//
//  CharacterAnimStateMachineSystem.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 22/1/25.
//

import Foundation
import RealityKit

struct AnimationStateMachineComponent: Component {
    var stateMachine: CharacterStateMachine
    
    init(model: ModelEntity, anims: AnimationLibraryComponent) {
        self.stateMachine = CharacterStateMachine(entity: model, anims: anims)
    }
}

class AnimationStateMachineSystem: System {
    static var dependencies: [SystemDependency] {
        [.after(NormalAttackSystem.self), .after(SkillSystem.self), .after(JoystickControlSystem.self), .after(CPURivalControlSystem.self)]
    }
    
    required init(scene: Scene) {
    }
    
    private static let query = EntityQuery(where: .has(AnimationStateMachineComponent.self))
    
    private var previousState = GameState.detectCharacters
    
    func update(context: SceneUpdateContext) {
        context.scene.performQuery(Self.query).forEach{ eligibleEntity in
            guard let stateMachineComp = eligibleEntity.components[AnimationStateMachineComponent.self] else {
                return
            }
            
            let currentState = ARBattleDelegate.shared.gameManager.gameState
            
            if (!ARBattleDelegate.shared.isGameActive() && currentState != GameState.victory) {
                stateMachineComp.stateMachine.changeState(to: IdleAnimState.self)
            }
            
            // When the battle starts, both characters prepare themselves
            if (currentState == GameState.aboutToBattle) {
                //battleInitSequence()
                stateMachineComp.stateMachine.changeState(to: IdleToActionAnimState.self)
            }
            
            if (currentState == GameState.combatPlay){
                
                guard let attackComp = eligibleEntity.components[NormalAttackComponent.self],
                      !attackComp.isAttacking()
                else {
                    return
                }
                
                guard let skillComp = eligibleEntity.components[SkillComponent.self],
                      !skillComp.isAttacking()
                else {
                    return
                }
                
                handleIdleRun(stateMachine: stateMachineComp, subject: eligibleEntity)
            }
            
            
            // Finishing
            previousState = ARBattleDelegate.shared.gameManager.gameState
            eligibleEntity.components[AnimationStateMachineComponent.self] = stateMachineComp
            //print("Previous: \(previousState)")
        }
    }

    func handleIdleRun(stateMachine: AnimationStateMachineComponent, subject: Entity){
        if let joystickComp = subject.components[JoystickControlComponent.self] {
            if (joystickComp.isMoving) {
                stateMachine.stateMachine.changeState(to: RunAnimState.self)
            } else {
                stateMachine.stateMachine.changeState(to: BattleIdleAnimState.self)
            }
        }
        
        if let cpuControlComp = subject.components[CPURivalControlComponent.self] {
            if (cpuControlComp.isMoving) {
                stateMachine.stateMachine.changeState(to: RunAnimState.self)
            } else {
                stateMachine.stateMachine.changeState(to: BattleIdleAnimState.self)
            }
        }
    }
}
