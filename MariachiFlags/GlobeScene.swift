import SceneKit
import UIKit

class GlobeScene {
    let scene: SCNScene
    let sphereNode: SCNNode
    let cameraNode: SCNNode

    let sphereRadius: Double = 1.0
    let idleCameraDistance: Float = 3.0
    let zoomedCameraDistance: Float = 1.8

    private var highlightNode: SCNNode?
    private var borderFeatures: [[String: Any]] = []

    init() {
        scene = SCNScene()

        // Earth sphere
        let sphere = SCNSphere(radius: sphereRadius)
        sphere.segmentCount = 64
        let material = SCNMaterial()
        if let texture = UIImage(named: "earth_texture") {
            material.diffuse.contents = texture
        } else {
            material.diffuse.contents = UIColor.systemBlue
        }
        material.specular.contents = UIColor(white: 0.3, alpha: 1.0)
        material.shininess = 0.1
        material.lightingModel = .blinn
        sphere.materials = [material]

        sphereNode = SCNNode(geometry: sphere)
        scene.rootNode.addChildNode(sphereNode)

        // Camera
        let camera = SCNCamera()
        camera.fieldOfView = 45
        camera.zNear = 0.1
        camera.zFar = 100
        cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, idleCameraDistance)

        let lookAt = SCNLookAtConstraint(target: sphereNode)
        lookAt.isGimbalLockEnabled = true
        cameraNode.constraints = [lookAt]
        scene.rootNode.addChildNode(cameraNode)

        // Ambient light — globe visible from all angles
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 600
        ambientLight.light?.color = UIColor.white
        scene.rootNode.addChildNode(ambientLight)

        // Directional light for subtle shading
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 400
        directionalLight.light?.color = UIColor.white
        directionalLight.position = SCNVector3(5, 5, 5)
        directionalLight.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(directionalLight)

        // Dark space background
        scene.background.contents = UIColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1.0)

        // Load and render country borders
        loadBorders()
    }

    /// Convert latitude/longitude to a 3D position on the sphere surface
    func positionOnSphere(latitude: Double, longitude: Double) -> SCNVector3 {
        let latRad = latitude * .pi / 180.0
        let lonRad = longitude * .pi / 180.0
        let r = sphereRadius
        let x = r * cos(latRad) * sin(lonRad)
        let y = r * sin(latRad)
        let z = r * cos(latRad) * cos(lonRad)
        return SCNVector3(Float(x), Float(y), Float(z))
    }

    // MARK: - Country Highlighting

    // Map our country names to GeoJSON names where they differ
    private static let nameToGeoJSON: [String: String] = [
        "United States": "United States of America",
        "Tanzania": "United Republic of Tanzania",
        "DR Congo": "Democratic Republic of the Congo",
        "Congo": "Republic of the Congo",
        "Serbia": "Republic of Serbia",
        "Bahamas": "The Bahamas",
        "Eswatini": "Swaziland",
        "Ivory Coast": "Ivory Coast",
        "North Korea": "North Korea",
        "South Korea": "South Korea",
        "Czech Republic": "Czech Republic",
        "Timor-Leste": "East Timor",
    ]

    /// Highlight a specific country's borders in bright color
    func highlightCountry(named countryName: String) {
        // Remove previous highlight
        highlightNode?.removeFromParentNode()
        highlightNode = nil

        let geoName = GlobeScene.nameToGeoJSON[countryName] ?? countryName
        let highlightRadius = sphereRadius * 1.002
        var allVertices: [SCNVector3] = []
        var allIndices: [UInt32] = []

        for feature in borderFeatures {
            guard let props = feature["properties"] as? [String: Any],
                  let name = props["name"] as? String,
                  name == geoName,
                  let geometry = feature["geometry"] as? [String: Any],
                  let type = geometry["type"] as? String else { continue }

            let rings = extractRings(geometry: geometry, type: type)
            for ring in rings {
                addTriangleStripBorder(ring, radius: highlightRadius, halfWidth: 0.006,
                                       vertices: &allVertices, indices: &allIndices)
            }
        }

        if !allVertices.isEmpty {
            let node = createTriangleNode(vertices: allVertices, indices: allIndices,
                                           color: UIColor(red: 0.2, green: 1.0, blue: 0.4, alpha: 0.9))
            sphereNode.addChildNode(node)
            highlightNode = node
        }
    }

    /// Remove country highlight
    func clearHighlight() {
        highlightNode?.removeFromParentNode()
        highlightNode = nil
    }

    // MARK: - Border Rendering

    private func loadBorders() {
        guard let url = Bundle.main.url(forResource: "borders", withExtension: "geojson"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = json["features"] as? [[String: Any]] else { return }

        self.borderFeatures = features

        let borderRadius = sphereRadius * 1.001
        var allVertices: [SCNVector3] = []
        var allIndices: [UInt32] = []

        for feature in features {
            guard let geometry = feature["geometry"] as? [String: Any],
                  let type = geometry["type"] as? String else { continue }

            let rings = extractRings(geometry: geometry, type: type)
            for ring in rings {
                addTriangleStripBorder(ring, radius: borderRadius, halfWidth: 0.002,
                                       vertices: &allVertices, indices: &allIndices)
            }
        }

        if !allVertices.isEmpty {
            let bordersNode = createTriangleNode(vertices: allVertices, indices: allIndices,
                                                  color: UIColor(white: 1.0, alpha: 0.55))
            sphereNode.addChildNode(bordersNode)
        }
    }

    private func extractRings(geometry: [String: Any], type: String) -> [[[Double]]] {
        var rings: [[[Double]]] = []
        if type == "Polygon", let coords = geometry["coordinates"] as? [[[Double]]] {
            if let ring = coords.first { rings.append(ring) }
        } else if type == "MultiPolygon", let polys = geometry["coordinates"] as? [[[[Double]]]] {
            for poly in polys {
                if let ring = poly.first { rings.append(ring) }
            }
        }
        return rings
    }

    private func spherePoint(_ lon: Double, _ lat: Double, _ radius: Double) -> simd_float3 {
        let latRad = Float(lat * .pi / 180.0)
        let lonRad = Float(lon * .pi / 180.0)
        let r = Float(radius)
        return simd_float3(
            r * cos(latRad) * sin(lonRad),
            r * sin(latRad),
            r * cos(latRad) * cos(lonRad)
        )
    }

    /// Build triangle-strip quads for a border ring with actual width
    private func addTriangleStripBorder(_ coordinates: [[Double]], radius: Double, halfWidth: Float,
                                         vertices: inout [SCNVector3], indices: inout [UInt32]) {
        guard coordinates.count > 1 else { return }

        // Downsample dense rings
        let step = coordinates.count > 200 ? 3 : (coordinates.count > 100 ? 2 : 1)

        var points: [simd_float3] = []
        for i in stride(from: 0, to: coordinates.count, by: step) {
            let coord = coordinates[i]
            guard coord.count >= 2 else { continue }
            points.append(spherePoint(coord[0], coord[1], radius))
        }
        guard points.count > 1 else { return }

        // For each point, compute the offset direction (perpendicular to edge and surface normal)
        let baseIdx = UInt32(vertices.count)

        for i in 0..<points.count {
            let p = points[i]
            let next = points[(i + 1) % points.count]
            let prev = points[(i + points.count - 1) % points.count]

            // Surface normal (radial direction from sphere center)
            let normal = simd_normalize(p)
            // Average edge direction
            let edgeDir = simd_normalize(next - prev)
            // Perpendicular to both edge and normal = width direction
            var widthDir = simd_cross(edgeDir, normal)
            let len = simd_length(widthDir)
            if len > 0.001 {
                widthDir = widthDir / len * halfWidth
            } else {
                widthDir = simd_float3(halfWidth, 0, 0)
            }

            let left = p - widthDir
            let right = p + widthDir
            vertices.append(SCNVector3(left.x, left.y, left.z))
            vertices.append(SCNVector3(right.x, right.y, right.z))
        }

        // Create triangles connecting consecutive quads
        let vertCount = UInt32(points.count)
        for i in 0..<vertCount {
            let j = (i + 1) % vertCount
            let i0 = baseIdx + i * 2       // left of current
            let i1 = baseIdx + i * 2 + 1   // right of current
            let i2 = baseIdx + j * 2       // left of next
            let i3 = baseIdx + j * 2 + 1   // right of next

            // Two triangles per quad
            indices.append(contentsOf: [i0, i1, i2])
            indices.append(contentsOf: [i1, i3, i2])
        }
    }

    private func createTriangleNode(vertices: [SCNVector3], indices: [UInt32], color: UIColor) -> SCNNode {
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let indexData = Data(bytes: indices, count: indices.count * MemoryLayout<UInt32>.size)
        let element = SCNGeometryElement(
            data: indexData,
            primitiveType: .triangles,
            primitiveCount: indices.count / 3,
            bytesPerIndex: MemoryLayout<UInt32>.size
        )

        let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.lightingModel = .constant
        material.isDoubleSided = true
        geometry.materials = [material]

        return SCNNode(geometry: geometry)
    }
}
