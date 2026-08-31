import Foundation

extension URL {
    public var schemeRemoved: String {
        guard let scheme: String = scheme else {
            return absoluteString
        }
        
        return absoluteString.replacingOccurrences(of: scheme + "://", with: "")
    }
    
    public var trailingQuestionMarkRemoved: URL {
        if absoluteString.last == "?" {
            var string: String = absoluteString
            string.removeLast()
            return URL(string: string)!
        } else {
            return self
        }
    }
    
    public static var fakeUserImage: URL {
        .init(string: "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=880&q=80")!
    }
    
    public static var randomImageURL: URL {
        URL(string: "https://picsum.photos/id/\(Int.random(in: 1...1000))/512/512")!
    }
    
    public static var fakeImageURL: URL {
        URL(string: "https://picsum.photos/id/237/512/512")!
    }
}
