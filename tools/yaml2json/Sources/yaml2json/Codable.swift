//
//  File.swift
//  
//
//  Created by Yannick Heinrich on 02.12.21.
//

import Foundation
import Yams

// MARK: - Decodable types
// MARK: - Codable
private struct SessionKey: CodingKey {
    var stringValue: String

    var intValue: Int? { return nil}

    init?(intValue: Int) {
        return nil
    }
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
}

private enum CodingKeys: String, CodingKey {
    case title = ":title", description = ":description", track = ":track"
}

/// Hold session information
struct Session {
    init(id: String, description: String, title: String, track: String) {
        self.id = id
        self.description = description
        self.title = title
        self.track = track
    }

    let id: String
    let description: String
    let title: String
    let track: String
}

// Hold Year event
struct YearContent: Decodable {
    let sessions: [Session]
    
    // MARK: - Init
    init(sessions: [Session]) {
        self.sessions = sessions
    }
    
    init(from decoder: Decoder) throws {
        // We get the top container as sessions keys
        let container = try decoder.container(keyedBy: SessionKey.self)

        let sessions = try container.allKeys.map { sessionKey -> Session in
            let subContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: sessionKey)
            
            let title = try subContainer.decode(String.self, forKey: .title)
            let description = try subContainer.decode(String.self, forKey: .description)
            let track = try subContainer.decode(String.self, forKey: .track)
            return Session(id: sessionKey.stringValue, description: description, title: title, track: track)
        }
        self.sessions = sessions
    }
}

struct YearEvent {
    let sessions: [Session]
    let year: UInt
    
}

struct SessionAlternate: Decodable {
    let id: UInt
    let session: Content

    struct Content: Decodable {
        let description: String
        let title: String
        let track: String

        enum CodingKeys: String, CodingKey {
            case title = ":title", description = ":description", track = ":track"

        }
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.id = try container.decode(UInt.self)
        self.session = try container.decode(Content.self)
    }
}


enum Either<A:  Decodable, B: Decodable>: Decodable {
    case left(A)
    case right(B)

    init(from decoder: Decoder) throws {
        if let value = try? A(from: decoder) {
            self = .left(value)
        } else if let value = try? B(from: decoder) {
            self = .right(value)
        } else {
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "can not decode \(A.self) or \(B.self)")
            throw DecodingError.dataCorrupted(context)
        }
    }
}

struct OutFormat: Encodable {
    let events: [YearEvent]
    init(events: [YearEvent]) {
        self.events = events
    }

    enum EncodingKeys: String, CodingKey {
        case title, description, track, url
    }

    // MARK: - Encodable
    func encode(to encoder: Encoder) throws {
        var topContainer = encoder.container(keyedBy: SessionKey.self)

        for event in self.events {

            let yearKey = SessionKey(stringValue: "\(event.year)")!
            var yearContainer = topContainer.nestedContainer(keyedBy: SessionKey.self, forKey: yearKey)

            for session in event.sessions {
                let sessionKey = SessionKey(stringValue: session.id)!
                var sessionContainer = yearContainer.nestedContainer(keyedBy: EncodingKeys.self, forKey: sessionKey)
                try sessionContainer.encode(session.title, forKey: .title)
                try sessionContainer.encode(session.description, forKey: .description)
                try sessionContainer.encode(session.track, forKey: .track)

                // We convert the session to url
                let year = "\(event.year)"
                let wwdcPath = year[year.index(year.endIndex, offsetBy: -2)..<year.endIndex]

                let url = URL(string: "https://developer.apple.com/wwdc\(wwdcPath)/\(session.id)")
                try sessionContainer.encode(url, forKey: .url)
            }
        }
        
    }
}
// MARK: - Operation
struct ParseYamlOperation {
    
    /// The year
    let year: UInt
    
    /// The URL to the _sessions.yaml file for the year
    let sessionYaml: URL
    
    func parse() throws -> YearEvent {
        print("Decoding \(self.year)")
        let data = try Data(contentsOf: self.sessionYaml)
        let decoder = YAMLDecoder()
        
        let eithers = try decoder.decode(Either<YearContent, [SessionAlternate]>.self, from: data)
        let sessions: [Session]
        switch eithers {
        case .right(let element):
            sessions = element.map { Session(id: "\($0.id)", description: $0.session.description, title: $0.session.title, track: $0.session.track)}
        case .left(let element):
            sessions = element.sessions
        }
        return YearEvent(sessions: sessions, year: self.year)
    }
}

