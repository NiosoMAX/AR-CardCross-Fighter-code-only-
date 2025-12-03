//
//  AudioManager.swift
//  AR Crossover Fighter
//
//  Created by Pablo on 28/1/25.
//

import Foundation
import RealityKit
import AVFoundation

final class AudioManager: NSObject, ObservableObject {
    static var shared = AudioManager()
    
    private var musicPlayer: AVAudioPlayer?
    private var sfxPlayer: AVAudioPlayer?
    
    // MARK: Voice lines
    func playVoiceLine(for character: Entity, line: CharacterVoiceLines) {
        DispatchQueue.main.async { [weak self] in
            Task {
                do {
                    try await self?.loadVoiceLine(for: character, line: line)
                } catch {
                    print("Error loading voice line: \(error)")
                }
            }
        }
    }
    
    func loadVoiceLine(for character: Entity, line: CharacterVoiceLines) async throws {
        let voiceLine = try await AudioFileResource(named: "\(character.name)_\(line.rawValue)")
        await character.playAudio(voiceLine)
    }
    
    // MARK: SFX
    
    func playCountdown() {
        do {
            let url = Bundle.main.url(forResource: GameSFX.countdown.rawValue, withExtension: "mp3")
            sfxPlayer = try AVAudioPlayer(contentsOf: url!)
            sfxPlayer?.volume = SoundConstants.SFXVolume
            sfxPlayer?.play()
        } catch {
            print("Error loading SFX: \(error)")
        }
    }
    
    func playSFX(for obj: Entity, sound: GameSFX) {
        switch sound {
        case .beam:
            do {
                let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3")
                sfxPlayer = try AVAudioPlayer(contentsOf: url!)
                sfxPlayer?.volume = SoundConstants.beamVolume
                sfxPlayer?.play()
            } catch {
                print("Error loading SFX: \(error)")
            }
            break
        default:
            DispatchQueue.main.async { [weak self] in
                Task {
                    do {
                        try await self?.loadSFX(for: obj, sound: sound)
                    } catch {
                        print("Error loading SFX: \(error)")
                    }
                }
            }
        }
    }
    
    func loadSFX(for obj: Entity, sound: GameSFX) async throws {
        let voiceLine = try await AudioFileResource(
            named: sound.rawValue,
            configuration: .init(loadingStrategy: .preload, shouldLoop: false)
        )
        //let audioController = await obj.prepareAudio(voiceLine)
        await obj.playAudio(voiceLine)
    }
    
    // MARK: Music
    
    func playMusic(track: GameMusic) {
        do {
            let url = Bundle.main.url(forResource: track.rawValue, withExtension: "mp3")
            musicPlayer = try AVAudioPlayer(contentsOf: url!)
            musicPlayer?.numberOfLoops = -1
            var volume: Float = 0.5
            switch track {
            case .battle:
                volume = SoundConstants.musicVolumeBattle
            case .theme:
                volume = SoundConstants.musicVolume
            }
            musicPlayer?.volume = volume
            musicPlayer?.play()
        } catch {
            print("Error loading music file: \(error)")
        }
    }
    
    func setMusicVolume(volume: Float){
        musicPlayer?.volume = volume
    }
    
    
}
