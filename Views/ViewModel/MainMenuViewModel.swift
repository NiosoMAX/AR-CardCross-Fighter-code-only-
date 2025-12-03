//
//  MainMenuViewDelegate.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 17/12/24.
//

import Foundation
import Combine

@MainActor
class MainMenuViewModel: ObservableObject {
    @Published var isLoading: Bool
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        self.isLoading = false
        ARSessionManager.shared.streamIsLoading
            .sink { [weak self] status in
                print("Loading screen order: \(status.description)")
                self?.isLoading = status
            }
            .store(in: &cancellables)
    }
}
