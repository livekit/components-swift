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

/// Loops through `Participant`'s in the current `Room`.
///
/// > Note: References `Room` environment object.
public struct ForEachParticipant<Content: View>: View {
    // MARK: - Public types

    public enum Filter {
        case all
        /// Only participants that have publish permission
        case canPublishVideoOrAudio
        case isPublishingVideo
        case isPublishingAudio
    }

    @EnvironmentObject private var _room: Room

    /// Whether to include the local participant in the enumeration
    private let _includeLocalParticipant: Bool
    private let _filterMode: Filter
    private let _content: ParticipantComponentBuilder<Content>

    public init(includeLocalParticipant: Bool = true,
                filter: Filter = .all,
                @ViewBuilder content: @escaping ParticipantComponentBuilder<Content>)
    {
        _includeLocalParticipant = includeLocalParticipant
        _filterMode = filter
        _content = content
    }

    private func _sortedParticipants() -> [Participant] {
        // Include LocalParticipant or not
        let participants: [Participant] = Array(_room.allParticipants.values).filter { participant in
            // Filter out LocalParticipant if not required
            if !_includeLocalParticipant, participant is LocalParticipant { return false }
            if case .canPublishVideoOrAudio = _filterMode, !participant.permissions.canPublish { return false }
            return true
        }

        return participants.sorted { p1, p2 in
            if p1 is LocalParticipant { return true }
            if p2 is LocalParticipant { return false }
            return (p1.joinedAt ?? Date()) < (p2.joinedAt ?? Date())
        }
    }

    public var body: some View {
        ForEach(_sortedParticipants()) { participant in
            _content(participant)
                .environmentObject(participant)
        }
    }
}
