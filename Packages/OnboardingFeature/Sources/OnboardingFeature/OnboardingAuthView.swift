//  OnboardingAuthView.swift
//  Cature — 온보딩 마지막: 최소 Auth (닉네임 + @아이디).
//
//  · 아이디는 "유니크 형식" 검증(소문자·숫자·밑줄 3–15자) — 내부 규칙만 검사.
//  · 통과 시 ProfileRepository(mock/실구현)에 UserProfile 저장 → onComplete.

import CorePackage
import DesignTokens
import SwiftUI

struct OnboardingAuthView: View {
    let profileRepository: any ProfileRepository
    let onComplete: () -> Void

    @State private var nickname = ""
    @State private var userId = ""
    @State private var isSaving = false
    @State private var errorText: String?

    private var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var normalizedUserId: String {
        userId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    private var isNicknameValid: Bool {
        (1...20).contains(trimmedNickname.count)
    }
    private var isUserIdValid: Bool {
        Self.isValidUserId(normalizedUserId)
    }
    private var canSubmit: Bool {
        isNicknameValid && isUserIdValid && !isSaving
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CatureSpacing.lg) {
            VStack(alignment: .leading, spacing: CatureSpacing.xs) {
                Text("프로필을 만들어요")
                    .font(CatureFont.largeTitle)
                    .foregroundStyle(CatureColor.textPrimary)
                Text("도감과 지도에서 보일 이름이에요.")
                    .font(CatureFont.body)
                    .foregroundStyle(CatureColor.textSecondary)
            }
            .padding(.top, CatureSpacing.xl)

            field(title: "닉네임") {
                TextField("예: 산책자", text: $nickname)
                    .textInputAutocapitalization(.never)
            }

            VStack(alignment: .leading, spacing: CatureSpacing.xxs) {
                field(title: "아이디") {
                    HStack(spacing: 2) {
                        Text("@")
                            .foregroundStyle(CatureColor.textSecondary)
                        TextField("소문자·숫자·밑줄 3–15자", text: $userId)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                if !normalizedUserId.isEmpty && !isUserIdValid {
                    hint("아이디는 소문자·숫자·밑줄(_) 3–15자만 쓸 수 있어요.")
                }
            }

            if let errorText {
                hint(errorText)
            }

            Spacer()

            Button {
                Task { await save() }
            } label: {
                if isSaving {
                    ProgressView().tint(CatureColor.onFab)
                } else {
                    Text("Cature 시작하기")
                }
            }
            .buttonStyle(.caturePrimary)
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.5)
        }
        .padding(.horizontal, CatureSpacing.lg)
        .padding(.bottom, CatureSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func field<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: CatureSpacing.xs) {
            Text(title)
                .font(CatureFont.headline)
                .foregroundStyle(CatureColor.textPrimary)
            content()
                .font(CatureFont.body)
                .foregroundStyle(CatureColor.textPrimary)
                .padding(.horizontal, CatureSpacing.md)
                .padding(.vertical, CatureSpacing.sm)
                .background(CatureColor.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: CatureRadius.md, style: .continuous))
        }
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .font(CatureFont.caption)
            .foregroundStyle(.red)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func save() async {
        errorText = nil
        isSaving = true
        defer { isSaving = false }

        let profile = UserProfile(userId: normalizedUserId, nickname: trimmedNickname)
        do {
            try await profileRepository.save(profile)
            onComplete()
        } catch {
            errorText = "저장에 실패했어요. 다시 시도해 주세요."
        }
    }

    /// 유니크 형식 검증: 소문자·숫자·밑줄 3–15자.
    static func isValidUserId(_ value: String) -> Bool {
        guard (3...15).contains(value.count) else { return false }
        let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789_")
        return value.allSatisfy { allowed.contains($0) }
    }
}

#Preview("Auth") {
    OnboardingAuthView(profileRepository: MockProfileRepository(), onComplete: {})
}
