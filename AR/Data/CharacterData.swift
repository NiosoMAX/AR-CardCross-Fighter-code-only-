//
//  CharacterData.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 9/12/24.
//

import Foundation

class CharacterData: Identifiable, Codable {
    var id: String {name}
    let name: String
    let full_name: String
    let descripcion_1: String
    let descripcion_2: String
    let voice: String
    let normal_attack: NormalAttackData
    let skill: SkillData
    let createConvex: Bool
    let animStart: AnimTimestamps
    let animEnd: AnimTimestamps
}

class NormalAttackData: Codable {
    let damage: Double
    let type: NormalAttackType
    let initialDelay: Double
    let duration: Double
}

class SkillData: Codable {
    let damage: Double
    let type: SkillType
    let cooldown: Double
    let initialDelay: Double
    let duration: Double
}

class AnimTimestamps: Codable {
    let idle: Int
    let idle_to_action: Int
    let battle_idle: Int
    let run: Int
    let normal_attack: Int
    let skill: Int
    let defeat: Int
    let victory: Int
}
