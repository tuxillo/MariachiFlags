import SceneKit

class GlobeAnimator {
    private let globeScene: GlobeScene
    private let idleActionKey = "idleRotation"

    var onArrivedAtCountry: (() -> Void)?
    var onReturnedToIdle: (() -> Void)?

    init(globeScene: GlobeScene) {
        self.globeScene = globeScene
    }

    // MARK: - Idle Rotation

    func startIdleRotation() {
        let sphere = globeScene.sphereNode
        sphere.removeAction(forKey: idleActionKey)

        let rotate = SCNAction.repeatForever(
            SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 30)
        )
        sphere.runAction(rotate, forKey: idleActionKey)

        // Ensure camera is at idle distance on Z axis
        let camera = globeScene.cameraNode
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.5
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        camera.position = SCNVector3(0, 0, globeScene.idleCameraDistance)
        SCNTransaction.commit()
    }

    // MARK: - Fly to Country

    func flyToCountry(_ country: Country) {
        let sphere = globeScene.sphereNode
        let camera = globeScene.cameraNode

        // Stop idle rotation and freeze at current presentation state
        sphere.removeAction(forKey: idleActionKey)
        let currentOrientation = sphere.presentation.orientation
        sphere.orientation = currentOrientation

        // Calculate target quaternion that brings the country to face the camera (+Z axis)
        // We need to rotate the sphere so lat/lon maps to the +Z direction
        let latRad = Float(country.latitude * .pi / 180.0)
        let lonRad = Float(country.longitude * .pi / 180.0)

        // Rotation: first rotate around Y by -longitude, then around X by +latitude
        // Using quaternion multiplication for smooth interpolation
        let qY = simd_quatf(angle: -lonRad, axis: simd_float3(0, 1, 0))
        let qX = simd_quatf(angle: latRad, axis: simd_float3(1, 0, 0))
        let targetQ = simd_mul(qX, qY)

        // Highlight the target country's borders
        globeScene.highlightCountry(named: country.name)

        // Animate sphere rotation and camera zoom simultaneously
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2.0
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        SCNTransaction.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                self?.onArrivedAtCountry?()
            }
        }

        // Rotate the sphere using quaternion (SceneKit uses SLERP for smooth interpolation)
        sphere.simdOrientation = targetQ

        // Zoom camera in
        camera.position = SCNVector3(0, 0, globeScene.zoomedCameraDistance)

        SCNTransaction.commit()
    }

    // MARK: - Zoom Out

    func zoomOut() {
        let camera = globeScene.cameraNode

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.5
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        SCNTransaction.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                self?.startIdleRotation()
                self?.onReturnedToIdle?()
            }
        }

        // Clear country highlight and zoom camera back out
        globeScene.clearHighlight()
        camera.position = SCNVector3(0, 0, globeScene.idleCameraDistance)

        SCNTransaction.commit()
    }
}
