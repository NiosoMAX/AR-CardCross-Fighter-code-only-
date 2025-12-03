//
//  AttackDelaySystem.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 22/1/25.
//

import Foundation
import RealityKit

struct AttackDelayComponent: Component {
    var delayingATK: Bool = false
    var delayingSkill: Bool = false
}

class AttackDelaySystem: System {
    static var dependencies: [SystemDependency] {
        [.before(NormalAttackSystem.self), .before(SkillSystem.self)]
    }
    
    required init(scene: Scene) {
    }
    
    private static let query = EntityQuery(where: .has(KnockbackComponent.self))
    
    func update(context: SceneUpdateContext) {
        context.scene.performQuery(Self.query).forEach{ eligibleEntity in
            guard var delayComp = eligibleEntity.components[AttackDelayComponent.self],
            let attackComp = eligibleEntity.components[NormalAttackComponent.self],
            let skillComp = eligibleEntity.components[SkillComponent.self] else {
                return
            }
            
            if (attackComp.attack.currentDelay > 0){
                //print("Delay started for NA")
                delayComp.delayingATK = true
            }
            
            if (skillComp.skill.currentDelay > 0){
                //print("Delay started for skill")
                delayComp.delayingSkill = true
            }
            
            if (delayComp.delayingATK) {
                var myDelay = attackComp.attack.currentDelay
                let delta = context.deltaTime
                myDelay -= delta
                
                if myDelay < 0 {
                    myDelay = 0
                    delayComp.delayingATK = false
                }
                
                //print("Attack delay: \(myDelay)")
                
                attackComp.attack.currentDelay = myDelay
            }
            
            if (delayComp.delayingSkill) {
                var myDelay = skillComp.skill.currentDelay
                let delta = context.deltaTime
                myDelay -= delta
                
                if myDelay < 0 {
                    skillComp.skill.currentDelay = 0
                    delayComp.delayingSkill = false
                }
                
                //print("Skill delay: \(myDelay)")
                
                skillComp.skill.currentDelay = myDelay
            }
        }
    }
}
