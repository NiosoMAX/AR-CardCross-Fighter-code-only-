//
//  JoystickView.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 1/12/24.
//

import SwiftUI
import SwiftUIJoystick

public struct Joystick: View {
        @ObservedObject public var joystickMonitor: JoystickMonitor
    
        private let dragDiameter: CGFloat
        private let shape: JoystickShape
    
        public init(monitor: JoystickMonitor, width: CGFloat, shape: JoystickShape = .rect) {
            self.joystickMonitor = monitor
            self.dragDiameter = width
            self.shape = shape
        }
        
        public var body: some View {
            VStack{
                JoystickBuilder(
                    monitor: self.joystickMonitor,
                    width: self.dragDiameter,
                    shape: .circle,
                    background: {
                        // Example Background
                        Circle().fill(Color.gray.opacity(0.5))
                    },
                    foreground: {
                        // Example Thumb
                        Circle().fill(Color.white.opacity(0.8))
                    },
                    locksInPlace: false)
            }
        }
}

#Preview {
    Joystick(monitor: JoystickMonitor(), width: 100)
}
