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

public struct ChatScrollView<Content: View>: View {
    public typealias MessageBuilder = (ReceivedMessage) -> Content

    @LiveKitConversation private var conversation
    @ViewBuilder private let messageBuilder: MessageBuilder

    public init(messageBuilder: @escaping MessageBuilder) {
        self.messageBuilder = messageBuilder
    }

    public var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack {
                    ForEach(conversation.messages.values.reversed()) { message in
                        messageBuilder(message)
                            .upsideDown()
                            .id(message.id)
                    }
                }
            }
            .onChange(of: conversation.messages.count) { _ in
                scrollView.scrollTo(conversation.messages.keys.last)
            }
            .upsideDown()
            .animation(.default, value: conversation.messages)
        }
    }
}

private struct UpsideDown: ViewModifier {
    func body(content: Content) -> some View {
        content
            .rotationEffect(.radians(Double.pi))
            .scaleEffect(x: -1, y: 1, anchor: .center)
    }
}

private extension View {
    func upsideDown() -> some View {
        modifier(UpsideDown())
    }
}
