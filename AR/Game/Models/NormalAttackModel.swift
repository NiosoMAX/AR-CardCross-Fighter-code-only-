//
//  AttackModel.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 6/1/25.
//

import Foundation
import RealityKit

class NormalAttackModel: BaseAttackModel {
    var attackType: NormalAttackType
    
    // Projectile only
    var projectileSpd = Constants.projectileSpd
    var projectileDir: simd_float3 = .zero
    
    init(damage: Double,
         initialDelay: TimeInterval,
         effectDuration: TimeInterval,
         attacker: FighterPosition,
         attackType: NormalAttackType,
         projectileSpd: Float = Constants.projectileSpd,
         totalDuration: TimeInterval
    ) {
        self.attackType = attackType
        self.projectileSpd = projectileSpd
        super.init(damage: damage, initialDelay: initialDelay, effectDuration: effectDuration, type: .normalAttackDMG, attacker: attacker, totalDuration: totalDuration)
    }
    
    override func createAttack(){
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
        
        switch (attackType){
        case .melee:
            createHitbox(attackerModel: attackerModel, isPlayer: isPlayer)
        case .projectile:
            createProjectile(attackerModel: attackerModel, isPlayer: isPlayer, id: charId)
            break
        }
    }
    
    
    // MARK: Model creation
    
    private func createHitbox(attackerModel: ModelEntity, isPlayer: Bool) {
        if attackEntity == nil {
            print("Generating Hitbox")
            let box = MeshResource.generateBox(width: Constants.hitboxWidth, height: 1, depth: Constants.hitboxDepth)
            
            let metalMat = createTransparentMaterial()
            let hitBox = ModelEntity(mesh: box, materials: [metalMat])
            hitBox.name = "\(TextConstants.hitbox)_\(attackerModel.name)_\(TextConstants.normal_attack)"
            hitBox.position = SIMD3<Float>(x: 0, y: Constants.hitboxHeight, z: Constants.hitboxOffset)
            
            setCollisions(attack: hitBox, isPlayer: isPlayer)
            addCollisionATKListening(onEntity: hitBox, isFromAlly: isPlayer, damage: damage, type: .normalAttackDMG)
            
            attackerModel.addChild(hitBox)
            self.attackEntity = hitBox
            
            AudioManager.shared.playSFX(for: hitBox, sound: .sword1)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + attackDuration) {
                self.eraseAttack(model: hitBox)
            }
        }
    }
    
    private func createProjectile(attackerModel: ModelEntity, isPlayer: Bool, id: PlayableCharacterID){
        if attackEntity == nil {
            print("Creating projectile")
            let sphere = MeshResource.generateSphere(radius: Constants.projectileRadius)
            let lumMat = UnlitMaterial(color: .yellow)
            let projectileModel = ModelEntity(mesh: sphere, materials: [lumMat])
            projectileModel.name = "\(TextConstants.projectile)_\(attackerModel.name)_\(TextConstants.normal_attack)"
            projectileModel.transform.rotation = attackerModel.transform.rotation
            projectileModel.position = attackerModel.position
            projectileModel.position = simd_float3(x: projectileModel.position.x, y: Constants.projectileHeight, z: projectileModel.position.z)
            
            setCollisions(attack: projectileModel, isPlayer: isPlayer)
            addCollisionATKListening(onEntity: projectileModel, isFromAlly: isPlayer, damage: damage, type: .normalAttackDMG)
            ARBattleDelegate.shared.imgAnchors[id]?.addChild(projectileModel)
            
            self.attackEntity = projectileModel
            
            AudioManager.shared.playSFX(for: projectileModel, sound: .shot)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + attackDuration) {
                self.eraseAttack(model: projectileModel)
            }
        }
    }
    
    private func setCollisions(attack: ModelEntity, isPlayer: Bool) {
        switch (attackType){
        case .melee:
            attack.collision = CollisionComponent(
                shapes: [.generateBox(size: [Constants.hitboxWidth, 1, Constants.hitboxDepth])],
                mode: .trigger
            )
        case .projectile:
            attack.collision = CollisionComponent(
                shapes: [.generateBox(size: [Constants.projectileRadius, Constants.projectileRadius, Constants.projectileRadius])],
                mode: .trigger
            )
        }
        
        if isPlayer {
            attack.setNewCollisionFilter(belongsToGroup: GameCollisionGroups.playerAtk, andCanCollideWith: [.rival])
        } else {
            attack.setNewCollisionFilter(belongsToGroup: GameCollisionGroups.rivalAtk, andCanCollideWith: [GameCollisionGroups.player])
        }
        
        print("Collisions set")
    }
}
