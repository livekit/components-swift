/*
 * Copyright 2025 LiveKit
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

public class TrackReference: ObservableObject {
    public let participant: Participant
    public let publication: TrackPublication?
    public let name: String?
    public let source: Track.Source?

    public var isResolvable: Bool { resolve() != nil }

    public init(participant: Participant,
                publication: TrackPublication? = nil,
                name: String? = nil,
                source: Track.Source? = nil)
    {
        self.participant = participant
        self.publication = publication
        self.name = name
        self.source = source
    }

    /// Attempts to reseolve ``TrackPublication`` in order: publication, name, source.
    public func resolve() -> TrackPublication? {
        if let publication {
            return publication
        } else if let name, let source, let publication = participant.trackPublications.first(where: { $0.value.name == name && $0.value.source == source })?.value {
            return publication
        } else if let name, let publication = participant.trackPublications.first(where: { $0.value.name == name })?.value {
            return publication
        } else if let source, let publication = participant.trackPublications.first(where: { $0.value.source == source })?.value {
            return publication
        }

        return nil
    }
}
