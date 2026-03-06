import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 20)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Image(systemName: "cube.transparent")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.blue)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)

                    Text("ScenInk")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text("Pose your 3D models and draw over them seamlessly.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)

                VStack(alignment: .leading, spacing: 15) {
                    Text("My Projects")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 32)

                    LazyVGrid(columns: columns, spacing: 20) {
                        NavigationLink(
                            destination: SingleDummyEditorView(viewModel: SceneEditorViewModel())
                        ) {
                            VStack(spacing: 12) {
                                Image(systemName: "plus")
                                    .font(.system(size: 36, weight: .light))
                                    .foregroundColor(.blue)

                                Text("New Scene")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 170)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                                    .foregroundColor(.blue.opacity(0.4))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        ForEach(viewModel.savedScenes) { scene in
                            NavigationLink(
                                destination: SingleDummyEditorView(
                                    viewModel: SceneEditorViewModel(document: scene))
                            ) {
                                SceneCardView(scene: scene, viewModel: viewModel)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 32)
                }
            }
            .padding(.bottom, 60)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            viewModel.fetchScenes()
        }
    }
}

struct SceneCardView: View {
    let scene: SceneDocument
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                Color.gray.opacity(0.2)

                if let image = DataManager.shared.loadThumbnail(for: scene.id) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .layoutPriority(-1)
                } else {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
            }
            .frame(height: 120)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(scene.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(scene.lastModified.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        .overlay(
            Button(action: {
                viewModel.deleteScene(id: scene.id)
            }) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
            }
            .padding(8),
            alignment: .topTrailing
        )
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
