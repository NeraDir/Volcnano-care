import Foundation
import AppsFlyerLib

class Prejhghjdfgjd: NSObject, AppsFlyerLibDelegate {
    static let shared = Prejhghjdfgjd()
    private var conversionDataReceived = false
    private var conversionCompletion: ((String?) -> Void)?

    func startTracking(completion: @escaping (String?) -> Void) {
        self.conversionCompletion = completion

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            if !self.conversionDataReceived {
                self.conversionCompletion?(nil)
            }
        }
    }

    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        print("succ")
        if let campaign = data["campaign"] as? String {
            let components = campaign.split(separator: "_")
            var wehfsjdhgj = ""
            for (index, value) in components.enumerated() {
                wehfsjdhgj += "sub\(index + 1)=\(value)"
                if index < components.count - 1 {
                    wehfsjdhgj += "&"
                }
            }
            conversionDataReceived = true
            conversionCompletion?("&" + wehfsjdhgj)
        }
    }

    func onConversionDataFail(_ error: Error) {
        print("Conversion data failed: \(error.localizedDescription)")
        conversionCompletion?(nil)
    }
    
    func onAppOpenAttribution(_ attributionData: [AnyHashable: Any]) {
        print("onAppOpenAttribution: \(attributionData)")
        if let campaign = attributionData["campaign"] as? String {
            let hrtughyhuh = campaign.split(separator: "_")
            var parameters = ""
            for (index, value) in hrtughyhuh.enumerated() {
                parameters += "sub\(index + 1)=\(value)"
                if index < hrtughyhuh.count - 1 {
                    parameters += "&"
                }
            }
            conversionDataReceived = true
            conversionCompletion?("&" + parameters)
        }
    }
    
    func onAppOpenAttributionFailure(_ error: Error) {
        print("onAppOpenAttributionFailure: \(error.localizedDescription)")
        conversionCompletion?(nil)
    }
} 
