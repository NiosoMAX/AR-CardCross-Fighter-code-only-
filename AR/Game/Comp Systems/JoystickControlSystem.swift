//
//  JoystickControlSystem.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 13/12/24.
//

import Foundation
import Combine
import RealityKit
import simd
import SwiftUIJoystick

struct JoystickControlComponent: Component {
    var joystickMonitor:JoystickMonitor
    var speed: Float = Constants.playerSpeed
    var isMoving: Bool = false
    var lastFrameState = false
    var lastRotation: Float = 0
    
    init(joystickMonitor: JoystickMonitor, lastRotation: Float) {
        self.joystickMonitor = joystickMonitor
        self.lastRotation = lastRotation
    }
}

class JoystickControlSystem: System {
    private static let query = EntityQuery(where: .has(JoystickControlComponent.self))
    
    
    
    required init(scene: RealityKit.Scene) {
    }
    
    var requiredComponent: [Component.Type] = [JoystickControlComponent.self]
    
    func update(context: SceneUpdateContext) {
        let delta = context.deltaTime
        context.scene.performQuery(Self.query).forEach{ eligibleEntity in
            guard var movComp = eligibleEntity.components[JoystickControlComponent.self],
                  let atkComp = eligibleEntity.components[NormalAttackComponent.self],
                  let skillComp = eligibleEntity.components[SkillComponent.self],
                  let healthComp = eligibleEntity.components[HealthComponent.self]
            else {
                return
            }
            
            guard ARBattleDelegate.shared.isGameActive(), !atkComp.isAttacking(), !skillComp.isAttacking() else {
                movComp.isMoving = false
                return
            }
            
            guard healthComp.HP > 0 else {
                return
            }
            
//            guard stunComp.value == 0 else {
//                movComp.isMoving = false
//                return
//            }
            
            let jsX = movComp.joystickMonitor.xyPoint.x
            let jsY = movComp.joystickMonitor.xyPoint.y
            let movSpd = movComp.speed * Float(delta)
            
            // Calcular dirección
            var rotDir = simd_float3(Float(jsX), 0, Float(jsY))
            if length(rotDir) > 0 {
                rotDir = normalize(rotDir)
            }
            
            // Posición
            var newPosition = eligibleEntity.position
            newPosition += rotDir * movSpd
            eligibleEntity.position = newPosition
            
            // Rotación
            let angle = atan2(rotDir.x, rotDir.z)
            if (angle != 0) {
                movComp.lastRotation = angle
            }
            let rotation = simd_quatf(angle: movComp.lastRotation, axis: simd_float3(0, 1, 0))
            
            eligibleEntity.transform.rotation = rotation
            
            // Animación
            if (rotDir != .zero) {
                movComp.isMoving = true
            } else {
                movComp.isMoving = false
            }
            
            eligibleEntity.components[JoystickControlComponent.self] = movComp
        }
    }
}
