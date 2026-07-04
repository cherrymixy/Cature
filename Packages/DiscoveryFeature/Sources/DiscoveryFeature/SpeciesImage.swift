//  SpeciesImage.swift
//  DiscoveryFeature — 종 이름으로 위키백과 대표 이미지 URL 조회(공개 REST, 키 불필요).

import Foundation

func fetchRepresentativeImageURL(for name: String) async -> URL? {
    guard let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
          let api = URL(string: "https://ko.wikipedia.org/api/rest_v1/page/summary/\(encoded)"),
          let (data, _) = try? await URLSession.shared.data(from: api),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return nil }
    let source = (json["originalimage"] as? [String: Any])?["source"] as? String
        ?? (json["thumbnail"] as? [String: Any])?["source"] as? String
    return source.flatMap { URL(string: $0) }
}
