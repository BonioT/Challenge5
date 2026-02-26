//
//  DrawView.swift
//  Constructor
//
//  Created by Antonio Bonetti on 24/02/26.
//


import SwiftUI
import PencilKit

struct DrawView: View {
    let backgroundImage: UIImage

    @State private var canvasView = PKCanvasView()
    @State private var backgroundOpacity: Double = 0.35
    @State private var showBackground: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // “Foglio” bianco
                Color.white.ignoresSafeArea()

                if showBackground {
                    Image(uiImage: backgroundImage)
                        .resizable()
                        .scaledToFit()
                        .opacity(backgroundOpacity)
                        .blendMode(.normal)
                        .allowsHitTesting(false)
                        .padding(12)
                }

                PencilKitCanvas(canvasView: $canvasView)
                    .padding(12)
            }

            // Controls
            HStack(spacing: 16) {
                Toggle("Show snapshot", isOn: $showBackground)
                    .toggleStyle(.switch)

                HStack {
                    Text("Opacity")
                    Slider(value: $backgroundOpacity, in: 0...1)
                        .frame(width: 180)
                }
                .opacity(showBackground ? 1 : 0.3)
                .disabled(!showBackground)

                Spacer()

                Button("Clear") {
                    canvasView.drawing = PKDrawing()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Draw Mode")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PencilKitCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false

        // ToolPicker stile Note
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                let toolPicker = PKToolPicker.shared(for: window)
                toolPicker?.setVisible(true, forFirstResponder: canvasView)
                toolPicker?.addObserver(canvasView)
                canvasView.becomeFirstResponder()
            }
        }

        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
