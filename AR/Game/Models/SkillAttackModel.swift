//
//  SkillAttackModel.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 7/1/25.
//

import Foundation
import RealityKit

class SkillAttackModel: BaseAttackModel {
    var skillType: SkillType
    var cooldown: TimeInterval
    var currentCooldown: TimeInterval = 0.0
    
    init(damage: Double,
         cooldown: TimeInterval,
         initialDelay: TimeInterval,
         duration: TimeInterval,
         type: SkillType,
         attacker: FighterPosition,
         totalDuration: TimeInterval) {
        self.skillType = type
        self.cooldown = cooldown
        super.init(damage: damage, initialDelay: initialDelay, effectDuration: duration, type: .skillDMG, attacker: attacker, totalDuration: totalDuration)
    }
    
    override func createAttack(){
        guard currentCooldown == 0.0 else {
            print("La skill se está ejecutando")
            return
        }
        let attackerModel: ModelEntity
        let isPlayer: Bool
        let charId: PlayableCharacterID
        switch (attackerPos){
        case .player1:
            attackerModel = ARBattleDelegate.shared.gameManager.player1!.model
            charId = ARBattleDelegate.shared.gameManager.player1!.id
            isPlayer = true
        case .player2:
            attackerModel = ARBattleDelegate.shared.gameManager.player2!.model
            charId = ARBattleDelegate.shared.gameManager.player2!.id
            isPlayer = false
        }
        
        switch (skillType){
        case .aoe:
            createAoEHitbox(attackerModel: attackerModel, isPlayer: isPlayer)
        case .beam:
            createBeam(attackerModel: attackerModel, isPlayer: isPlayer, id: charId)
            break
        }
        currentCooldown = cooldown
    }
    
    private func createAoEHitbox(attackerModel: ModelEntity, isPlayer: Bool) {
        if attackEntity == nil {
            print("Creating AoE Hitbox")
            let box = MeshResource.generateBox(width: Constants.aoeSize, height: 1, depth: Constants.aoeSize)
            // TODO: Cambiar por material invisible cuando las animaciones 3D funcionen
            let metalMat = createTransparentMaterial()
            let hitBox = ModelEntity(mesh: box, materials: [metalMat])
            hitBox.name = "\(TextConstants.hitbox)_\(attackerModel.name)_\(TextConstants.normal_attack)"
            hitBox.position = SIMD3<Float>(x: 0, y: Constants.hitboxHeight, z: Constants.aoeOffset)
            
            setCollisions(attack: hitBox, isPlayer: isPlayer)
            addCollisionATKListening(onEntity: hitBox, isFromAlly: isPlayer, damage: damage, type: .skillDMG)
            
            attackerModel.addChild(hitBox)
            self.attackEntity = hitBox
            
            AudioManager.shared.playSFX(for: hitBox, sound: .sword2)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + attackDuration) {
                self.eraseAttack(model: hitBox)
            }
        }
    }
    
    private func createBeam(attackerModel: ModelEntity, isPlayer: Bool, id: PlayableCharacterID) {
        if attackEntity == nil {
            print("Creating beam")
            let box = MeshResource.generateBox(width: Constants.beamSize, height: Constants.beamSize, depth: Constants.beamLength, cornerRadius: 20)
            let lumMat = UnlitMaterial(color: .yellow)
            let beamModel = ModelEntity(mesh: box, materials: [lumMat])
            beamModel.name = "\(TextConstants.projectile)_\(attackerModel.name)_\(TextConstants.normal_attack)"
            beamModel.transform.rotation = attackerModel.transform.rotation
            
            let beamDirection = beamModel.transform.rotation.act(SIMD3<Float>(0, 0, 1))
            beamModel.position = attackerModel.position + beamDirection * Constants.beamOffset
            beamModel.position = simd_float3(x: beamModel.position.x, y: Constants.projectileHeight, z: beamModel.position.z)

            setCollisions(attack: beamModel, isPlayer: isPlayer)
            addCollisionATKListening(onEntity: beamModel, isFromAlly: isPlayer, damage: damage, type: .skillDMG)
            
            ARBattleDelegate.shared.imgAnchors[id]?.addChild(beamModel)
            
            self.attackEntity = beamModel
            
            AudioManager.shared.playSFX(for: beamModel, sound: .beam)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + attackDuration) {
                self.eraseAttack(model: beamModel)
            }
        }
    }
    
    private func setCollisions(attack: ModelEntity, isPlayer: Bool) {
        switch (skillType){
        case .aoe:
            attack.collision = CollisionComponent(
                shapes: [.generateBox(size: [Constants.aoeSize, 1, Constants.aoeSize])],
                mode: .trigger
            )
        case .beam:
            attack.collision = CollisionComponent(
                shapes: [.generateBox(size: [Constants.beamSize, Constants.beamSize, Constants.beamLength])],
                mode: .trigger
            )
        }
        
        if isPlayer {
            attack.setNewCollisionFilter(belongsToGroup: GameCollisionGroups.playerAtk, andCanCollideWith: [.rival])
        } else {
            attack.setNewCollisionFilter(belongsToGroup: GameCollisionGroups.rivalAtk, andCanCollideWith: [.player])
        }
    }
}
