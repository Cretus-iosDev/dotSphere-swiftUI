import SwiftUI
import simd

// MARK: - Dot Model
struct Dot: Identifiable {
    let id = UUID()
    var start: SIMD3<Double>
    var end: SIMD3<Double>
    var color: Color = .white

    func interpolated(_ progress: Double) -> SIMD3<Double> {
        mix(start, end, t: progress)
    }

    private func mix(_ a: SIMD3<Double>, _ b: SIMD3<Double>, t: Double) -> SIMD3<Double> {
        return a + (b - a) * t
    }
}

// MARK: - ViewModel
class DotSphereViewModel: ObservableObject {
    @Published var dots: [Dot] = []
    @Published var progress: Double = 0.0
    @Published var shapeType: ShapeType = .sphere

    let totalDots = 500

    init() {
        generateDots()
    }

    enum ShapeType: String, CaseIterable, Identifiable {
        case sphere, star, torus
        var id: String { rawValue }
    }

    func generateDots() {
        var newDots: [Dot] = []
        for i in 0..<totalDots {
            let start = SIMD3<Double>(
                Double.random(in: -1...1),
                Double.random(in: -1...1),
                Double.random(in: -1...1)
            )
            let end = generateShapePoint(index: i, total: totalDots)
            newDots.append(Dot(start: start, end: end))
        }
        dots = newDots
    }

    func generateShapePoint(index: Int, total: Int) -> SIMD3<Double> {
        switch shapeType {
        case .sphere:
            return fibonacciSphere(index: index, total: total)
        case .star:
            return starShape(index: index, total: total)
        case .torus:
            return torusShape(index: index, total: total)
        }
    }

    func fibonacciSphere(index: Int, total: Int) -> SIMD3<Double> {
        let offset = 2.0 / Double(total)
        let increment = .pi * (3.0 - sqrt(5.0))

        let y = ((Double(index) * offset) - 1) + (offset / 2)
        let r = sqrt(1 - y * y)
        let phi = Double(index) * increment

        let x = cos(phi) * r
        let z = sin(phi) * r

        return SIMD3<Double>(x, y, z)
    }

    func starShape(index: Int, total: Int) -> SIMD3<Double> {
        let angle = Double(index) / Double(total) * 2 * Double.pi * 5 // 5-point star
        let radius = 0.8 + 0.2 * sin(5 * angle)
        let x = cos(angle) * radius
        let y = sin(angle) * radius
        return SIMD3<Double>(x, y, 0)
    }

    func torusShape(index: Int, total: Int) -> SIMD3<Double> {
        let majorRadius = 1.0
        let minorRadius = 0.4

        let theta = 2 * Double.pi * Double(index) / Double(total)
        let phi = 4 * Double.pi * Double(index) / Double(total)

        let x = (majorRadius + minorRadius * cos(phi)) * cos(theta)
        let y = (majorRadius + minorRadius * cos(phi)) * sin(theta)
        let z = minorRadius * sin(phi)

        return SIMD3<Double>(x, y, z)
    }
}

// MARK: - Main View
struct MorphingDotSphereView: View {
    @StateObject private var viewModel = DotSphereViewModel()
    @State private var angle: Angle = .degrees(0)

    var body: some View {
        VStack {
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    for dot in viewModel.dots {
                        let interpolated = dot.interpolated(viewModel.progress)

                        // Rotation
                        let rotated = rotate3D(point: interpolated, angle: angle.radians)
                        let projected = project(point: rotated, size: size)

                        let yColorRatio = (rotated.y + 1) / 2
                        let color = Color(hue: yColorRatio, saturation: 1, brightness: 1)

                        let dotSize = CGSize(width: 4, height: 4)
                        let rect = CGRect(origin: CGPoint(x: projected.x - dotSize.width / 2,
                                                         y: projected.y - dotSize.height / 2),
                                          size: dotSize)

                        context.fill(
                            Circle().path(in: rect),
                            with: .color(color)
                        )
                    }
                }
                .background(Color.black)
                .onChange(of: timeline.date) {
                    angle += .degrees(0.5)
                }

            }

            Slider(value: $viewModel.progress, in: 0...1)
                .padding()

            Picker("Shape", selection: $viewModel.shapeType) {
                ForEach(DotSphereViewModel.ShapeType.allCases) { shape in
                    Text(shape.rawValue.capitalized).tag(shape)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .onChange(of: viewModel.shapeType) {
                viewModel.generateDots()
            }

        }
    }

    func rotate3D(point: SIMD3<Double>, angle: Double) -> SIMD3<Double> {
        let rotationMatrix = simd_double3x3(
            SIMD3<Double>(cos(angle), 0, -sin(angle)),
            SIMD3<Double>(0, 1, 0),
            SIMD3<Double>(sin(angle), 0, cos(angle))
        )
        return rotationMatrix * point
    }

    func project(point: SIMD3<Double>, size: CGSize) -> CGPoint {
        let scale = 150.0
        let x = point.x * scale + size.width / 2
        let y = point.y * scale + size.height / 2
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Preview
struct MorphingDotSphereView_Previews: PreviewProvider {
    static var previews: some View {
        MorphingDotSphereView()
    }
}
