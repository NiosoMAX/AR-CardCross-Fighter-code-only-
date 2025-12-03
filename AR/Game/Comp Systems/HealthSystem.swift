//
//  HealthSystem.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 4/1/25.
//

import Foundation
import RealityKit

struct HealthComponent: Component {
    private var _HP: Double = Constants.defaultMaxHP
    private var _maxHP: Double = Constants.defaultMaxHP
    var id: PlayableCharacterID
    var pos: FighterPosition
    
    init(id: PlayableCharacterID, pos: FighterPosition) {
        self.id = id
        self.pos = pos
    }
    
    var HP: Double {
        get {
            return _HP
        }
        set {
            _HP = newValue
        }
    }
    
    var maxHP: Double {
        get {
            return _maxHP
        }
    }
}

class HealthSystem: System {
    required init(scene: Scene) {}
    
    private static let query = EntityQuery(where: .has(HealthComponent.self))
    
    func update(context: SceneUpdateContext) {
        context.scene.performQuery(Self.query).forEach{ eligibleEntity in
            guard var hpComp = eligibleEntity.components[HealthComponent.self] else {
                return
            }
            
            if hpComp.HP >= hpComp.maxHP {
                hpComp.HP = hpComp.maxHP
            }
            
            if hpComp.HP <= 0 {
                hpComp.HP = 0
                
                if let stateMachineComp = eligibleEntity.components[AnimationStateMachineComponent.self] {
                    stateMachineComp.stateMachine.changeState(to: DefeatAnimState.self)
                }
                
                if let cpuComp = eligibleEntity.components[CPURivalControlComponent.self] {
                    cpuComp.defeat()
                }
                
                ARBattleDelegate.shared.win(loserPosition: hpComp.pos, loserID: hpComp.id)
            }
            
            eligibleEntity.components[HealthComponent.self] = hpComp
        }
    }
}
