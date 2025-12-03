//
//  BaseAttackModel.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 19/1/25.
//

import Foundation
import RealityKit
import Combine
import UIKit

protocol Attack {
    var attackEntity: ModelEntity? { get set }
    var damage: Double { get }
    var damageType: DMGType { get }
    var initialDelay: TimeInterval { get set }
    var currentDelay: TimeInterval { get set }
    var totalDuration: TimeInterval { get }
    var attackDuration: TimeInterval { get set }
    var isAttacking: Bool { get set }
    var attackerPos: FighterPosition { get }
    
    func createAttack()
    func eraseAttack(model: ModelEntity)
    func addCollisionATKListening(onEntity entity: Entity & HasCollision, isFromAlly: Bool, damage: Double, type: DMGType)
}

class BaseAttackModel: Attack {
    var attackEntity: ModelEntity?
    var damage: Double
    var damageType: DMGType
    var attackDuration: TimeInterval
    var initialDelay: TimeInterval
    var currentDelay: TimeInterval = 0.0
    var isAttacking: Bool = false
    var totalDuration: TimeInterval = 0.0
    
    var attackerPos: FighterPosition
    
    private var collisionSubscriptions = [Cancellable]()
    
    init(damage: Double, initialDelay: TimeInterval, effectDuration: TimeInterval, type: DMGType, attacker: FighterPosition, totalDuration: TimeInterval) {
        self.damage = damage
        self.damageType = type
        self.initialDelay = initialDelay
        self.attackDuration = effectDuration
        self.attackerPos = attacker
        self.totalDuration = totalDuration
    }
    
    func createAttack() {
        //print("Use override to create the attack")
    }
    
    func eraseAttack(model: ModelEntity) {
        model.removeFromParent()
        self.attackEntity = nil
    }
    
    func startDelay() {
        isAttacking = true
        currentDelay = initialDelay
    }
    
    func createTransparentMaterial () -> SimpleMaterial {
        var material = SimpleMaterial()
        material.tintColor = UIColor.init(
            red: 1.0,
            green: 1.0,
            blue: 1.0,
            alpha: 0.025)
        material.baseColor = MaterialColorParameter.color(UIColor.red)
        return material
    }
    
    
    func addCollisionATKListening(onEntity entity: Entity & HasCollision, isFromAlly: Bool, damage: Double, type: DMGType) {
        collisionSubscriptions.append((ARSessionManager.shared.arView?.scene.subscribe(to: CollisionEvents.Began.self, on: entity) { event in
            print(event.entityA.name, "collided with", event.entityB.name, " - From player: \(isFromAlly)")
            if (isFromAlly) {
                guard event.entityB.name == ARBattleDelegate.shared.getPlayer2().name else {
                    print("Prevented a collided false positive with rival")
                    return
                }
                ARBattleDelegate.shared.gameManager.sendAttack(.toRival(amount: damage), type: type)
            } else {
                guard event.entityB.name == ARBattleDelegate.shared.getPlayer1().name else {
                    print("Prevented a collided false positive with player")
                    return
                }
                ARBattleDelegate.shared.gameManager.sendAttack(.toPlayer(amount: damage), type: type)
            }
        })!)
    }
    
}
