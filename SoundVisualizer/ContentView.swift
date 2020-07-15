//
//  ContentView.swift
//  SoundVisualizer
//
//  Created by momosuke on 2020/07/15.
//  Copyright © 2020 momosuke. All rights reserved.
//

import SwiftUI
import CoreHaptics

let numberOfSamples: Int = 10

struct ContentView: View {
    @State private var engine: CHHapticEngine?
    // マイクロホンモニターのobservedObjectを作成
    @ObservedObject private var mic = MicrophoneMonitor(numberOfSamples: numberOfSamples)
    
    // 生のサウンドレベル（マイクモニターから使用するために与えられたレベル）を取り込むヘルパー関数を作成
    // -160 ~ 0の入力を0.1 ~ 25の間に正則化し，可視化の都合で300までにさらに変換
    private func normalizeSoundLevel(level: Float) -> CGFloat {
        let level = max(0.2, CGFloat(level) + 50) / 2
        if(CGFloat(level * (300 / 25)) > 200) {
            print(">200: 何か喋ってる")
            playHaptics()
        }
        return CGFloat(level * (300 / 25))
    }
    
    var body: some View {
        VStack {
            // 正規化されたバーを表示
            HStack(spacing: 4) {
                ForEach(mic.soundSamples, id: \.self) { level in
                    BarView(value: self.normalizeSoundLevel(level: level))
                }
            }
            Text("Feel the Vibes")
                .onAppear(perform: prepareHaptics)
                .onTapGesture(perform: playHaptics)
        }
    }
    
    func prepareHaptics() {

        // 接続デバイスで触覚フィードバックをサポートしているかチェック
        guard  CHHapticEngine.capabilitiesForHardware()
            .supportsHaptics else { print("no support"); return; }
        do {
            // 触覚フィードバックスタート
            self.engine = try! CHHapticEngine()
            try engine!.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription).")
        }
        print("a")
    }
    
    func playHaptics() {
        mic.halt()
        guard CHHapticEngine.capabilitiesForHardware()
            .supportsHaptics  else { print("no support"); return; }
//        var events = [CHHapticEvent]() // CHHapticEvent: 1つの触覚またはオーディオイベントオブジェクト
//
//        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)
//        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1)
//        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
//        events.append(event)
        
        let audioEvent = CHHapticEvent(eventType: .audioContinuous, parameters: [
            CHHapticEventParameter(parameterID: .audioPitch, value: 0.5),
            CHHapticEventParameter(parameterID: .audioVolume, value: 1),
            CHHapticEventParameter(parameterID: .decayTime, value: 1),
            CHHapticEventParameter(parameterID: .sustained, value: 0)
        ], relativeTime: 0)
        let hapticEvent = CHHapticEvent(eventType: .hapticTransient, parameters: [
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1),
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)
        ], relativeTime: 0)
        
        do {
            let pattern = try! CHHapticPattern(events: [audioEvent, hapticEvent], parameters: [])
            //let pattern = try CHHapticPattern(events: events, parameters: []) // CHHapticPattern: イベントを束ねるオブジェクト
            let player = try engine?.makePlayer(with: pattern) // makePlayer: パターンからプレイヤーをsakusei
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
        mic.restart()
        print("b")
        
    }
}

struct BarView: View {

    // サウンドレベルを UI が認識できるものに変換
    var value: CGFloat
    
    var body: some View {
        ZStack {
            // ラウンドとった長方形で可視化
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .top, endPoint: .bottom))
            
                .frame(width: (UIScreen.main.bounds.width - CGFloat(numberOfSamples) * 4) / CGFloat(numberOfSamples), height: value)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
