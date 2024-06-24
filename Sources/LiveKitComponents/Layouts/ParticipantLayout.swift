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

import SwiftUI

public struct ParticipantLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable, Data.Index: Hashable {
    private let _data: Data
    private let _spacing: CGFloat?
    private let _viewBuilder: (Data.Element) -> Content

    public init(_ data: Data,
                spacing: CGFloat? = nil,
                content: @escaping (Data.Element) -> Content)
    {
        _data = data
        _viewBuilder = content
        _spacing = spacing
    }

    public var body: some View {
        if _data.count > 0 {
            GeometryReader { _ in
                let computed = _computeColumn()
                VStack(spacing: _spacing) {
                    ForEach(0 ..< computed.rows, id: \.self) { row in
                        HStack(spacing: _spacing) {
                            ForEach(0 ..< computed.columns[row], id: \.self) { column in
                                let index = computed.columns.prefix(row).reduce(0, +) + column
                                if index < _data.count {
                                    ZStack(alignment: .center) {
                                        Color.white
                                        Text("\(index)")
                                            .foregroundColor(Color.black)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Private

    private func _data(at index: Int) -> Data.Element {
        let dataIndex = _data.index(_data.startIndex, offsetBy: index)
        return _data[dataIndex]
    }

    private func _computeColumn() -> (columns: [Int], rows: Int) {
        let baseCount = Int(ceil(Double(_data.count).squareRoot()))
        let remainder = _data.count % baseCount
        let firstRowCount = remainder > 0 ? remainder : baseCount
        let rows = remainder > 0 ? baseCount : baseCount

        var columns = [Int]()
        columns.append(firstRowCount)
        columns.append(contentsOf: Array(repeating: baseCount, count: rows - 1))
        return (columns: columns, rows: rows)
    }
}
