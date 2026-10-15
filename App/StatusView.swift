import SwiftUI
import Video

/// Explains the current connection state and, when needed, what to do next.
struct StatusView: View {
    let state: ConnectionState

    var body: some View {
        ContentUnavailableView(title, systemImage: symbolName, description: hint.map(Text.init))
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
        case .waitingForAuthorization(.deviceNotReady):
            "Déverrouillez votre iPhone et touchez « Se fier » si la question s'affiche."
        case .connected:
            nil
        }
    }
}
