//
//  ARKitARView.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 17/11/24.
//

import Foundation
import ARKit
import Combine
import SpriteKit
import AVFoundation

class ARInfoDelegate: NSObject, ARSCNViewDelegate {
    
    // Characters
    var charNodes = [String: SCNNode?]()
    
    var imageNodes = [SCNNode]()
    var pointNodes = [SCNNode]()
    var infoNodes = [String: SCNNode]()
    var voiceTextNodes = [String: SCNNode]()
    var displayingInfo = false
    var lastDisplay = ""
    
    // Sound
    var musicPlayer: AVAudioPlayer?
    var sfxPlayer: AVAudioPlayer?
    var voiceFiles: [String: SCNAudioSource] = [:]
    
    override init() {
        super.init()
        for character in PlayableCharacterID.allCases {
            loadSCNModels(named: character.name)
            loadVoice(name: character.name)
        }
    }
    
    private func configuration(){
        // Configuración para hacer Image Tracking
        let configuration = ARImageTrackingConfiguration()
        
        if let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "Cards", bundle: Bundle.main) {
            configuration.trackingImages = trackingImages;
            configuration.maximumNumberOfTrackedImages = 2
        }
        
        //ARManager.shared.sceneView.session.run(configuration)
    }
    
    private func loadVoice(name: String) {
        let audioFile = "\(name)_\(VoiceLinesConstants.presentation)"
        guard let voiceURL = Bundle.main.url(forResource: audioFile, withExtension: "wav") else {
            print("Error: Voice line \(audioFile) file not found.")
            return
        }
        
        let audio = SCNAudioSource(url: voiceURL)!
        audio.isPositional = true
        voiceFiles[name] = audio
    }
    
    private func loadMusic(named file: String){
        guard let url = Bundle.main.url(forResource: file, withExtension: "wav") else {
            print("No se encontró el audio")
            return
        }
        
        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.prepareToPlay()
        } catch {
            print("Error al cargar el audio: \(error)")
            return
        }
    }
    
    private func loadSCNModels(named character: String){
        let charScene = SCNScene(named: "3DModels.scnassets/\(character)_Idle.scn")
        
        guard let rootNode = charScene?.rootNode else {
           print("Error loading model")
           return
       }
        
        rootNode.name = character
        
        for childNode in rootNode.childNodes {
            childNode.name = character
        }
        
        charNodes[character] = rootNode
    }
    
    // MARK: Render
    
    // Render inicial
    func renderer(_ renderer: any SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        DispatchQueue.global().async { [weak self] in
            if let imageAnchor = anchor as? ARImageAnchor {
                // Preparación
                guard let charData = ARSessionManager.shared.getCharData(from: imageAnchor.referenceImage.name!) else {
                    print("No hay datos asociados a la carta")
                    return
                }
                
                // Cargamos todos los modelos necesarios para RA
                // Texto
                let textModel = SCNText(string: charData.full_name, extrusionDepth: 2)
                let mat1 = SCNMaterial()
                mat1.diffuse.contents = UIColor.green
                textModel.materials = [mat1]
                let textNode = SCNNode(geometry: textModel)
                textNode.position = SCNVector3(x: -3.5, y: 0, z: 1)
                textNode.scale = SCNVector3(x:0.08, y:0.08, z:0.08)
                textNode.name = "Text_\(charData.name)"
                node.addChildNode(textNode)
                node.name = charData.name
                
                self?.crearModuloInfo(node, charData.descripcion_1, altura: 2)
                self?.crearModuloInfo(node, charData.descripcion_2, altura: 1)
                self?.crearVoiceLineNode(node, name: charData.name, voiceActor: charData.voice)
                
                // Personaje
                let charNode = self?.charNodes[imageAnchor.referenceImage.name!]

                guard let char = charNode! else {return}
                node.addChildNode(char)
                self?.imageNodes.append(node)
            }
        }
        return node
    }
    
    private func crearModuloInfo(_ node: SCNNode, _ descpt: String, altura: Float) {
        // Punto
        let pointModel1 = SCNSphere(radius: 0.15)
        let mat2 = SCNMaterial()
        mat2.diffuse.contents = UIColor.white
        mat2.emission.contents = UIColor.green
        pointModel1.materials = [mat2]
        let nodePoint = SCNNode(geometry: pointModel1)
        let pointID = InfoActions.infoPoint + String(pointNodes.count)
        nodePoint.name = pointID
        nodePoint.position = SCNVector3(x: 1, y: altura, z: 0)
        node.addChildNode(nodePoint)
        pointNodes.append(nodePoint)
        
        // Texto descriptivo
        let nodeInfo = crearCajaTexto(descripcion: descpt, width: CGFloat(Constants.defaultTextBoxSize), height: CGFloat(Constants.defaultTextBoxSize))
        nodeInfo.position = SCNVector3(x: 3, y: 2, z: 0.5)
        nodeInfo.eulerAngles = SCNVector3(x: 0, y: .pi, z: .pi)
        nodeInfo.opacity = 0
        node.addChildNode(nodeInfo)
        self.infoNodes[pointID] = (nodeInfo)
    }
    
    private func crearCajaTexto(descripcion: String, width: CGFloat, height: CGFloat, color: UIColor = #colorLiteral(red: 0.04942956771, green: 0.347947378, blue: 0.3496697809, alpha: 1)) -> SCNNode {
        let skTexture = SKScene(size: CGSize(width: width, height: height))
        skTexture.backgroundColor = UIColor.clear
        
        // Textura con texto creado con SceneKit
        let rectangle = SKShapeNode(rect: CGRect(x: 0, y: 0, width: width, height: width), cornerRadius: 10)
        rectangle.fillColor = #colorLiteral(red: 0.7845792427, green: 0.9238082874, blue: 0.9254902005, alpha: 1)
        rectangle.strokeColor = color
        rectangle.lineWidth = 2
        rectangle.alpha = 0.4
        let labelNode = SKLabelNode(text: descripcion)
        labelNode.fontSize = 15
        labelNode.fontName = "San Francisco"
        labelNode.numberOfLines = 7
        labelNode.position = CGPoint(x: 100, y: 50)
        skTexture.addChild(rectangle)
        skTexture.addChild(labelNode)
        
        // Rectángulo 3D
        let plane = SCNPlane(width: 2, height: 2)
        let material = SCNMaterial()
        material.isDoubleSided = true
        material.diffuse.contents = skTexture
        plane.materials = [material]
        let node = SCNNode(geometry: plane)
        return node
    }
    
    private func crearVoiceLineNode(_ node: SCNNode, name: String, voiceActor: String) {
        let pointModel = SCNSphere(radius: 0.15)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.red
        mat.emission.contents = UIColor.red
        pointModel.materials = [mat]
        let nodePoint = SCNNode(geometry: pointModel)
        let pointID = "\(name)_\(VoiceLinesConstants.presentation)"
        nodePoint.name = pointID
        nodePoint.position = SCNVector3(x: -1, y: 1.5, z: 0)
        node.addChildNode(nodePoint)
        pointNodes.append(nodePoint)
        
        node.addChildNode(nodePoint)
        
        // Texto descriptivo
        let nodeInfo = crearCajaTexto(descripcion: "\(TextConstants.characterVoice): \(voiceActor)", width: CGFloat(Constants.defaultTextBoxSize), height: CGFloat(Constants.voiceTextHeight), color: #colorLiteral(red: 0.7045043135, green: 0.2691438117, blue: 0.4874552109, alpha: 1))
        nodeInfo.position = SCNVector3(x: -1.5, y: 1, z: 0.5)
        nodeInfo.eulerAngles = SCNVector3(x: 0, y: .pi, z: .pi)
        nodeInfo.opacity = 0
        node.addChildNode(nodeInfo)
        self.voiceTextNodes[name] = (nodeInfo)
    }
    
    // MARK: Animaciones
    func animAppear(target: SCNNode){
        let fadeInAnim = SCNAction.fadeIn(duration: 1)
        fadeInAnim.timingMode = .easeOut
        target.runAction(fadeInAnim)
    }
    
    func animDisappear(target: SCNNode){
        let fadeOutAnim = SCNAction.fadeOut(duration: 1)
        fadeOutAnim.timingMode = .easeInEaseOut
        target.runAction(fadeOutAnim)
    }
    
    func animGlowSelect(target: SCNNode) {
        let glowSelectAnim = SCNAction.customAction(duration: 1, action: { (node, _) in
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        })
        glowSelectAnim.timingMode = .easeOut
        target.runAction(glowSelectAnim)
    }
    
    func animGlowDeselect(target: SCNNode) {
        let glowDeselectAnim = SCNAction.customAction(duration: 1, action: { (node, _) in
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        })
        glowDeselectAnim.timingMode = .easeOut
        target.runAction(glowDeselectAnim)
    }
    
    // MARK: Input
    
    func handleTap(_ recogniser: UITapGestureRecognizer, in arSCNView: ARSCNView) {
        // Touch location
        let tapLocation = recogniser.location(in: arSCNView)
        let hits = arSCNView.hitTest(tapLocation, options: nil)
        if !hits.isEmpty {
            print("Se ha encontrado: \(String(describing: hits.first?.node.name))")
            
            guard let targetNodePoint = hits.first?.node else {
                return
            }
            
            guard let nodeName = targetNodePoint.name else {
                return
            }
            
            if nodeName.contains(InfoActions.infoPoint){
                animGlowSelect(target: targetNodePoint)
                
                guard let targetInfoBox = infoNodes[targetNodePoint.name!] else {
                    return
                }
                animAppear(target: targetInfoBox)
                if displayingInfo && lastDisplay != "" {
                    // Hacer desaparecer la última caja de información
                    let targetInfoBoxDismiss = infoNodes[lastDisplay]
                    animDisappear(target: targetInfoBoxDismiss!)
                    if let lastPoint = pointNodes.firstIndex(where: { point in
                        point.name == lastDisplay
                    }) {
                        animGlowDeselect(target: pointNodes[lastPoint])
                    }
                }
                displayingInfo = true
                lastDisplay = nodeName
            }
            
            if nodeName.contains(VoiceLinesConstants.presentation) {
                let splitNames = nodeName.split(separator: "_")
                let name = String(splitNames[0])
                
                guard let voiceBox = voiceTextNodes[name] else {
                    print("Voice text not found for \(name)")
                    return
                }
                
                voiceBox.opacity = 1
                
                let audio = voiceFiles[name]!
                
                let audioPlayer = SCNAudioPlayer(source: audio)
                targetNodePoint.addAudioPlayer(audioPlayer)
                
                audioPlayer.didFinishPlayback = {
                    voiceBox.opacity = 0
                }
            }
        }
    }
}
