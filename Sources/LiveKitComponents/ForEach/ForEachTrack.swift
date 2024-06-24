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

/// Loops through `TrackPublications`'s in the current `Participant`.
///
/// - Parameters:
/// - filter: Type of track to loop through, defaults to `.video`.
///
/// > Note: References `Participant` environment object.
public struct ForEachTrack<Content: View>: View {
    // MARK: - Public types

    public enum Filter {
        case all
        case video
        case audio
    }

    // MARK: - Private

    private let _filter: Filter
    private let _content: TrackReferenceComponentBuilder<Content>

    @EnvironmentObject private var _participant: Participant

    public init(filter: Filter = .video,
                @ViewBuilder content: @escaping TrackReferenceComponentBuilder<Content>)
    {
        _filter = filter
        _content = content
    }

    private func _computedTrackPublications() -> [TrackPublication] {
        let trackPublications = Array(_participant.trackPublications.values)
        switch _filter {
        case .all: return trackPublications
        case .video: return trackPublications.filter { $0.kind == .video }
        case .audio: return trackPublications.filter { $0.kind == .audio }
        }
    }

    public var body: some View {
        ForEach(_computedTrackPublications()) { trackPublication in
            let trackReference = TrackReference(participant: _participant,
                                                publication: trackPublication)
            _content(trackReference)
                .environmentObject(trackReference)
        }
    }
}
