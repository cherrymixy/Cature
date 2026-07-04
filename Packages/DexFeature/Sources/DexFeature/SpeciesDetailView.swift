//  SpeciesDetailView.swift
//  Cature — 도감 종 상세 (찬희 S2). 도감 그리드에서 종을 탭하면 진입.
//
//  구성(플레이북 S2):
//   · 종 소개 + usdz 미리보기 자리(플레이스홀더) + 발견 지역
//   · 공존 카드 재열람: 필요한 것 / 조심할 것 2블록 (LLMService.coexistCard, mock)
//   · 발견 기록: 촬영 N회, 처음/마지막 발견 시각, 마지막 발견 위치 (CollectionEntry + Sighting, mock)
//
//  데이터는 CorePackage 프로토콜로만. 스타일은 시맨틱 시스템 폰트/색(하드코딩 hex 없음).

import CorePackage
import Foundation
import SwiftUI

struct DexSpeciesDetailView: View {
    @StateObject private var viewModel: DexSpeciesDetailViewModel

    init(
        species: Species,
        entry: CollectionEntry?,
        sightingRepository: any SightingRepository,
        llmService: any LLMService
    ) {
        _viewModel = StateObject(
            wrappedValue: DexSpeciesDetailViewModel(
                species: species,
                entry: entry,
                sightingRepository: sightingRepository,
                llmService: llmService
            )
        )
    }

    var body: some View {
        List {
            headerSection
            introSection
            coexistSection
            recordSection
        }
        .navigationTitle(viewModel.species.nameKo)
        .task { await viewModel.load() }
    }

    // MARK: 헤더 — usdz 미리보기 자리 + 이름/카테고리
    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                UsdzPreviewPlaceholder(canExperience: viewModel.species.canExperience)
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.species.nameKo)
                        .font(.title2.weight(.bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Text(viewModel.species.category)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: 소개 (공존 카드 intro)
    private var introSection: some View {
        Section("소개") {
            if let intro = viewModel.intro {
                Text(intro)
                    .font(.callout)
            } else if viewModel.isLoading {
                loadingRow
            } else {
                Text("소개 정보를 불러오지 못했어요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: 공존 카드 재열람 — 필요한 것 / 조심할 것
    private var coexistSection: some View {
        Section("함께 살기") {
            if !viewModel.needs.isEmpty || !viewModel.disturbances.isEmpty {
                CoexistBlock(title: "필요한 것", symbol: "leaf.fill", items: viewModel.needs)
                CoexistBlock(title: "조심할 것", symbol: "exclamationmark.triangle.fill", items: viewModel.disturbances)
                if let source = viewModel.cardSource {
                    Text(source == .curated ? "검수된 정보예요." : "AI가 정리한 정보예요.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.isLoading {
                loadingRow
            } else {
                Text("공존 카드를 불러오지 못했어요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: 발견 기록
    private var recordSection: some View {
        Section("발견 기록") {
            if let entry = viewModel.entry, entry.discovered {
                InfoRow(label: "촬영 횟수", value: "\(entry.captureCount)회")
                InfoRow(label: "처음 발견", value: DexDateFormat.string(entry.firstSeenAt))
                InfoRow(label: "마지막 발견", value: DexDateFormat.string(entry.lastSeenAt))
                InfoRow(label: "발견 지역", value: viewModel.lastLocationName ?? "위치 정보 없음")
            } else {
                EmptyPolicyView(
                    title: "아직 발견하지 않았어요",
                    message: "카메라로 이 생물을 발견하면 기록이 여기에 쌓여요."
                )
            }
        }
    }

    private var loadingRow: some View {
        HStack(spacing: 8) {
            ProgressView()
            Text("불러오는 중…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - usdz 미리보기 플레이스홀더

struct UsdzPreviewPlaceholder: View {
    let canExperience: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.secondary.opacity(0.12))
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .overlay {
                VStack(spacing: 10) {
                    Image(systemName: canExperience ? "cube.transparent.fill" : "cube")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.secondary)
                    Text(canExperience ? "AR 체험 가능" : "AR 준비중")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(canExperience ? "AR 미리보기, 체험 가능" : "AR 미리보기, 준비중")
    }
}

// MARK: - 공존 카드 블록 (필요한 것 / 조심할 것)

struct CoexistBlock: View {
    let title: String
    let symbol: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(item)
                }
                .font(.callout)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(items.joined(separator: ", "))")
    }
}

// MARK: - 라벨/값 한 줄

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.callout)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 날짜 포맷 (yyyy.MM.dd HH:mm, ko_KR)

enum DexDateFormat {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy.MM.dd HH:mm"
        return f
    }()

    static func string(_ date: Date) -> String { formatter.string(from: date) }
}

// MARK: - 상세 ViewModel

@MainActor
final class DexSpeciesDetailViewModel: ObservableObject {
    @Published private(set) var intro: String?
    @Published private(set) var needs: [String] = []
    @Published private(set) var disturbances: [String] = []
    @Published private(set) var cardSource: CardSource?
    @Published private(set) var lastLocationName: String?
    @Published private(set) var isLoading = true

    let species: Species
    let entry: CollectionEntry?

    private let sightingRepository: any SightingRepository
    private let llmService: any LLMService

    init(
        species: Species,
        entry: CollectionEntry?,
        sightingRepository: any SightingRepository,
        llmService: any LLMService
    ) {
        self.species = species
        self.entry = entry
        self.sightingRepository = sightingRepository
        self.llmService = llmService
    }

    func load() async {
        if let card = try? await llmService.coexistCard(speciesId: species.id) {
            intro = card.intro
            needs = card.needs
            disturbances = card.disturbances
            cardSource = card.source
        }

        if let sightings = try? await sightingRepository.sightings(speciesId: species.id) {
            // 가장 최근 발견의 위치를 "발견 지역"으로.
            lastLocationName = sightings.max { $0.createdAt < $1.createdAt }?.locationName
        }

        isLoading = false
    }
}

#if !CLI_BUILD
#Preview("발견함") {
    NavigationView {
        DexSpeciesDetailView(
            species: SampleData.species[1], // 카멜레온 (usdz 있음)
            entry: CollectionEntry(
                speciesId: "chameleon",
                captureCount: 3,
                discovered: true,
                firstSeenAt: Date(timeIntervalSince1970: 1_720_000_000),
                lastSeenAt: Date(timeIntervalSince1970: 1_720_500_000),
                isFavorite: false
            ),
            sightingRepository: MockSightingRepository(sightings: [
                Sighting(
                    id: "s1",
                    speciesId: "chameleon",
                    photoPath: "",
                    latitude: 37.5665,
                    longitude: 126.9780,
                    locationName: "서울특별시 중구",
                    createdAt: Date(timeIntervalSince1970: 1_720_500_000)
                )
            ]),
            llmService: MockLLMService()
        )
    }
}

#Preview("미발견") {
    NavigationView {
        DexSpeciesDetailView(
            species: SampleData.species[4], // 무당벌레 (usdz 없음 → AR 준비중)
            entry: nil,
            sightingRepository: MockSightingRepository(),
            llmService: MockLLMService()
        )
    }
}
#endif
