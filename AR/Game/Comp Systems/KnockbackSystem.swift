//
//  StunSystem.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 19/1/25.
//

import Foundation
import RealityKit

class KnockbackComponent: Component {
    private var _strength: Float = .zero
    private var _angle: Float = .zero
    private var spamGuard: Bool = false
    
    var isKnockedBack: Bool {
        return spamGuard
    }
    
    var strength: Float {
        get {
            return _strength
        }
    }
    
    var angle: Float {
        return _angle
    }
    
    func setKnockback(strength: Float, angle: Float = .zero) {
        guard !spamGuard else { return }
        
        _strength = strength
        _angle = angle
        spamGuard = true
        Timer.scheduledTimer(withTimeInterval: Constants.knockbackDuration, repeats: false) { _ in
            self.reset()
        }
    }
    
    func reset() {
        self._strength = .zero
        self._angle = .zero
        self.spamGuard = false
    }
}

class KnockbackSystem: System {
    required init(scene: Scene) {
    }
    
    private static let query = EntityQuery(where: .has(KnockbackComponent.self))
    
    private var lastState: Bool = false
    
    func update(context: SceneUpdateContext) {
        context.scene.performQuery(Self.query).forEach{ eligibleEntity in
            guard let knockbackComp = eligibleEntity.components[KnockbackComponent.self] else {
                return
            }
            
            guard ARBattleDelegate.shared.isGameActive() else {
                knockbackComp.reset()
                return
            }
            
            if (lastState == false && knockbackComp.isKnockedBack) {
                knockback(model: eligibleEntity, info: knockbackComp)
            }
            
            eligibleEntity.components[KnockbackComponent.self] = knockbackComp
        }
    }
    
    private func knockback(model: Entity, info: KnockbackComponent) {
        // Rotation
        guard !info.isKnockedBack else { return }
        
        let invertedRotation = simd_quatf(angle: info.angle, axis: [0, 1, 0])
        model.transform.rotation = invertedRotation
        
        let forwardDir = model.transform.forwardVector
        let displacement = forwardDir * info.strength
        model.transform.translation += displacement
    }
}
