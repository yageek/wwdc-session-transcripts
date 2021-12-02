//
//  File.swift
//  
//
//  Created by Yannick Heinrich on 02.12.21.
//

import Foundation
import Yams

// MARK: - Decodable types

/// Hold session information
struct Session: Codable {
    let id: String
    let description: String
    let title: String
    let track: String
}

// Hold Year event
struct YearContent: Codable {
    let sessions: [Session]
    
    // MARK: - Init
    init(sessions: [Session]) {
        self.sessions = sessions
    }
    
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
    
    // MARK: - Encodable
    func encode(to encoder: Encoder) throws {
        var topContainer = encoder.container(keyedBy: SessionKey.self)
        
        for session in self.sessions {
            
            let key = SessionKey(stringValue: session.id)!
            var sessionContainer = topContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: key)
            try sessionContainer.encode(session.title, forKey: .title)
            try sessionContainer.encode(session.description, forKey: .description)
            try sessionContainer.encode(session.track, forKey: .track)
        }
    }
}

struct YearEvent: Codable {
    let sessions: [Session]
    let year: UInt
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
        
        let sessions = try decoder.decode(YearContent.self, from: data)
        return YearEvent(sessions: sessions.sessions, year: self.year)
    }
}

