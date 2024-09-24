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
    private let _trackReference: TrackReference

    // Normalized to 0.0-1.0 range.
    @Published var data: [Float] = []

    private let processor: AudioVisualizeProcessor

    init(trackReference: TrackReference, bandCount: Int, isCentered: Bool) {
        processor = AudioVisualizeProcessor(bandsCount: bandCount, isCentered: isCentered)
        _trackReference = trackReference

        if let track = _trackReference.resolve()?.track as? AudioTrack {
            track.add(audioRenderer: self)
        }
    }

    deinit {
        // TODO: Remove
    }

    func render(pcmBuffer: AVAudioPCMBuffer) {
        processor.add(pcmBuffer: pcmBuffer)
        let processedData = processor.bands ?? []
        DispatchQueue.main.async { [weak self] in
            self?.data = processedData
        }
    }
}

struct BarAudioVisualizer: View {
    public let barCount: Int
    public let barColor: Color
    public let barCornerRadius: CGFloat
    public let barSpacing: CGFloat
    public let isCentered: Bool

    public let trackReference: TrackReference

    @ObservedObject private var _observableAudioProcessor: AudioProcessor

    init(trackReference: TrackReference,
         barColor: Color = .white,
         barCount: Int = 5,
         barCornerRadius: CGFloat = 15,
         barSpacing: CGFloat = 10,
         isCentered: Bool = true)
    {
        self.trackReference = trackReference
        self.barColor = barColor
        self.barCount = barCount
        self.barCornerRadius = barCornerRadius
        self.barSpacing = barSpacing
        self.isCentered = isCentered

        _observableAudioProcessor = AudioProcessor(trackReference: trackReference,
                                                   bandCount: barCount,
                                                   isCentered: isCentered)
    }

    var body: some View {
        HStack(alignment: .center, spacing: barSpacing) {
            ForEach(0 ..< _observableAudioProcessor.data.count, id: \.self) { index in
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: barCornerRadius)
                            .fill(barColor.opacity(Double(_observableAudioProcessor.data[index]))) // Use normalized magnitude for opacity
                            .frame(height: CGFloat(_observableAudioProcessor.data[index]) * geometry.size.height) // Magnitude determines height
                        Spacer()
                    }
                }
            }
        }
        .padding()
    }
}
