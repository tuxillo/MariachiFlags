import SwiftUI
import SceneKit

struct GlobeView: UIViewRepresentable {
    let globeScene: GlobeScene

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = globeScene.scene
        scnView.pointOfView = globeScene.cameraNode
        scnView.backgroundColor = .clear
        scnView.allowsCameraControl = false
        scnView.antialiasingMode = .multisampling4X
        scnView.isPlaying = true
        scnView.preferredFramesPerSecond = 60
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}
