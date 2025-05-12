import Foundation

struct CorrectorReply: Codable {
  var error: String?
  var returnValue: [String]?

  enum CodingKeys: String, CodingKey {
    case error
    // FIXME: this name has made this unnecessarily difficult.
    case returnValue = "return"
  }
}

class CompletionService {
  var reply: CorrectorReply?

  func fetchData(from url: URL, completion: @escaping () -> Void) -> URLSessionDataTask {
    let urlRequest = URLRequest(url: url, timeoutInterval: 1.5)
    self.reply = nil
    let task = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, _, error in
      if let error = error {
        switch (error as NSError).code {
        case NSURLErrorNetworkConnectionLost:
          print("network connection lost: \(error)")
        case NSURLErrorTimedOut:
          print("url request timeout: \(error)")
        default:
          print("url fetch error: \(error)")
        }
        ZeroConfController.shared.reset()
      }

      guard self != nil else {
        // [weak self] seems to be guarding against a leak when the
        // dataTask retains the view.
        print("nil self in CompletionService callback")
        return
      }
      if let jsonData = data {
        do {
          self!.reply = try JSONDecoder().decode(CorrectorReply.self, from: jsonData)
        } catch {
          print("invalid json: \(error)")
        }
      }
      completion()
    }
    task.resume()
    return task
  }
}
