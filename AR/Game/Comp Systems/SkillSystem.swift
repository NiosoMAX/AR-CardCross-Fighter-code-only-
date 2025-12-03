//
//  MikiSystem.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 3/1/25.
//

import Foundation
import RealityKit

struct SkillComponent: Component {
    var skill: SkillAttackModel
    
    init(damage: Double, cooldown: TimeInterval, initialDelay: TimeInterval, duration: TimeInterval, type: SkillType, attacker: FighterPosition, totalDuration: TimeInterval) {
        self.skill = SkillAttackModel(
            damage: damage,
            cooldown: cooldown,
            initialDelay: initialDelay,
            duration: duration,
            type: type,
            attacker: attacker,
            totalDuration: totalDuration)
    }
    
    func activateSkill(){
        skill.startDelay()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + skill.totalDuration) {
            self.skill.isAttacking = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + skill.initialDelay){
            skill.createAttack()
        }
    }
    
    func isInCooldown() -> Bool {
        print("Cooldown: \(skill.currentCooldown) - \(skill.currentCooldown > .zero)")
        return skill.currentCooldown > .zero
    }
    
    func isAttacking() -> Bool {
        return skill.isAttacking
    }
}

class SkillSystem: System {
    required init(scene: Scene) {}
    
    private static let query = EntityQuery(where: .has(SkillComponent.self))
    
    func update(context: SceneUpdateContext) {
        context.scene.performQuery(Self.query).forEach{ eligibleEntity in
            guard let skillComp = eligibleEntity.components[SkillComponent.self] else {
                return
            }
            
            guard ARBattleDelegate.shared.isGameActive() else {
                skillComp.skill.currentCooldown = 0
                return
            }
            
            var myCooldown = skillComp.skill.currentCooldown
            
            if (myCooldown > 0) {
                //print("Bajando cooldown: \(skillComp.skill.currentCooldown)")
                let delta = context.deltaTime
                myCooldown -= delta
                
                if myCooldown < 0 { myCooldown = 0 }
                
                skillComp.skill.currentCooldown = myCooldown
                
                if (skillComp.skill.attackerPos == .player1) {
                    ARBattleDelegate.shared.sendPlayerSkillCooldown(cd: skillComp.skill.currentCooldown)
                }
            }
            
            eligibleEntity.components[SkillComponent.self] = skillComp
        }
    }
    
}
