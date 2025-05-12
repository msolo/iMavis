import SwiftUI

class ZeroConfController: NSObject,
  NetServiceBrowserDelegate,
  NetServiceDelegate
{
  static let shared = ZeroConfController()

  // Local service browser
  var browser = NetServiceBrowser()

  // Instance of the service that we're looking for
  var service: NetService?

  var serviceType: String?

  var _resolvedAddr: String?
  // A resolved address - host:port as a string.
  var resolvedAddr: String? {
    if _resolvedAddr == nil {
      start()
    }
    return _resolvedAddr
  }

  func discover(serviceType: String) {
    // Make sure to reset the last known service if we want to run this a few times
    self.serviceType = serviceType
    service = nil
    browser.delegate = self
    start()
  }

  private func start() {
    guard let serviceType = self.serviceType else { return }
    // Start the discovery
    browser.stop()
    browser.searchForServices(ofType: serviceType, inDomain: "")

    // Don't search forever.
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
      self.browser.stop()
    }
  }

  func reset() {
    service = nil
    _resolvedAddr = nil
  }

  // MARK: Service discovery
  func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
    print("Start service search \(serviceType!) ")
  }

  func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
    print("Resolve service error:", sender, errorDict)
    reset()
  }

  func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
    print("Stop service search \(serviceType!) ")
  }

  func netServiceBrowser(_ browser: NetServiceBrowser, didFind svc: NetService, moreComing: Bool) {
    print("Discovered service \"\(svc.name)\" \(svc.type) \(svc.domain)")

    // We just need the first service
    if service != nil {
      return
    }

    service = svc
    // Stop after we find first service
    browser.stop()

    // Resolve the service in 5 seconds
    svc.delegate = self

    print("Attempt service resolve \"\(svc.name)\" \(svc.type) \(svc.domain)")
    svc.resolve(withTimeout: 5)
  }

  func netServiceDidResolveAddress(_ svc: NetService) {
    guard let addrs = svc.addresses else {
      print("Resolved no addresses for \"\(svc.name)\" \(svc.type).\(svc.domain)")
      return
    }

    // Find the IPV4 address
    guard let ip = resolveIPv4(addresses: addrs) else {
      print("Resolved no IPv4 addresses for \"\(svc.name)\" \(svc.type).\(svc.domain)")
      return
    }

    let addr = "\(ip):\(svc.port)"
    _resolvedAddr = addr
    print("Resolved service \"\(svc.name)\" \(svc.type) \(svc.domain) to \(addr)")
    if let data = svc.txtRecordData() {
      let dict = NetService.dictionary(fromTXTRecord: data)
      //      let value = String(data: dict["hello"]!, encoding: String.Encoding.utf8)
      if !dict.isEmpty {
        print("TXT record:", dict)
      }
    }
  }

  // Find an IPv4 address from the service address data
  func resolveIPv4(addresses: [Data]) -> String? {
    var result: String?

    for addr in addresses {
      let data = addr as NSData
      var storage = sockaddr_storage()
      data.getBytes(&storage, length: MemoryLayout<sockaddr_storage>.size)

      if Int32(storage.ss_family) == AF_INET {
        let addr4 = withUnsafePointer(to: &storage) {
          $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
            $0.pointee
          }
        }

        if let ip = String(cString: inet_ntoa(addr4.sin_addr), encoding: .ascii) {
          result = ip
          break
        }
      }
    }

    return result
  }
}

struct ZeroConf: View {
  var body: some View {
    Text( /*@START_MENU_TOKEN@*/"Hello, World!" /*@END_MENU_TOKEN@*/)
    Button("Resolve") {
      ZeroConfController.shared.discover(serviceType: "_mavis-corrector._tcp")
    }
  }
}

#Preview {
  ZeroConf()
}
