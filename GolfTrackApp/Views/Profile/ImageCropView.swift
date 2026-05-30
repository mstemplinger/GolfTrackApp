import SwiftUI

struct ImageCropView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let cropSize: CGFloat = 280

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Image with gestures
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = max(1.0, lastScale * value)
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                },
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                    )
                    .clipped()
            }

            // Dimming overlay with circular cutout
            CropOverlay(cropSize: cropSize)
                .allowsHitTesting(false)

            // Crop circle border
            Circle()
                .stroke(AppTheme.gold, lineWidth: 2)
                .frame(width: cropSize, height: cropSize)
                .allowsHitTesting(false)

            // Buttons
            VStack {
                HStack {
                    Button("Abbrechen") { dismiss() }
                        .foregroundStyle(.white)
                        .padding()
                    Spacer()
                    Button("Übernehmen") {
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
        .onAppear { fitImageToCircle() }
    }

    private func fitImageToCircle() {
        // Scale image so it at least fills the crop circle
        let imgW = image.size.width
        let imgH = image.size.height
        let minDim = min(imgW, imgH)
        let needed = cropSize / min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * max(imgW, imgH)
        scale = max(1.0, cropSize / minDim * (UIScreen.main.bounds.width / max(imgW, imgH)) * (imgW / imgH))
        lastScale = scale
    }

    private func cropImage() -> UIImage {
        let screenScale = UIScreen.main.scale
        let viewW = UIScreen.main.bounds.width
        let viewH = UIScreen.main.bounds.height

        // Render the current state into a UIImage
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cropSize, height: cropSize))
        return renderer.image { ctx in
            ctx.cgContext.translateBy(x: cropSize / 2, y: cropSize / 2)

            let imgAspect = image.size.width / image.size.height
            let baseW: CGFloat
            let baseH: CGFloat
            if imgAspect > 1 {
                baseH = viewH
                baseW = baseH * imgAspect
            } else {
                baseW = viewW
                baseH = baseW / imgAspect
            }

            let scaledW = baseW * scale
            let scaledH = baseH * scale

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
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .compositingGroup()
    }
}
