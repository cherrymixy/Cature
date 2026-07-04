//  CoexistCache.swift
//  ServicesPackage — 공존 카드 로컬 캐시. 큐레이션(seed) 우선.

import Foundation
import CorePackage

public actor CoexistCache {
    private let url: URL
    private var cards: [String: CoexistCard]

    public init(fileURL: URL, curated: [CoexistCard] = []) {
        self.url = fileURL
        let loaded = (try? Data(contentsOf: fileURL))
            .flatMap { try? JSONDecoder().decode([CoexistCard].self, from: $0) } ?? []
        var dict = Dictionary(uniqueKeysWithValues: loaded.map { ($0.speciesId, $0) })
        for card in curated { dict[card.speciesId] = card }   // 큐레이션 우선
        self.cards = dict
    }

    public func card(for speciesId: String) -> CoexistCard? { cards[speciesId] }

    /// best-effort 캐시 저장(실패해도 흐름 중단 안 함).
    public func store(_ card: CoexistCard) {
        cards[card.speciesId] = card
        guard let data = try? JSONEncoder().encode(Array(cards.values)) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }
}
