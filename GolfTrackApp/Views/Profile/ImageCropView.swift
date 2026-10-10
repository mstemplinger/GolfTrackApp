import SwiftUI

struct ImageCropView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var containerSize: CGSize = UIScreen.main.bounds.size

    private let cropSize: CGFloat = 280

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Bild, Abdunklung und Ring teilen sich denselben Rahmen,
            // damit Ausschnitt und Ring exakt übereinanderliegen.
            GeometryReader { geo in
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .contentShape(Rectangle())
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = min(maxScale, max(minScale, lastScale * value))
                                        offset = clampedOffset(offset)
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                        lastOffset = offset
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        offset = clampedOffset(CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        ))
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                        )

                    // Dimming overlay with circular cutout
                    CropOverlay(cropSize: cropSize)
                        .allowsHitTesting(false)

                    // Crop circle border
                    Circle()
                        .stroke(AppTheme.gold, lineWidth: 2)
                        .frame(width: cropSize, height: cropSize)
                        .allowsHitTesting(false)
                }
                .onAppear { containerSize = geo.size }
                .onChange(of: geo.size) { _, newSize in containerSize = newSize }
            }
            .ignoresSafeArea()

            // Buttons
            VStack {
                HStack {
                    Button("Abbrechen") {
                        Haptics.tap()
                        dismiss()
                    }
                    .foregroundStyle(.white)
                        .padding()
                    Spacer()
                    Button("Übernehmen") {
                        Haptics.success()
                        let cropped = cropImage()
                        onCrop(cropped)
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(AppTheme.gold)
                    .padding()
                }
                Spacer()
                Text("Ziehen & Zoomen zum Anpassen")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 40)
            }
        }
    }

    private let maxScale: CGFloat = 6

    /// Bildgröße bei Zoom 1 (scaledToFill im Rahmen).
    private var baseSize: CGSize {
        let viewW = containerSize.width
        let viewH = containerSize.height
        let imgAspect = image.size.width / image.size.height
        if imgAspect > viewW / viewH {
            return CGSize(width: viewH * imgAspect, height: viewH)
        }
        return CGSize(width: viewW, height: viewW / imgAspect)
    }

    /// Kleinster Zoom, bei dem das Bild den Ring gerade noch ausfüllt.
    private var minScale: CGFloat {
        let base = baseSize
        return min(1, cropSize / min(base.width, base.height))
    }

    /// Hält den Ring immer vollständig mit Bild bedeckt.
    private func clampedOffset(_ proposed: CGSize) -> CGSize {
        let base = baseSize
        let maxX = max(0, (base.width * scale - cropSize) / 2)
        let maxY = max(0, (base.height * scale - cropSize) / 2)
        return CGSize(
            width: min(maxX, max(-maxX, proposed.width)),
            height: min(maxY, max(-maxY, proposed.height))
        )
    }

    private func cropImage() -> UIImage {
        // Render the current state into a UIImage
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cropSize, height: cropSize))
        return renderer.image { ctx in
            ctx.cgContext.translateBy(x: cropSize / 2, y: cropSize / 2)

            let base = baseSize
            let scaledW = base.width * scale
            let scaledH = base.height * scale

            ctx.cgContext.translateBy(x: offset.width, y: offset.height)
            image.draw(in: CGRect(x: -scaledW / 2, y: -scaledH / 2, width: scaledW, height: scaledH))
        }
    }
}

// MARK: - Crop Overlay (dim everything outside the circle)

private struct CropOverlay: View {
    let cropSize: CGFloat
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.55)))
            let circle = Path(ellipseIn: CGRect(
                x: size.width / 2 - cropSize / 2,
                y: size.height / 2 - cropSize / 2,
                width: cropSize, height: cropSize
            ))
            context.blendMode = .destinationOut
            context.fill(circle, with: .color(.black))
        }
        .allowsHitTesting(false)
        .compositingGroup()
    }
}
