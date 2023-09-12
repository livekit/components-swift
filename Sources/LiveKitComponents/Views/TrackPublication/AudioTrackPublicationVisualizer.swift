/*
 * Copyright 2023 LiveKit
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

import SwiftUI
import LiveKit
import WebRTC

func isValidPCMAudio(sampleBuffer: CMSampleBuffer) -> Bool {
    // Get format description
    guard let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer) else {
        print("Failed to get format description from sample buffer")
        return false
    }

    // Verify media type is audio
    if CMFormatDescriptionGetMediaType(formatDesc) != kCMMediaType_Audio {
        print("Sample buffer is not of audio media type")
        return false
    }

    // Check if audio format is PCM
    let audioStreamDesc = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc)
    if audioStreamDesc?.pointee.mFormatID != kAudioFormatLinearPCM {
        print("Sample buffer is not in PCM format")
        return false
    }

    return true
}

internal class SampleBufferReceiver: NSObject, ObservableObject, RTCAudioRenderer {

    var sampleBuffer: CMSampleBuffer?

    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?

    override init() {
        print("RTCAudioTrack SampleBufferReceiver init")
    }

    deinit {
        print("RTCAudioTrack SampleBufferReceiver deinit")
        assetWriterInput?.markAsFinished()
        assetWriter?.finishWriting {
            //
        }
        //{
         //   completion()
//        }
    }

    func createAssetWriter(with sampleBuffer: CMSampleBuffer) {

        let tempDir = NSTemporaryDirectory()
        let outputPath = tempDir.appending("recording_\(UUID().uuidString).m4a")
        let outputURL = URL(fileURLWithPath: outputPath)

            // Create the asset writer
            assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .m4a)

            guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
                return
            }

            let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)!.pointee

        let opts: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
             AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
             AVEncoderBitRateKey: 128000,
             AVNumberOfChannelsKey: 1,
             AVSampleRateKey: 44100.0
            ]

            assetWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: opts)
            assetWriterInput!.expectsMediaDataInRealTime = true

            assert(assetWriter!.canAdd(assetWriterInput!))

            assetWriter!.add(assetWriterInput!)


        assetWriter!.startWriting()
        assetWriter!.startSession(atSourceTime: CMTime.zero)

        print("RTCAudioTrack recording to \(outputPath)")
    }

    func render(sampleBuffer: CMSampleBuffer) {

        let isValid = isValidPCMAudio(sampleBuffer: sampleBuffer)

        print("RTCAudioTrack isValid: \(isValid)")

        guard let assetWriterInput = assetWriterInput else {
            print("RTCAudioTrack assetWriterInput is nil")
            createAssetWriter(with: sampleBuffer)
            return
        }

        //if assetWriterInput?.isReadyForMoreMediaData == true {
        if !assetWriterInput.append(sampleBuffer) {
//            if let error = assetWriter.error {
//                print("Asset writer error: \(error)")
//            }
            print("RTCAudioTrack write error \(assetWriter?.error)")
        }
        //}
//        Task.detached { @MainActor in
//            self.sampleBuffer = sampleBuffer
//            self.objectWillChange.send()
//            print("RTCAudioTrack render(sampleBuffer:) isValid: \(CMSampleBufferIsValid(sampleBuffer))")
//        }
    }
}

struct SampView: View {

    weak var track: AudioTrack?

    let sampleBufferReceiver = SampleBufferReceiver()

    init(track: AudioTrack) {
        self.track = track
    }

    var body: some View {
        ZStack {
            Text("Sample: \(String(describing: sampleBufferReceiver.sampleBuffer))")
        }
        .onAppear(perform: {
            print("RTCAudioTrack add(audioRenderer:)")
            track?.add(audioRenderer: sampleBufferReceiver)
            print("RTCAudioTrack add(audioRenderer:) complete")
        })
        .onDisappear(perform: {
            print("RTCAudioTrack remove(audioRenderer:)")
            track?.remove(audioRenderer: sampleBufferReceiver)
            print("RTCAudioTrack remove(audioRenderer:) complete")
        })
    }
}
public struct AudioTrackPublicationVisualizer: View {

    @EnvironmentObject var trackPublication: TrackPublication
    @EnvironmentObject var ui: UIPreference

    public var body: some View {
        GeometryReader { geometry in

            ZStack {
                if let track = trackPublication.track as? AudioTrack,
                   trackPublication.subscribed,
                   !trackPublication.muted {
                    SampView(track: track)
                        .frame(width: 100, height: 100)
                }
            }
        }
    }
}
