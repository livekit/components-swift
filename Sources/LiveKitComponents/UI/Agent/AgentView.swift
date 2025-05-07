import LiveKit
import SwiftUI

public struct AgentView: View {
    @EnvironmentObject private var room: Room
    @EnvironmentObject private var participant: Participant

    private var cameraTrack: VideoTrack? {
        return participant.firstCameraVideoTrack ?? room.avatarWorker?.firstCameraVideoTrack
    }

    private var micTrack: AudioTrack? {
        return participant.firstAudioTrack ?? room.avatarWorker?.firstAudioTrack
    }
    
    public init() {}

    public var body: some View {
        ZStack {
            if let cameraTrack, !cameraTrack.isMuted {
                SwiftUIVideoView(cameraTrack)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                AgentBarAudioVisualizer(audioTrack: micTrack, agentState: participant.agentState, barColor: .primary, barCount: 5)
            }
        }
        .id("\(participant.identity?.stringValue ?? "none")-\(cameraTrack?.sid?.stringValue ?? "none")-\(micTrack?.sid?.stringValue ?? "none")")
    }
}
