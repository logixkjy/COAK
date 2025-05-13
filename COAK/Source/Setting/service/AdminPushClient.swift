//
//  AdminPushClient.swift
//  COAK
//
//  Created by JooYoung Kim on 5/14/25.
//

import ComposableArchitecture
import Foundation

struct AdminPushClient {
    var sendPush: @Sendable (String, String) async throws -> Void
}

extension AdminPushClient: DependencyKey {
    static let liveValue: AdminPushClient = .init(
        sendPush: { title, body in
            // Firebase Functions 엔드포인트 호출
            let url = URL(string: "https://us-central1-koac-841d0.cloudfunctions.net/sendAdminPush")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let payload: [String: Any] = [
                "title": title,
                "body": body
            ]
            
            // JSON 직렬화
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            } catch {
                throw URLError(.cannotParseResponse)
            }

            // 비동기 HTTP 요청
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // HTTP 응답 상태 코드 확인
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let responseString = String(data: data, encoding: .utf8) ?? "No response"
                print("Error: Server responded with status code: \(String(describing: (response as? HTTPURLResponse)?.statusCode)), Response: \(responseString)")
                throw URLError(.badServerResponse)
            }
            
            print("Push sent successfully: \(String(data: data, encoding: .utf8) ?? "No response")")
        }
    )
}

extension DependencyValues {
    var adminPushClient: AdminPushClient {
        get { self[AdminPushClient.self] }
        set { self[AdminPushClient.self] = newValue }
    }
}
