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

public struct VideoTrackView: View {
    @Environment(\.liveKitUIOptions) var _ui: UIOptions
    private let _trackReference: TrackReference

    private var _layoutMode: VideoView.LayoutMode
    private var _mirrorMode: VideoView.MirrorMode

    public init(trackReference: TrackReference,
                layoutMode: VideoView.LayoutMode = .fill,
                mirrorMode: VideoView.MirrorMode = .auto)
    {
        _trackReference = trackReference
        _layoutMode = layoutMode
        _mirrorMode = mirrorMode
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                _ui.videoDisabledView(geometry: geometry)

                if let trackPublication = _trackReference.resolve(),
                   let track = trackPublication.track as? VideoTrack,
                   trackPublication.isSubscribed,
                   !trackPublication.isMuted
                {
                    SwiftUIVideoView(track,
                                     layoutMode: _layoutMode,
                                     mirrorMode: _mirrorMode)
                }
            }
        }
    }
}
