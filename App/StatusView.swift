import SwiftUI
import Video

/// Explains the current connection state and, when needed, what to do next.
struct StatusView: View {
    let state: ConnectionState

    @Environment(\.openURL) private var openURL

    var body: some View {
        // Only the actions take clicks: elsewhere, dragging moves the window.
        ContentUnavailableView {
            Label(title, systemImage: symbolName)
                .allowsHitTesting(false)
        } description: {
            if let hint {
                Text(hint)
                    .allowsHitTesting(false)
            }
        } actions: {
            if state == .waitingForAuthorization(.cameraAccessDenied) {
                Button("Ouvrir les Réglages Système") {
                    openURL(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")!)
                }
            }
        }
    }

    private var symbolName: String {
        switch state {
        case .noDevice: "iphone.slash"
        case .waitingForAuthorization: "lock.iphone"
        case .connected: "iphone"
        }
    }

    private var title: String {
        switch state {
        case .noDevice: "Aucun iPhone"
        case .waitingForAuthorization: "En attente d'autorisation"
        case .connected(let deviceName): "Connecté à \(deviceName)"
        }
    }

    private var hint: String? {
        switch state {
        case .noDevice:
            "Branchez votre iPhone à ce Mac avec un câble USB."
        case .waitingForAuthorization(.cameraAccessNotDetermined):
            "Autorisez PhoneMirror à utiliser la caméra pour afficher l'écran de l'iPhone."
        case .waitingForAuthorization(.cameraAccessDenied):
            "Autorisez PhoneMirror dans Réglages Système › Confidentialité et sécurité › Caméra."
        case .waitingForAuthorization(.cameraAccessRestricted):
            "L'accès à la caméra est bloqué sur ce Mac par un profil de gestion ou le contrôle parental."
        case .waitingForAuthorization(.deviceNotReady):
            "Déverrouillez votre iPhone et touchez « Se fier » si la question s'affiche."
        case .connected:
            nil
        }
    }
}
