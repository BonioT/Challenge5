//
//  SceneBuilderView.swift
//  Constructor
//
//  Created by Antonio Bonetti on 24/02/26.
//

import SwiftUI
import SceneKit

struct SceneBuilderView: View {

    @ObservedObject var viewModel: SceneViewModel
    @Binding var snapshot: UIImage?

    @State private var scnView: SCNView?

    // Sliders: piccoli delta (non valori assoluti), così non devi “mappare” l’angolo
    @State private var deltaX: Double = 0
    @State private var deltaY: Double = 0
    @State private var deltaZ: Double = 0

    var body: some View {
        VStack(spacing: 0) {

            SceneViewContainer(viewModel: viewModel, onViewReady: { view in
                self.scnView = view
            })
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Control panel
            VStack(alignment: .leading, spacing: 12) {

                HStack {
                    Text("Selected: \(viewModel.selectedNodeName ?? "None")")
                        .font(.headline)
                    Spacer()

                    Button("Snapshot") { takeSnapshot() }
                        .buttonStyle(.borderedProminent)
                }

                // Pose presets
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SceneViewModel.PoseType.allCases, id: \.self) { pose in
                            Button(pose.rawValue) {
                                viewModel.applyPose(pose)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                // Joint rotation sliders (only if something selected)
                if viewModel.selectedNode != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rotate Joint (X / Y / Z)")
                            .font(.subheadline)

                        axisSlider(title: "X", value: $deltaX) { v in
                            viewModel.rotateSelectedJoint(deltaX: Float(v), deltaY: 0, deltaZ: 0)
                        }

                        axisSlider(title: "Y", value: $deltaY) { v in
                            viewModel.rotateSelectedJoint(deltaX: 0, deltaY: Float(v), deltaZ: 0)
                        }

                        axisSlider(title: "Z", value: $deltaZ) { v in
                            viewModel.rotateSelectedJoint(deltaX: 0, deltaY: 0, deltaZ: Float(v))
                        }

                        Text("Tip: tap a limb to select it, then use sliders to pose it.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Tap a limb to select it, then rotate it with the sliders.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }

    // Slider helper: we use a small range and reset to 0 after applying
    private func axisSlider(title: String,
                            value: Binding<Double>,
                            onChange: @escaping (Float) -> Void) -> some View {
        HStack {
            Text(title).frame(width: 18)

            Slider(value: value, in: -0.08...0.08, step: 0.01)
                .onChange(of: value.wrappedValue) { _, newValue in
                    onChange(Float(newValue))
                    // reset to center so it behaves like “nudge”
                    value.wrappedValue = 0
                }
        }
    }

    private func takeSnapshot() {
        guard let scnView else { return }
        snapshot = scnView.snapshot()
    }
}
