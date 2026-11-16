#if canImport(Glibc)
    import Glibc
#elseif canImport(Darwin)
    import Darwin
#else
    #error("Permitter currently supports Linux and macOS only.")
#endif

/// Writes to the standard streams without buffering, so broken pipes can be
/// reported instead of terminating the process.
enum StandardStream {
    enum WriteResult: Equatable {
        case success
        case brokenPipe
        case failure(Int32)
    }

    /// Makes writes to a closed pipe return `EPIPE` instead of terminating the
    /// process with `SIGPIPE`.
    static func ignoreBrokenPipeSignal() {
        signal(SIGPIPE, SIG_IGN)
    }

    static func writeToStandardOutput(_ text: String) -> WriteResult {
        write(text, to: STDOUT_FILENO)
    }

    static func writeToStandardError(_ text: String) -> WriteResult {
        write(text, to: STDERR_FILENO)
    }

    private static func write(_ text: String, to descriptor: Int32) -> WriteResult {
        let bytes = Array(text.utf8)
        return bytes.withUnsafeBytes { buffer in
            guard let baseAddress = buffer.baseAddress, !buffer.isEmpty else {
                return .success
            }

            var offset = 0
            while offset < buffer.count {
                let written = systemWrite(
                    descriptor,
                    baseAddress.advanced(by: offset),
                    buffer.count - offset
                )
                if written < 0 {
                    if errno == EINTR {
                        continue
                    }
                    if errno == EPIPE {
                        return .brokenPipe
                    }
                    return .failure(errno)
                }
                offset += written
            }
            return .success
        }
    }
}

#if canImport(Glibc)
    private let systemWrite = Glibc.write
#elseif canImport(Darwin)
    private let systemWrite = Darwin.write
#endif
