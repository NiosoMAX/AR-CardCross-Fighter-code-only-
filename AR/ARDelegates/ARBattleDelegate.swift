//
//  RealityKitARView.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 17/11/24.
//

import Foundation
import ARKit
import RealityKit
import Combine
import SwiftUIJoystick

final class ARBattleDelegate: NSObject, ARSessionDelegate, ObservableObject {
    static var shared = ARBattleDelegate()
    var session: ARSession
    var gameManager = GameManager()
    
    // Entities
    var characters = [PlayableCharacterID : ModelEntity]()
    var imgAnchors = [PlayableCharacterID : AnchorEntity]()
    var selectEntities = [PlayableCharacterID: Entity]()
    var visibleCharacters: [PlayableCharacterID?] = [nil, nil]
    
    //var animations: [PlayableCharacterID : [CharacterAnimationType : Entity]] = [:]
    
    // Auxiliaries
    var joystickMonitor = JoystickMonitor()
    
    private override init() {
        self.session = ARSession()
        super.init()
        self.session.delegate = self
        self.freeMemory()
    }
    
    // MARK: AR session
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let imageAnchor = anchor as? ARImageAnchor {
                // Setting
                let imageAnchorEntity = AnchorEntity(.anchor(identifier: imageAnchor.identifier))
                ARSessionManager.shared.arView?.scene.addAnchor(imageAnchorEntity)
                
                let name = imageAnchor.name!
                
                guard let id = PlayableCharacterID(rawValue: name) else {
                    continue
                }
                
                guard characters[id] == nil else {
                    print("Prevented loading \(name) more than once")
                    continue
                }
                
                let modelName = "\(name)_\(TextConstants.modelSufix)"
                print("Loading: \(modelName)")
                
                guard let url = Bundle.main.url(forResource: modelName, withExtension: TextConstants.modelExtension) else {
                    print("Model url for \(modelName) is not valid")
                    continue
                }
                
                guard let model = try? ModelEntity.loadModel(contentsOf: url) else {
                    print("Error loading model \(modelName)")
                    continue
                }
                
                model.name = name
                model.scale = SIMD3<Float>(Constants.defaultModelScale, Constants.defaultModelScale, Constants.defaultModelScale)
                model.physicsBody = PhysicsBodyComponent(massProperties: .default, mode: .kinematic)
                
                self.gameManager.selectedPlayableCharacter = id
                self.gameManager.sendPlayableChar()
                self.createSelectionModel(character: model, id: id)
                
                imageAnchorEntity.addChild(model)
                ARSessionManager.shared.arView?.scene.addAnchor(imageAnchorEntity)
                characters[id] = model
                imgAnchors[id] = imageAnchorEntity
                
                // Animations
                var animLibrary = AnimationLibraryComponent()
                for animID in CharacterAnimationType.allCases {
                    let allAnimations = model.availableAnimations.first!
                    let def = allAnimations.definition.trimmed(start: animID.startTime(id), duration: animID.duration(id))
                    guard let trimmedAnim = try? AnimationResource.generate(with: def) else {
                        print("Error creating the trimmed animation for \(animID.rawValue)")
                        continue
                    }
                    animLibrary.animations[animID.rawValue] = trimmedAnim
                }
                model.components[AnimationLibraryComponent.self] = animLibrary
                model.playAnimation(animLibrary.animations[CharacterAnimationType.idle.rawValue]!, transitionDuration: 0.1, startsPaused: false)
                
                model.components[AnimationStateMachineComponent.self] = AnimationStateMachineComponent(model: model, anims: animLibrary)
                AudioManager.shared.playVoiceLine(for: model, line: .start)
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Detect if at least 2 cards are in view
        let detectedImageAnchors = frame.anchors.filter { imgAnchor in
            guard let imageAnchor = imgAnchor as? ARImageAnchor else { return false }
            return imageAnchor.isTracked
        }

        // Activate UI as long as both cards are active
        if detectedImageAnchors.count == 2 && characters.count >= 2 {
            // Al cambiar de fase 0 a 1, se activa el aura de selección
            if (gameManager.gameState == GameState.detectCharacters && selectEntities.count != 0){
                selectEntities[gameManager.selectedPlayableCharacter]?.isEnabled = true
            }
            
            gameManager.sendShowGameUI(true)
            //print("Activando GameUI")
        } else {
            gameManager.sendShowGameUI(false)
            gameManager.gameState = GameState.detectCharacters
            
            //print("Desactivando GameUI")
        }
        
        // Characters detected
        if detectedImageAnchors.count == 2 {
            guard let name1 = detectedImageAnchors[0].name, let name2 = detectedImageAnchors[1].name else { return }
            
            guard let character1 = PlayableCharacterID.idFromName(name1),
                  let character2 = PlayableCharacterID.idFromName(name2)
            else {return}
            
            visibleCharacters[0] = character1
            visibleCharacters[1] = character2
        } else {
            if (visibleCharacters[0] != nil) {
                characters[visibleCharacters[0]!]?.transform.rotation = simd_quatf(angle: .zero, axis: simd_float3(0, 1, 0))
            }
            
            if (visibleCharacters[1] != nil) {
                characters[visibleCharacters[1]!]?.transform.rotation = simd_quatf(angle: .zero, axis: simd_float3(0, 1, 0))
            }
            
            visibleCharacters[0] = nil
            visibleCharacters[1] = nil
        }
    }
    
    // MARK: Models
    // Loading functions are no longer necessary but are conserved in case I need something from them

    func loadModel(from url: URL, anchorEntity: AnchorEntity, name: String, id: PlayableCharacterID) {
        loadAllUSDZFiles(name: name, id: id, anchorEntity: anchorEntity)
    }
    
    func loadAllUSDZFiles(name: String, id: PlayableCharacterID, anchorEntity: AnchorEntity){
        let group = DispatchGroup()
        var models: [CharacterAnimationType: ModelEntity] = [:]
        
        for animID in CharacterAnimationType.allCases {
            let animName = animID.animId(character: name)
            group.enter()
            DispatchQueue.global().async {
                Task {
                    let model = await self.loadUSDZFile(named: animName)
                    DispatchQueue.main.async {
                        models[animID] = model
                        print("Model \(animName) loaded")
                        group.leave()
                    }
                }
            }
        }
        
        //group.notify(queue: .main) {
            //print("Todos los archivos han sido procesados. Contenido:\n\(models)")
//            let model = models[.idle]!
//            model.name = name
//            self.imgAnchors[id] = anchorEntity
//            
//            // Modificaciones adicionales
//            model.scale = SIMD3(x: 0.02, y: 0.02, z: 0.02)
//            model.physicsBody = PhysicsBodyComponent(massProperties: .default, mode: .kinematic)
//            
//            self.gameManager.selectedPlayableCharacter = id
//            self.gameManager.sendPlayableChar()
//            self.createSelectionModel(character: model, id: id)
//            
//            // Registrar personaje
//            anchorEntity.addChild(model)
//            self.loadedCharacters[id] = model
//            self.animations[id] = models
//            ARSessionManager.shared.arView?.scene.addAnchor(anchorEntity)
//            
//            // Registrar animaciones
//            var animLibrary = AnimationLibraryComponent()
//            for animID in CharacterAnimationType.allCases {
//                animLibrary.animations[animID.rawValue] = self.animations[id]?[animID]?.availableAnimations[0]
//                print("\(animID.rawValue) loaded on \(id)")
//            }
//            model.components[AnimationLibraryComponent.self] = animLibrary
        //}
    }
    
    func loadUSDZFile(named: String) async -> ModelEntity {
        let model = try! await ModelEntity(named: named)
        return model
    }
    
    func createSelectionModel(character: ModelEntity, id: PlayableCharacterID) {
        // Model creation
        var selectMat = UnlitMaterial(color: .green)
        selectMat.blending = .transparent(opacity: 0.5)
        let selectMesh = MeshResource.generatePlane(width: Constants.selectMeshSize, depth: Constants.selectMeshSize, cornerRadius: 50)
        let selectEntity = ModelEntity(mesh: selectMesh, materials: [selectMat])
        
        // Configuration and deployment
        character.addChild(selectEntity)
        selectEntity.isEnabled = false
        selectEntities[id] = selectEntity
    }
    
    // MARK: Game
    
    func isGameActive() -> Bool {
        return gameManager.gameState == GameState.combatPlay
    }
    
    func getPlayer1() -> PlayableCharacterID {
        return gameManager.player1!.id
    }
    
    func getPlayer2() -> PlayableCharacterID {
        return gameManager.player2!.id
    }
    
    func startCountdown() {
        guard let character1 = visibleCharacters[0],
              let character2 = visibleCharacters[1] else {
            print("Can't start countdown: at least one character hasn't been detected")
            return
        }
        
        if gameManager.gameState == GameState.combatConfirmation {
            charactersLookIntoEachOther(character1, character2)
            gameManager.sendStartCountdown()
        }
    }
    
    func startGame() {
        if gameManager.gameState == GameState.aboutToBattle {
            let playerCharacter = gameManager.selectedPlayableCharacter
            guard let rivalCharacter = visibleCharacters.first(where: {$0 != playerCharacter}) else {
                print("Game cannot start: Missing the rival character")
                return
            }
            gameManager.startGame(player1Model: characters[playerCharacter]!, player2Model: characters[rivalCharacter!]!, monitor: joystickMonitor)
            gameManager.gameState = GameState.combatPlay
            gameManager.lastActiveGameState = GameState.combatPlay
            gameManager.sendIsGameActive(true)
        }
    }
    
    func togglePlayers() {
        guard selectEntities.count == 2,
              gameManager.gameState == GameState.combatConfirmation
        else { return }
        
        guard visibleCharacters[0] != nil, visibleCharacters[1] != nil else {
            print("Not enough visible playable characters to toggle")
            return
        }
        
        let previouslySelectedChar = visibleCharacters.first(where: {$0 == gameManager.selectedPlayableCharacter})
        let newSelectionChar = visibleCharacters.first(where: {$0 != gameManager.selectedPlayableCharacter})
        gameManager.selectedPlayableCharacter = newSelectionChar!!
        selectEntities[previouslySelectedChar!!]!.isEnabled = false
        selectEntities[newSelectionChar!!]!.isEnabled = true
        gameManager.sendPlayableChar()
    }
    
    func attack(to target: AttackTarget){
        //print("Sending attack")
        gameManager.attack(to: target)
    }
    
    func skill(to target: AttackTarget){
        //print("Activating skill")
        gameManager.skill(to: target)
    }
    
    func sendPlayerSkillCooldown(cd: TimeInterval){
        gameManager.sendCooldown(cd)
    }
    
    func win(loserPosition: FighterPosition, loserID: PlayableCharacterID) {
        Timer.scheduledTimer(withTimeInterval: Constants.victoryAnimationDelay, repeats: false) { _ in
            self.gameManager.win(loserPosition: loserPosition, loserID: loserID)
        }
    }
    
    func restart(){
        for character in characters.values {
            character.position = .zero
            character.transform.rotation = .identity
        }
        gameManager.restart()
    }
    
    func freeMemory() {
        for index in characters.keys {
            characters[index] = nil
        }
        
        for index in imgAnchors.keys {
            imgAnchors[index] = nil
        }
        
        for index in selectEntities.keys {
            selectEntities[index] = nil
        }
        
        visibleCharacters[0] = nil
        visibleCharacters[1] = nil
    }
    
    // MARK: Animations
    
    func charactersLookIntoEachOther(_ character1: PlayableCharacterID, _ character2: PlayableCharacterID) {
        guard characters[character1] != nil, characters[character2] != nil else { return }
        let pos1 = characters[character1]!.worldPosition
        let pos2 = characters[character2]!.worldPosition
        
        let direction = pos2 - pos1
        let opposedDirection = pos1 - pos2
        
        let angle = atan2(direction.x, direction.z)
        let opposedAngle = atan2(opposedDirection.x, opposedDirection.z)
        
        let rotation = simd_quatf(angle: angle, axis: simd_float3(0, 1, 0))
        let opposedRotation = simd_quatf(angle: opposedAngle, axis: simd_float3(0, 1, 0))
        
        var transform1 = characters[character1]!.worldTransform
        var transform2 = characters[character2]!.worldTransform
        
        transform1.rotation = rotation
        transform2.rotation = opposedRotation
        
        characters[character1]!.move(to: transform1, relativeTo: nil, duration: Constants.rotationDuration)
        characters[character2]!.move(to: transform2, relativeTo: nil, duration: Constants.rotationDuration)
        
//        characters[character1]!.transform.rotation = rotation
//        characters[character2]!.transform.rotation = opposedRotation
    }
}
