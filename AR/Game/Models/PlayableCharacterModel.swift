//
//  PlayableCharacter.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 30/12/24.
//

import Foundation
import RealityKit
import SwiftUIJoystick
import GameplayKit
import RealityCollisions

class PlayableCharacterModel {
    private var _name: String = ""
    private var _id: PlayableCharacterID? = nil
    private var _data: CharacterData? = nil
    private var _isPlayer: Bool = false
    var rootPosition: Entity
    var model: ModelEntity
    
    var name: String {
        get {
            return _name
        }
    }
    
    var data: CharacterData {
        get {
            return _data!
        }
        set {
            _data = newValue
        }
    }
    
    var id: PlayableCharacterID {
        get {
            return _id!
        }
    }
    
    var hp: Double {
        get {
            guard let hpComp = model.components[HealthComponent.self] else {
                return 0
            }
            return hpComp.HP
        }
    }
    
    init(model: ModelEntity) {
        self.model = model
        self._isPlayer = false
        self.rootPosition = Entity()
        setCharacter()
        setCPUControl()
    }
    
    init(model: ModelEntity, jsMonitor: JoystickMonitor){
        self.model = model
        self._isPlayer = true
        self.rootPosition = Entity()
        setCharacter()
        setPlayable(monitor: jsMonitor)
    }
    
    private func setCharacter() {
        _name = model.name
        guard let id = PlayableCharacterID.idFromName(_name),
              let myData = ARSessionManager.shared.getCharData(from: _name)
        else {
            print("Unknown registered character \(_name)")
            return
        }
        _id = id
        _data = myData
        let myPos: FighterPosition
        if (_isPlayer) {
            myPos = .player1
        } else {
            myPos = .player2
        }
        
        model.components[NormalAttackComponent.self] = NormalAttackComponent(
            damage: _data!.normal_attack.damage,
            type: _data!.normal_attack.type,
            initialDelay: _data!.normal_attack.initialDelay,
            duration: _data!.normal_attack.duration,
            attacker: myPos,
            totalDuration: getAttackAnimDuration()
            
        )
        model.components[SkillComponent.self] = SkillComponent(
            damage: _data!.skill.damage,
            cooldown: _data!.skill.cooldown,
            initialDelay: _data!.skill.initialDelay,
            duration: _data!.skill.duration,
            type: _data!.skill.type,
            attacker: myPos,
            totalDuration: getSkillAnimDuration()
        )
        model.components[HealthComponent.self] = HealthComponent(id: id, pos: myPos)
        model.components[KnockbackComponent.self] = KnockbackComponent()
        model.components[AttackDelayComponent.self] = AttackDelayComponent()
        
        if (_data!.createConvex) {
            createConvexCollision()
        } else {
            model.generateCollisionShapes(recursive: false)
        }
    }
    
    func setPlayable(monitor: JoystickMonitor){
        let rotation = model.transform.rotation
        let angle = 2 * acos(rotation.vector.w)
        let angleInDegrees = angle * 180 / .pi
        
        model.components[JoystickControlComponent.self] = JoystickControlComponent(joystickMonitor: monitor, lastRotation: angleInDegrees)
        model.setNewCollisionFilter(belongsToGroup: GameCollisionGroups.player, andCanCollideWith: [.rival, .rivalAtk])
    }
    
    func reset() {
        model.components[JoystickControlComponent.self] = nil
        model.components[CPURivalControlComponent.self] = nil
        model.components[CollisionComponent.self] = nil
        model.components[KnockbackComponent.self] = nil
        guard var hpComp = model.components[HealthComponent.self] else {
            return
        }
        hpComp.HP = Constants.defaultMaxHP
        model.components[HealthComponent.self] = hpComp
    }
    
    private func setCPUControl() {
        model.components[CPURivalControlComponent.self] = CPURivalControlComponent(model: model, id: _id!)
        model.setNewCollisionFilter(belongsToGroup: GameCollisionGroups.rival, andCanCollideWith: [GameCollisionGroups.player, .playerAtk])
    }
    
    // MARK: RealityKit
    
    private func createConvexCollision() {
        let convex = ShapeResource.generateConvex(from: model.model!.mesh)
        model.components[CollisionComponent.self] = CollisionComponent(shapes: [convex])
    }
    
    // MARK: Animations
    func victoryAnimation(){
        guard let stateMachineComp = model.components[AnimationStateMachineComponent.self] else {
            return
        }
        
        stateMachineComp.stateMachine.changeState(to: VictoryAnimState.self)
    }
    
    private func getAttackAnimDuration() -> TimeInterval {
        guard let animComp = model.components[AnimationLibraryComponent.self] else {
            return .zero
        }
        
        return animComp.animations[CharacterAnimationType.normal_attack.rawValue]?.definition.duration ?? .zero
    }
    
    private func getSkillAnimDuration() -> TimeInterval {
        guard let animComp = model.components[AnimationLibraryComponent.self] else {
            return .zero
        }
        
        return animComp.animations[CharacterAnimationType.skill.rawValue]?.definition.duration ?? .zero
    }
    
    
    // MARK: Public actions
    func attack() {
        guard let naComp = model.components[NormalAttackComponent.self],
              let skillComp = model.components[SkillComponent.self],
              let stateMachineComp = model.components[AnimationStateMachineComponent.self]
        else {
            return
        }
        
        guard !skillComp.isAttacking() && !naComp.isAttacking() else {
            print("Can't activate attack - \(id.name) is already attacking!")
            return
        }
        
        naComp.performAttack()
        stateMachineComp.stateMachine.stateMachine.enter(AttackAnimState.self)
    }
    
    func skill() {
        guard let naComp = model.components[NormalAttackComponent.self],
              let skillComp = model.components[SkillComponent.self],
              let stateMachineComp = model.components[AnimationStateMachineComponent.self]
        else {
            return
        }
        
        guard !skillComp.isAttacking() && !naComp.isAttacking() else {
            print("Can't activate skill - \(id.name) is already attacking!")
            return
        }
        
        guard !skillComp.isInCooldown() else {
            print("Can't activate skill - \(id.name)'s skill is loading!")
            return
        }
        
        skillComp.activateSkill()
        stateMachineComp.stateMachine.stateMachine.enter(SkillAnimState.self)
    }
    
    func receiveAttack(dmg: Double, strength: Float, angle: Float) {
        guard var hpComp = model.components[HealthComponent.self],
              let stunComp = model.components[KnockbackComponent.self]
        else {
            return
        }
        
        guard !stunComp.isKnockedBack else { return }
        
        hpComp.HP -= dmg
        
        model.components[HealthComponent.self] = hpComp
        
        guard hpComp.HP > 0 else { return }
        
        stunComp.setKnockback(strength: strength, angle: angle)
        model.components[KnockbackComponent.self] = stunComp
        
        if hpComp.HP > 0 {
            AudioManager.shared.playVoiceLine(for: model, line: .damage)
        }
    }
}
