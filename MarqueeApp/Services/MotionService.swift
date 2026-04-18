import CoreMotion
import Observation

@Observable
@MainActor
final class MotionService {
    private let manager = CMMotionManager()
    private var referenceAttitude: CMAttitude?

    // Offsets in radians from the reference attitude
    private(set) var yawOffset: Double = 0    // left/right
    private(set) var pitchOffset: Double = 0  // up/down

    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            if let ref = self.referenceAttitude {
                motion.attitude.multiply(byInverseOf: ref)
                self.yawOffset = motion.attitude.yaw
                self.pitchOffset = motion.attitude.pitch
            } else {
                self.referenceAttitude = motion.attitude.copy() as? CMAttitude
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }

    func resetReference() {
        referenceAttitude = nil
        yawOffset = 0
        pitchOffset = 0
    }
}
