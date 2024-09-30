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
    @Published var data: [Float] = []

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
        _processor.add(pcmBuffer: pcmBuffer)
        let processedData = _processor.bands ?? []
        DispatchQueue.main.async { [weak self] in
            self?.data = processedData
        }
    }
}

struct BarAudioVisualizer: View {
    public let barCount: Int
    public let barColor: Color
    public let barCornerRadius: CGFloat
    public let barSpacingFactor: CGFloat
    public let isCentered: Bool

    public let trackReference: TrackReference

    @StateObject private var audioProcessor: AudioProcessor

    init(trackReference: TrackReference,
         barColor: Color = .white,
         barCount: Int = 7,
         barCornerRadius: CGFloat = 15,
         barSpacingFactor: CGFloat = 0.015,
         isCentered: Bool = true)
    {
        self.trackReference = trackReference
        self.barColor = barColor
        self.barCount = barCount
        self.barCornerRadius = barCornerRadius
        self.barSpacingFactor = barSpacingFactor
        self.isCentered = isCentered

        let track = trackReference.resolve()?.track as? AudioTrack
        _audioProcessor = StateObject(wrappedValue: AudioProcessor(track: track,
                                                                   bandCount: barCount,
                                                                   isCentered: isCentered))
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: geometry.size.width * barSpacingFactor) {
                ForEach(0 ..< audioProcessor.data.count, id: \.self) { index in
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: barCornerRadius)
                            .fill(barColor.opacity(Double(audioProcessor.data[index])))
                            .frame(height: CGFloat(audioProcessor.data[index]) * geometry.size.height)
                        Spacer()
                    }
                }
            }
        }
        .padding()
    }
}
