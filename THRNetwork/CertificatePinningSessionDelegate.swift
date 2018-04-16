//
//  CertificatePinningSessionDelegate.swift
//  THRNetwork
//
//  Created by Sam Oakley on 07/11/2016.
//  Copyright © 2016 Sam Oakley. All rights reserved.
//

import Foundation


/// A URLSessionDelegate that you can use with your URLSession to implement Certificate Pinning.
/// Add valid certificates to your bundle with the file name corresponding to the domain you want to pin.
/// For example, "google.com.cer" for connections to google.com. 
///
/// If a certificate is missing, the terminal command to generate it will be printed to the console.
public class CertificatePinningSessionDelegate: NSObject, URLSessionDelegate {
    
    let domains: [String]?
    
    /// Create a URLSessionDelegate implementing Certificate Pinning.
    ///
    /// - parameter domains: An array of domains to pin. If not provided, all domains will be pinned.
    ///
    /// - returns: A new CertificatePinningSessionDelegate.
    public init(withPinnedDomains domains: [String]? = nil) {
        self.domains = domains
        super.init()
    }
    
    
    /// :nodoc:
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        let domain = challenge.protectionSpace.host
        
        // If there is a list of domains, and the current domain is not in there, don't pin it.
        if let pinnedDomains = domains {
            if !pinnedDomains.contains(domain) {
                completionHandler(.performDefaultHandling, nil)
                return
            }
        }
        
        // Check that trust settings are available.
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            print("Missing trust settings for '\(domain)'")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Check that a certificate is present in any bundle.
        guard let pathToCert = Bundle.allBundles.path(forResource: domain, ofType: "cer"),
            let localCertificate = NSData(contentsOfFile: pathToCert) else {
                print("Missing local certificate for '\(domain)'. Disable certificate pinning, or add a valid certificate to your bundle with the file name '\(domain).cer'.\n\n"
                    + "To get your certificate, run the following command:\n\n"
                    + "openssl s_client -showcerts -connect \(domain):\(challenge.protectionSpace.port) < /dev/null | openssl x509 -outform DER > \(domain).cer\n\n")
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
        }
        
        let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0)
        
        // Set SSL policies for domain name check
        let policies = NSArray(array: [SecPolicyCreateSSL(true, (challenge.protectionSpace.host as CFString))])
        SecTrustSetPolicies(serverTrust, policies)
        
        // Evaluate server certificate
        var result: SecTrustResultType = SecTrustResultType.invalid
        SecTrustEvaluate(serverTrust, &result)
        let isServerTrusted = (result == SecTrustResultType.unspecified || result == SecTrustResultType.proceed)
        
        // Get remote cert data
        let remoteCertificateData = SecCertificateCopyData(certificate!) as Data
        
        if (isServerTrusted && remoteCertificateData == localCertificate as Data) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
            return
        }
        
        
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}

extension Collection where Iterator.Element: Bundle {
    func path(forResource resource: String, ofType type: String) -> String? {
        for bundle in self {
            if let path = bundle.path(forResource: resource, ofType: type) {
                return path
            }
        }
        return nil
    }
}
