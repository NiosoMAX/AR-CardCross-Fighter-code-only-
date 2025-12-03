//
//  HPBarViewController.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 10/12/24.
//

import Foundation

class HPBarViewModel: ObservableObject {
    @Published var valHP: Double
    @Published var maxHP: Double
    @Published var name: String = ""
    
    init(maxHP: Double) {
        self.maxHP = maxHP
        self.valHP = maxHP
    }
    
    init(maxHP: Double, name: String) {
        self.maxHP = maxHP
        self.valHP = maxHP
        self.name = name
    }
    
    public func setHP(val: Double) {
        self.valHP = val
    }
    
    public func receiveAttack(damage: Double) {
        self.valHP -= damage
    }
}
