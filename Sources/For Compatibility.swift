import Compatibility


// trimmed and trim functions should be on StringProtocol and not String

#if (os(WASM) || os(WASI)) && !canImport(Foundation) && compiler(>=6.2)
/// Backport for Foundation.Codable
public typealias Codable = Decodable & Encodable
public protocol Decodable {}
public protocol Encodable {}

// TODO: Implement backport versions for WASM, but for now, just include stubs to silence compiler warnings.

#endif
