/*
 * Copyright 2024 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import AVFoundation
import LiveKit
import SwiftUI

class AudioProcessor: ObservableObject, AudioRenderer {
    private weak var _track: AudioTrack?
    // Normalized to 0.0-1.0 range.
    @Published var bands: [Float] = []

    private let _processor: AudioVisualizeProcessor

    init(track: AudioTrack?, bandCount: Int, isCentered: Bool) {
        _processor = AudioVisualizeProcessor(bandsCount: bandCount, isCentered: isCentered)
        _track = track
        _track?.add(audioRenderer: self)
    }

    deinit {
        _track?.remove(audioRenderer: self)
    }

    func render(pcmBuffer: AVAudioPCMBuffer) {
        let bands = _processor.process(pcmBuffer: pcmBuffer)
        guard let bands else { return }
        DispatchQueue.main.async { [weak self] in
            self?.bands = bands
        }
    }
}

struct BarAudioVisualizer: View {
    public let barCount: Int
    public let barColor: Color
    public let barCornerRadius: CGFloat
    public let barSpacingFactor: CGFloat
    public let isCentered: Bool

    public let audioTrack: AudioTrack

    @StateObject private var audioProcessor: AudioProcessor

    init(audioTrack: AudioTrack,
         barColor: Color = .white,
         barCount: Int = 7,
         barCornerRadius: CGFloat = 100,
         barSpacingFactor: CGFloat = 0.015,
         isCentered: Bool = true)
    {
        self.audioTrack = audioTrack
        self.barColor = barColor
        self.barCount = barCount
        self.barCornerRadius = barCornerRadius
        self.barSpacingFactor = barSpacingFactor
        self.isCentered = isCentered

        _audioProcessor = StateObject(wrappedValue: AudioProcessor(track: audioTrack,
                                                                   bandCount: barCount,
                                                                   isCentered: isCentered))
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: geometry.size.width * barSpacingFactor) {
                ForEach(0 ..< audioProcessor.bands.count, id: \.self) { index in
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: barCornerRadius)
                            .fill(barColor.opacity(Double(audioProcessor.bands[index])))
                            .frame(height: CGFloat(audioProcessor.bands[index]) * geometry.size.height)
                        Spacer()
                    }
                }
            }
        }
        .padding()
    }
}
