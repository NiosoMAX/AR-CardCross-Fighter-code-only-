//
//  MovementSystem.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 12/12/24.
//

import Foundation
import RealityKit

struct CPURivalControlComponent: Component {
    var stateMachine: CPURivalStateMachine
    
    init(model: ModelEntity, id: PlayableCharacterID) {
        self.stateMachine = CPURivalStateMachine(model: model, id: id)
    }
    
    var isMoving: Bool {
        return stateMachine.stateContext.isMoving
    }
    
    var id: PlayableCharacterID {
        return stateMachine.stateContext.myID
    }
    
    var distance: Float {
        return stateMachine.stateContext.referenceDistance
    }
    
    func defeat() {
        stateMachine.stateMachine.enter(DefeatAIState.self)
    }
}

class CPURivalControlSystem: System {
    required init(scene: Scene) {}
    
    private static let query = EntityQuery(where: .has(CPURivalControlComponent.self))
    
    // Identities
    private var me: Entity? = nil
    private var myRival: Entity? = nil
    
    func update(context: SceneUpdateContext) {
        context.scene.performQuery(Self.query).forEach{ eligibleEntity in
            if ARBattleDelegate.shared.isGameActive() {
                guard let controlComp = eligibleEntity.components[CPURivalControlComponent.self]
                else { return }
                
                controlComp.stateMachine.update(deltaTime: context.deltaTime)
                
                eligibleEntity.components[CPURivalControlComponent.self] = controlComp
            }
        }
    }
}
