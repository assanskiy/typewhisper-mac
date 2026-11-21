import Foundation

enum CalendarMeetingRecordingFilename {
    private static let maximumTitleGraphemes = 120
    private static let maximumTitleUTF8Bytes = 200
    private static let maximumFilenameUTF8Bytes = 255

    static func preferredBaseName(title: String, date: Date = Date()) -> String {
        let datePrefix = datePrefixString(for: date)
        let sanitizedTitle = sanitizeTitle(title)
        if sanitizedTitle.isEmpty {
            return "\(datePrefix) - Recording"
        }
        return "\(datePrefix) - \(sanitizedTitle)"
    }

    static func sanitizedBaseName(_ value: String, fallbackDate: Date = Date()) -> String {
        let normalized = normalize(value)
        return normalized.isEmpty ? "Recording \(timestampString(for: fallbackDate))" : normalized
    }

    static func availableURL(
        in directory: URL,
        preferredBaseName: String,
        fileExtension: String,
        fallbackDate: Date = Date(),
        fileExists: (String) -> Bool = FileManager.default.fileExists(atPath:)
    ) -> URL {
        let baseName = sanitizedBaseName(preferredBaseName, fallbackDate: fallbackDate)
        var suffix = 1
        while true {
            let collisionSuffix = suffix == 1 ? "" : " \(suffix)"
            let extensionByteCount = fileExtension.isEmpty ? 0 : fileExtension.utf8.count + 1
            let baseNameByteLimit = max(
                1,
                maximumFilenameUTF8Bytes - extensionByteCount - collisionSuffix.utf8.count
            )
            let truncatedBaseName = prefix(
                baseName,
                fittingUTF8ByteCount: baseNameByteLimit
            )
            let candidateName = truncatedBaseName + collisionSuffix
            let candidate = directory
                .appendingPathComponent(candidateName)
                .appendingPathExtension(fileExtension)
            // The audio may exist in another Recorder format (`X.m4a` beside a new `X.wav`):
            // both would write `X.txt`.
            let audioURLs = AudioRecorderService.OutputFormat.allCases.map {
                candidate.deletingPathExtension().appendingPathExtension($0.fileExtension)
            }
            let taken = ([candidate] + audioURLs).contains { url in
                recordingFileURLs(for: url).contains(where: { fileExists($0.path) })
            }
            if !taken {
                return candidate
            }
            suffix += 1
        }
    }

    /// The audio file and the files the Recorder keeps beside it (the list
    /// `AudioRecorderViewModel.deleteRecording` trashes). A name stays taken while any of
    /// them exists: a new recording at that name would otherwise read the earlier
    /// recording's `recording_id` and overwrite its transcript and receipt after the
    /// audio was moved or deleted outside the app (#1774).
    private static func recordingFileURLs(for audioURL: URL) -> [URL] {
        let baseURL = audioURL.deletingPathExtension()
        return [
            audioURL,
            baseURL.appendingPathExtension("txt"),
            baseURL.appendingPathExtension("transcript.md"),
            baseURL.appendingPathExtension("transcript.json"),
            audioURL.appendingPathExtension("transcript-ready.json"),
            audioURL.appendingPathExtension("recording-id.json"),
            audioURL.appendingPathExtension("transcription-failure.json"),
            TranscriptTimestampsFile.url(besideAudio: audioURL),
        ]
    }

    private static func sanitizeTitle(_ title: String) -> String {
        let graphemeLimited = String(normalize(title).prefix(maximumTitleGraphemes))
        return prefix(graphemeLimited, fittingUTF8ByteCount: maximumTitleUTF8Bytes)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func prefix(
        _ value: String,
        fittingUTF8ByteCount maximumByteCount: Int
    ) -> String {
        var byteCount = 0
        var result = ""
        for character in value {
            let characterByteCount = String(character).utf8.count
            guard byteCount + characterByteCount <= maximumByteCount else { break }
            result.append(character)
            byteCount += characterByteCount
        }
        return result
    }

    private static func normalize(_ value: String) -> String {
        let precomposed = value.precomposedStringWithCanonicalMapping
        let normalizedScalars = precomposed.unicodeScalars.map { scalar in
            if CharacterSet.controlCharacters.contains(scalar)
                || scalar == "/"
                || scalar == ":" {
                return UnicodeScalar(0x20)!
            }
            return scalar
        }
        let withoutInvalidScalars = String(String.UnicodeScalarView(normalizedScalars))
        let collapsed = withoutInvalidScalars
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return collapsed.drop(while: { $0 == "." || $0.isWhitespace }).description
    }

    private static func timestampString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        return formatter.string(from: date)
    }

    private static func datePrefixString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }
}
