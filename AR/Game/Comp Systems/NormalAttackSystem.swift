//
//  HitomiSystem.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 3/1/25.
//

import Foundation
import RealityKit

struct NormalAttackComponent: Component {
    var attack: NormalAttackModel
    var acceleration: Float = 1
    
    init(damage: Double, type: NormalAttackType, initialDelay: TimeInterval, duration: TimeInterval, attacker: FighterPosition, totalDuration: TimeInterval) {
        self.attack = NormalAttackModel(
            damage: damage,
            initialDelay: initialDelay,
            effectDuration: duration,
            attacker: attacker,
            attackType: type,
            totalDuration: totalDuration
        )
    }
    
    func performAttack(){
        attack.startDelay()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + attack.totalDuration) {
            self.attack.isAttacking = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + attack.initialDelay){
            attack.createAttack()
        }
    }
    
    func isAttacking() -> Bool {
        return attack.isAttacking
    }
}

class NormalAttackSystem: System {
    required init(scene: Scene) {}
    
    private static let query = EntityQuery(where: .has(NormalAttackComponent.self))
    
    func update(context: SceneUpdateContext) {
        context.scene.performQuery(Self.query).forEach{ eligibleEntity in
            guard var atkComp = eligibleEntity.components[NormalAttackComponent.self] else {
                return
            }
            
            if atkComp.attack.attackEntity == nil {
                atkComp.attack.projectileDir = .zero
            }
            
            if atkComp.attack.attackType == .projectile {
                let delta = context.deltaTime
                let orientation = simd_make_float3(eligibleEntity.transform.matrix.columns.2)
                guard let projectileModel = atkComp.attack.attackEntity else {
                    return
                }
                
                if (atkComp.attack.projectileDir == .zero) {
                    atkComp.attack.projectileDir = orientation
                    atkComp.acceleration = 0
                }
                
                atkComp.acceleration += Constants.projectileAcceleration * Float(delta)
                let distance = atkComp.attack.projectileSpd + atkComp.acceleration
                let displacement = distance * atkComp.attack.projectileDir * Float(delta)
                
                projectileModel.position += displacement
                //print("ACC: \(atkComp.acceleration), distance: \(distance)")
            }
            
            eligibleEntity.components[NormalAttackComponent.self] = atkComp
        }
    }
}
