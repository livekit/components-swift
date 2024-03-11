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

import LiveKit
import SwiftUI

public struct LocalCameraPreview: View {
    @Environment(\.liveKitUIOptions) var ui: UIOptions

    let localVideoTrack: LocalVideoTrack

    public init(localVideoTrack: LocalVideoTrack? = nil) {
        self.localVideoTrack = localVideoTrack ?? LocalVideoTrack.createCameraTrack()
    }

    public var body: some View {
        GeometryReader { geometry in

            ZStack {
                ui.videoDisabledView(geometry: geometry)

                SwiftUIVideoView(localVideoTrack,
                                 mirrorMode: .mirror)
                    .onAppear {
                        Task {
                            try await localVideoTrack.start()
                        }
                    }
                    .onDisappear {
                        Task {
                            try await localVideoTrack.stop()
                        }
                    }
            }
        }
    }
}
