//
//  ARManager.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 19/11/24.
//

import Combine
import ARKit
import RealityKit

class ARSessionManager {
    static let shared = ARSessionManager()
    
    // AR
    var session: ARSession
    var arView: ARView? = nil
    
    // Data loaded
    var charData: [String: CharacterData] = [:]
    var loadedUSDZFiles: [PlayableCharacterID : [CharacterAnimationType : Entity]] = [:]
    var streamIsLoading = PassthroughSubject<Bool, Never>()
    
    private init() {
        self.session = ARSession()
        let conf = getImgTrackingConfiguration()
        self.session.run(conf)
        
        loadCharacterData()
        AudioManager.shared.playMusic(track: .theme)
        
        //loadVoiceLines()
        //loadAllUSDZFiles()
    }
    
    // MARK: Loading data
    
    func loadCharacterData() {
        guard let url = Bundle.main.url(forResource: "CharacterData", withExtension: "json") else {
            print("No se han encontrado los datos")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let charArray = try decoder.decode([CharacterData].self, from: data)
            
            charData = Dictionary(uniqueKeysWithValues: charArray.map{($0.id, $0)})
            //print("Exito al cargar")
        } catch {
            print("Error al cargar los datos: \(error)")
        }
    }
    
    func loadRealityKitSystems() {
        CPURivalControlSystem.registerSystem()
        JoystickControlSystem.registerSystem()
        NormalAttackSystem.registerSystem()
        SkillSystem.registerSystem()
        HealthSystem.registerSystem()
        KnockbackSystem.registerSystem()
        AttackDelaySystem.registerSystem()
        AnimationStateMachineSystem.registerSystem()
    }
    
    // Loading USDZ files individually is no longer necessary, but I keep it just in case
    func loadAllUSDZFiles() {
        for charId in PlayableCharacterID.allCases {
            DispatchQueue.global().async {
                Task {
                    await self.loadCharacterUSDZFiles(id: charId)
                }
            }
        }
    }
    
    func loadCharacterUSDZFiles(id: PlayableCharacterID) async {
        var models: [CharacterAnimationType: ModelEntity] = [:]
        var tareas: [Task<(CharacterAnimationType, ModelEntity), Never>] = []
        let name = id.name
        
        for animID in CharacterAnimationType.allCases {
            let animName = animID.animId(character: name)
            let tarea = Task {
                await loadUSDZFile(named: animName, id: animID)
            }
            tareas.append(tarea)
            print("Model \(animName) loaded")
        }
        
        for tarea in tareas {
            let resultado = await tarea.value
            models[resultado.0] = resultado.1
        }
    }
    
    func loadUSDZFile(named: String, id: CharacterAnimationType) async -> (CharacterAnimationType, ModelEntity) {
        let model = try! await ModelEntity(named: named)
        return (id, model)
    }
    
    // MARK: Image Tracking Configuration
    func getImgTrackingConfiguration() -> ARConfiguration {
        let configuration = ARImageTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        if let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "Cards", bundle: Bundle.main) {
            configuration.trackingImages = trackingImages;
            configuration.maximumNumberOfTrackedImages = 2
        }
        return configuration
    }
    
    // MARK: Senders and getters
    
    func showLoadingScreen(activate: Bool) {
        print("Enviando orden de loading screen")
        streamIsLoading.send(activate)
    }
    
    func getCharData(from character: String) -> CharacterData? {
        guard let charData = charData[character] else {
            print("No hay datos asociados a \(character)")
            return nil
        }
        return charData
    }
    
    func getStartFrames(from character: String) -> AnimTimestamps? {
        guard let charData = charData[character] else {
            print("No hay datos asociados a \(character)")
            return nil
        }
        return charData.animStart
    }
    
    func getEndFrames(from character: String) -> AnimTimestamps? {
        guard let charData = charData[character] else {
            print("No hay datos asociados a \(character)")
            return nil
        }
        return charData.animEnd
    }
}
