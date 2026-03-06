import PencilKit
import SwiftUI

struct DrawView: View {
    let backgroundImage: UIImage
    let sceneId: UUID
    let sheetId: UUID

    @StateObject private var viewModel = DrawViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var renderedImage: Image? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                Toggle(isOn: $viewModel.showBackground) {
                    Image(systemName: viewModel.showBackground ? "photo.fill" : "photo")
                }
                .toggleStyle(.button)
                .tint(.blue)
                .clipShape(Circle())

                if viewModel.showBackground {
                    Slider(value: $viewModel.backgroundOpacity, in: 0...1)
                        .frame(width: 120)
                        .tint(.blue)
                }

                Spacer()
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
            .zIndex(1)

            GeometryReader { geometry in
                ZoomableCanvasWrapper(
                    canvasView: $viewModel.canvasView,
                    backgroundImage: backgroundImage,
                    showBackground: viewModel.showBackground,
                    backgroundOpacity: viewModel.backgroundOpacity,
                    viewSize: geometry.size
                )
            }
            .ignoresSafeArea(edges: [.bottom, .horizontal])
            .background(Color(UIColor.secondarySystemBackground))
        }
        .navigationTitle("Drawing")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    viewModel.saveDrawing(for: sheetId, in: sceneId)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.backward")
                        Text("Back")
                    }
                    .foregroundColor(.primary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if let renderedImage = renderedImage {
                    ShareLink(
                        item: renderedImage, preview: SharePreview("Drawing", image: renderedImage)
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                    }
                } else {
                    Button(action: {
                        self.renderedImage = renderCompositeImage()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadDrawing(for: sheetId, in: sceneId)
        }
    }

    private func renderCompositeImage() -> Image {
        let size = backgroundImage.size
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        let uiImage = renderer.image { _ in
            if viewModel.showBackground {
                backgroundImage.draw(
                    in: CGRect(origin: .zero, size: size),
                    blendMode: .normal,
                    alpha: CGFloat(viewModel.backgroundOpacity)
                )
            }
            let drawingImage = viewModel.canvasView.drawing.image(
                from: CGRect(origin: .zero, size: size),
                scale: 1.0
            )
            drawingImage.draw(in: CGRect(origin: .zero, size: size))
        }

        return Image(uiImage: uiImage)
    }
}

struct ZoomableCanvasWrapper: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    var backgroundImage: UIImage
    var showBackground: Bool
    var backgroundOpacity: Double
    var viewSize: CGSize

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 5.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = context.coordinator

        let containerView = UIView()
        let imageSize = backgroundImage.size
        let sizeToUse = (imageSize.width > 0 && imageSize.height > 0)
            ? imageSize : CGSize(width: 1000, height: 1000)

        containerView.frame = CGRect(origin: .zero, size: sizeToUse)
        containerView.backgroundColor = .white
        containerView.layer.borderColor = UIColor.lightGray.cgColor
        containerView.layer.borderWidth = 1
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowRadius = 10
        containerView.layer.shadowOffset = CGSize(width: 0, height: 5)

        let bgImageView = UIImageView(image: backgroundImage)
        bgImageView.contentMode = .scaleToFill
        bgImageView.frame = containerView.bounds
        bgImageView.tag = 100
        containerView.addSubview(bgImageView)

        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.isScrollEnabled = false
        canvasView.frame = containerView.bounds
        containerView.addSubview(canvasView)

        scrollView.addSubview(containerView)
        scrollView.contentSize = containerView.bounds.size
        context.coordinator.containerView = containerView

        var initialScale: CGFloat = 1.0
        if sizeToUse.width > 0 && sizeToUse.height > 0 && viewSize.width > 0 && viewSize.height > 0 {
            let scaleX = viewSize.width / sizeToUse.width
            let scaleY = viewSize.height / sizeToUse.height
            initialScale = min(scaleX, scaleY) * 0.95
        }

        scrollView.minimumZoomScale = min(initialScale * 0.1, 0.05)
        scrollView.maximumZoomScale = max(initialScale * 10.0, 5.0)
        scrollView.zoomScale = initialScale

        let currentWidth = sizeToUse.width * initialScale
        let currentHeight = sizeToUse.height * initialScale
        let insetX = max(0, (viewSize.width - currentWidth) / 2)
        let insetY = max(0, (viewSize.height - currentHeight) / 2)
        scrollView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)

        DispatchQueue.main.async {
            let toolPicker = PKToolPicker()
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            canvasView.becomeFirstResponder()
            context.coordinator.toolPicker = toolPicker
        }

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        if let container = context.coordinator.containerView,
            let bgView = container.viewWithTag(100) as? UIImageView
        {
            bgView.alpha = showBackground ? CGFloat(backgroundOpacity) : 0.0

            let currentWidth = container.bounds.width * uiView.zoomScale
            let currentHeight = container.bounds.height * uiView.zoomScale
            let insetX = max(0, (viewSize.width - currentWidth) / 2)
            let insetY = max(0, (viewSize.height - currentHeight) / 2)
            uiView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var containerView: UIView?
        var toolPicker: PKToolPicker?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { containerView }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let container = containerView else { return }
            let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
            let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
            container.center = CGPoint(
                x: scrollView.contentSize.width * 0.5 + offsetX,
                y: scrollView.contentSize.height * 0.5 + offsetY)
        }
    }
}
