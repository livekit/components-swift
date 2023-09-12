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

public typealias ParticipantFilterFunc = (Participant) -> Bool

public enum ParticipantFilter {
    case all
    case remoteParticipants
    case canPublishMedia
    case publishingVideo
    case custom(ParticipantFilterFunc)
}

/// Loops through `Participant`'s in the current `Room`.
///
/// > Note: References `Room` environment object.
public struct ForEachParticipant<Content: View>: View {

    @EnvironmentObject var room: Room

    let filter: ParticipantFilter
    let content: ParticipantComponentBuilder<Content>

    public init(includeLocalParticipant: Bool = true,
                filter: ParticipantFilter = .all,
                @ViewBuilder content: @escaping ParticipantComponentBuilder<Content>) {

        self.filter = filter
        self.content = content
    }

    private func sortedParticipants() -> [Participant] {

        let participants: [Participant] = Array(room.allParticipants.values).filter { participant in

            //            for case .localParticipant(let include) in filter {
            //                if participant is LocalParticipant {
            //                    if !include { return false }
            //                }
            //            }

            if case .all = filter {
                // Include all participants
                return true
            } else if case .canPublishMedia = filter {
                //
                return participant.permissions.canPublish
            }

            //            for case .canPublishData(let include) in filter {
            //                if participant.permissions.canPublishData { return include }
            //            }

            //            for case .publishingVideo(let include) in filter {
            //                let enabledTrack = participant.videoTracks.first(where: { !$0.muted })
            //                if !(enabledTrack != nil && include) { return false }
            //            }

            return true
        }

        return participants.sorted { p1, p2 in
            if p1 is LocalParticipant { return true }
            if p2 is LocalParticipant { return false }
            return (p1.joinedAt ?? Date()) < (p2.joinedAt ?? Date())
        }
    }

    public var body: some View {
        ForEach(sortedParticipants()) { participant in
            content(participant)
                .environmentObject(participant)
        }
    }
}
