import SwiftUI

struct WatchQRView: View {
    @EnvironmentObject var store: WatchDataStore

    private var qrImage: UIImage? {
        guard !store.qrBase64.isEmpty,
              let data = Data(base64Encoded: store.qrBase64) else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        VStack(spacing: 6) {
            if let img = qrImage {
                Image(uiImage: img)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.18))
                    .frame(maxWidth: .infinity, maxHeight: 90)
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 28))
                                .foregroundColor(.gray)
                            Text("Synchronisez\nvos données")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    )
            }
            Text("Montrez pour le check-in")
                .font(.system(size: 9))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 4)
    }
}
