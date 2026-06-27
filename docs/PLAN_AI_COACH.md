# AI 코치 — 백엔드 연동 챗봇 계획서

## 1. 목표

- **AI 코치**(`aicoach`) 화면의 정적 목업 채팅을 **실제 대화형 챗봇**으로 전환한다.
- **LLM 호출·API 키·프롬프트 정책**은 모두 **Spring 백엔드**(`http://dontdelay.duckdns.org:8080`)에서 처리한다. Flutter 앱에는 비밀키를 넣지 않는다.
- 기존 **세션 로그인**(`dio` + `CookieManager`, `/api/auth/login`)과 동일한 인증 체계로 AI API를 보호한다.
- 사용자의 **할 일·일정 컨텍스트**를 요청에 포함해 “오늘 뭐부터 할까?” 같은 **학습·우선순위 코칭** 답변을 받는다.
- 응답에 **추천 할 일 카드**(`recommendations`)를 구조화 JSON으로 내려, 현재 UI(`_buildRecommendationCard`)와 연동한다.

---

## 2. 범위 및 비범위

| 포함 | 제외(이번 단계) |
|------|-----------------|
| 백엔드 `POST /api/ai/chat` (스트리밍 없음, 단일 응답) | SSE / WebSocket 스트리밍 응답 |
| 로그인 사용자만 채팅 가능 | 비로그인 게스트 모드 |
| 클라이언트가 보내는 **컨텍스트 스냅샷**(할 일 목록) | 서버가 `todos.json`을 직접 읽기 (로컬 파일은 앱에만 있음) |
| Flutter: 메시지 목록·전송·로딩·에러 UI, 추천 카드 완료 처리 | AI가 할 일을 **자동 생성·저장** |
| 서버 측 대화 **세션 ID** + 최근 N턴 히스토리 | 장기 대화 검색·보내기 |
| 추천 카드 JSON 스키마 | 캘린더 서버 동기화 (캘린더는 앱 내 더미 → 2차에서 컨텍스트 확장) |
| Rate limit·타임아웃·에러 코드 표준화 | 다국어(i18n) |
| 빠른 제안 칩 → 동일 API 호출 | Chrome 확장·로컬 URL API와의 직접 연동 |

---

## 2.1 현재 Flutter 구현 상태

- `feat/ai코치` 브랜치에서 AI 코치 프론트 MVP 구현 완료.
- [`aicoach.dart`](../lib/features/aicoach.dart)는 정적 목업이 아니라 실제 채팅 상태를 렌더링한다.
- [`ai_coach_provider.dart`](../lib/features/aicoach/ai_coach_provider.dart)는 메시지 목록, 전송 중 상태, 에러, `sessionId`를 관리한다.
- [`ai_coach_service.dart`](../lib/features/aicoach/ai_coach_service.dart)는 `POST /api/ai/chat`을 호출한다.
- 백엔드 API가 아직 없거나 `404`/`501`/`502`/연결 실패가 발생하면 앱 내부 mock 코칭 응답으로 fallback한다.
- `401`/`400`/`429`/`AI_DISABLED`는 fallback하지 않고 사용자에게 에러로 표시한다.
- `recommendations[].relatedTodoId`가 있으면 추천 카드 체크 버튼으로 해당 todo를 완료 처리할 수 있다.
- `recommendations[].action == createTodo`이고 `todoDraft`가 있으면 추천 카드에서 새 할 일을 추가할 수 있다.

---

## 3. 전체 아키텍처

```text
┌──────────────────────────────────────────────────────────────────┐
│  DontDelay (Flutter Desktop)                                     │
│  ┌─────────────┐   ┌──────────────────┐   ┌─────────────────┐  │
│  │ aicoach.dart│◀──│ ai_coach_provider │◀──│ ai_coach_service │  │
│  │ (채팅 UI)   │   │ (Riverpod)        │   │ (Dio)            │  │
│  └─────────────┘   └─────────┬────────┘   └────────┬────────┘  │
│                              │                        │           │
│  ┌───────────────────────────┴────────────────────────┘           │
│  │ todoListProvider → 컨텍스트 스냅샷 조립 (미완료 할 일 등)        │
│  │ authProvider → 로그인 여부, 미로그인 시 안내                    │
│  └──────────────────────────────────────────────────────────────┘
└───────────────────────────────┬──────────────────────────────────┘
                                │ HTTPS/HTTP
                                │ Cookie: JSESSIONID (기존 로그인)
                                │ POST /api/ai/chat
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│  Spring Boot (dontdelay.duckdns.org:8080)                        │
│  ┌──────────────┐   ┌─────────────┐   ┌──────────────────────┐  │
│  │ Security     │──▶│ AiCoach     │──▶│ LLM Provider         │  │
│  │ (세션 인증)  │   │ Controller  │   │ (OpenAI / Gemini 등) │  │
│  └──────────────┘   │ + Service   │   │ API Key: env only    │  │
│                     └──────┬──────┘   └──────────────────────┘  │
│                            │                                     │
│                     ┌──────▼──────┐   (선택) DB                  │
│                     │ ChatSession │   chat_session, chat_message │
│                     │ Repository  │                              │
│                     └─────────────┘                              │
└──────────────────────────────────────────────────────────────────┘
```

**동작 요약**

1. 사용자가 로그인한 상태에서 AI 코치 화면에 질문 입력(또는 빠른 제안 칩).
2. 앱이 `todoListProvider` 등에서 **컨텍스트 스냅샷**을 만들고, 메시지 + (선택) `sessionId`를 백엔드로 POST.
3. 백엔드가 시스템 프롬프트 + 컨텍스트 + 대화 히스토리로 LLM 호출.
4. 응답 텍스트 + 구조화 `recommendations`를 JSON으로 반환.
5. 앱이 채팅 목록에 assistant 메시지 추가, ListView 하단 스크롤.

---

## 4. 인증·보안

| 항목 | 정책 |
|------|------|
| 인증 | 기존과 동일: `POST /api/auth/login` 후 **세션 쿠키**. AI API는 `authenticated` 필요. |
| Flutter | [`auth_provider.dart`](../lib/features/auth/auth_provider.dart)의 `dioProvider` 재사용. 별도 Bearer 토큰 없음. |
| API 키 | `application.yml` / 환경변수 (`OPENAI_API_KEY`, `GEMINI_API_KEY` 등). **저장소·Git·앱 바이너리에 금지**. |
| 미로그인 | `401` → 앱에서 “로그인이 필요합니다” + 로그인 화면 이동 유도. |
| 입력 검증 | `message` 길이 상한(예: 2,000자), `context` JSON 크기 상한(예: 32KB). |
| Rate limit | 사용자(세션)당 분당 N회(예: 10). 초과 시 `429`. |
| 로깅 | 프롬프트 전문은 운영 로그에 남기지 않거나 마스킹. 사용자 메시지만 감사 로그(선택). |
| CORS | 데스크탑 Dio는 브라우저 CORS 없음. 향후 웹 클라이언트 시 Origin 허용 목록 별도. |

---

## 5. 백엔드 API 명세

Base URL: `http://dontdelay.duckdns.org:8080` (운영 시 HTTPS 권장)

### 5.1 `POST /api/ai/chat`

**설명:** 한 턴의 사용자 메시지를 처리하고 AI 응답을 반환한다.

**인증:** 필수 (세션 쿠키)

**Request Headers**

| Header | 값 |
|--------|-----|
| `Content-Type` | `application/json` |
| `Cookie` | `JSESSIONID=...` (Dio `CookieManager`가 자동 첨부) |

**Request Body**

```json
{
  "message": "오늘 뭐부터 해야 해?",
  "sessionId": "550e8400-e29b-41d4-a716-446655440000",
  "locale": "ko-KR",
  "context": {
    "today": "2026-05-28",
    "todos": [
      {
        "id": "uuid",
        "title": "알고리즘 과제",
        "date": "2026-05-28",
        "status": "todo",
        "urgency": 8,
        "importance": 7,
        "priority": "high",
        "tag": "전공",
        "time": "14:00",
        "memo": "선택 필드",
        "repeat": "daily"
      }
    ],
    "upcomingEvents": []
  }
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `message` | `string` | O | 사용자 입력 (trim, 빈 문자열 불가) |
| `sessionId` | `string` | X | 대화 세션 UUID. 없으면 서버가 신규 생성 후 응답에 포함 |
| `locale` | `string` | X | 기본 `ko-KR` |
| `context` | `object` | X | 앱이 조립한 스냅샷. 없으면 일반 코칭만 수행 |
| `context.today` | `string` | X | ISO 날짜 `yyyy-MM-dd` |
| `context.todos` | `array` | X | 미완료·오늘 할 일 등 필터링된 목록 |
| `context.upcomingEvents` | `array` | X | 2차: 캘린더 연동 시 일정 요약 |

현재 Flutter는 `status != done`이고 오늘 삭제 override가 없는 todo를 `context.todos`에 포함한다.

**Response 200**

```json
{
  "sessionId": "550e8400-e29b-41d4-a716-446655440000",
  "reply": {
    "role": "assistant",
    "content": "안녕하세요! 오늘의 우선순위를 정리해 드릴게요.\n\n1. ...",
    "recommendations": [
      {
        "title": "알고리즘 과제 완성",
        "timeRange": "14:30 - 16:00",
        "tag": "마감 임박",
        "tagLevel": "urgent",
        "reason": "오늘 마감이라 먼저 처리해야 합니다.",
        "relatedTodoId": "uuid-or-null",
        "action": "completeTodo",
        "todoDraft": null
      },
      {
        "title": "운영체제 핵심 개념 40분 복습",
        "timeRange": "오늘 안에",
        "tag": "새 할 일",
        "tagLevel": "review",
        "reason": "시험 대비를 위해 작은 복습 단위로 추가할 수 있습니다.",
        "relatedTodoId": null,
        "action": "createTodo",
        "todoDraft": {
          "title": "운영체제 핵심 개념 40분 복습",
          "date": "2026-05-28",
          "priority": "medium",
          "urgency": 5,
          "importance": 6,
          "tag": "default",
          "memo": "AI 코치 추천"
        }
      }
    ],
    "createdAt": "2026-05-28T14:23:00+09:00"
  },
  "usage": {
    "promptTokens": 1200,
    "completionTokens": 450
  }
}
```

| 필드 | 설명 |
|------|------|
| `reply.content` | 마크다운 일부 허용(`**굵게**`). 앱은 1단계에서 plain text 렌더, 2단계에서 간단 파싱 |
| `reply.recommendations` | 없으면 `[]`. UI 추천 카드용 |
| `tagLevel` | `urgent` \| `scheduled` \| `review` \| `normal` → 앱에서 색상 매핑 |
| `relatedTodoId` | 기존 할 일과 연결 시 ID (없으면 `null`) |
| `reason` | 추천 카드 하단에 표시할 짧은 근거. 선택 필드 |
| `action` | `completeTodo` \| `createTodo` \| `none`. 프론트 추천 카드 버튼 동작 |
| `todoDraft` | `createTodo`일 때 새 할 일 초안. 사용자가 버튼을 눌러야 실제 저장 |
| `usage` | (선택) 과금·모니터링용 |

**Error Responses**

| HTTP | code (body) | 의미 | 앱 처리 |
|------|-------------|------|---------|
| 400 | `INVALID_MESSAGE` | 빈 메시지·길이 초과 | 스낵바 |
| 401 | — | 미로그인 | 로그인 유도 |
| 429 | `RATE_LIMITED` | 호출 과다 | “잠시 후 다시 시도” |
| 502 | `LLM_UNAVAILABLE` | LLM 업스트림 실패 | 재시도 버튼 |
| 503 | `AI_DISABLED` | 서버에서 AI 기능 off | 안내 문구 |

**Error Body 예시**

```json
{
  "error": "RATE_LIMITED",
  "message": "요청이 너무 많습니다. 1분 후 다시 시도해 주세요."
}
```

### 5.2 `DELETE /api/ai/chat/sessions/{sessionId}` (선택, Phase 3)

**설명:** 대화 기록 초기화(새 대화 시작).

**Response:** `204 No Content`

### 5.3 `GET /api/ai/chat/sessions/{sessionId}/messages` (선택, Phase 3)

**설명:** 앱 재실행 시 서버에 저장된 히스토리 복원.

**Response 200:** `{ "messages": [ { "role", "content", "createdAt" }, ... ] }`

> **1단계(MVP):** `POST /api/ai/chat`만 구현. 히스토리는 **클라이언트 메모리**에만 유지.  
> **2단계:** 서버 DB에 세션·메시지 저장 + `GET` 복원.

---

## 6. 백엔드 구현 설계 (Spring)

### 6.1 패키지 구조 (권장)

```text
com.dontdelay.ai
├── controller   AiCoachController
├── dto          ChatRequest, ChatResponse, RecommendationDto, ErrorResponse
├── service      AiCoachService, PromptBuilder, LlmClient (interface)
├── infra        OpenAiLlmClient / GeminiLlmClient
├── domain       ChatSession, ChatMessage (Phase 3)
└── repository   ChatSessionRepository (Phase 3)
```

### 6.2 `PromptBuilder` 책임

- **시스템 프롬프트:** DontDelay AI 코치 역할, 한국어, 할 일 우선순위·학습 계획 조언, 의학·법률 등 금지 주제 disclaim.
- **컨텍스트 블록:** `context.todos`를 bullet list로 직렬화 (제목, 마감일, urgency/importance, status).
- **출력 형식:** LLM에게 JSON 또는 구분자 기반 응답을 요청. **권장:** OpenAI `response_format: json_object` 또는 Gemini structured output으로 `content` + `recommendations` 파싱 안정화.
- **히스토리:** `sessionId`로 DB에서 최근 10~20턴 로드 (Phase 3). MVP는 요청 body에 `history`를 넣지 않고 **서버가 직전 턴만** DB에 쌓거나, MVP는 히스토리 없이 단발 질의만.

### 6.3 LLM Provider (택 1, 환경변수로 스위치)

| Provider | 환경변수 | 비고 |
|----------|----------|------|
| OpenAI | `OPENAI_API_KEY`, `OPENAI_MODEL=gpt-4o-mini` | 팀 익숙도 높음 |
| Google Gemini | `GEMINI_API_KEY`, `GEMINI_MODEL=gemini-2.0-flash` | 비용·한국어 |

`AiCoachService`는 `LlmClient` 인터페이스만 의존 → 구현체 교체 용이.

### 6.4 Security 설정

```java
// 예시: /api/ai/** 는 authenticated
.requestMatchers("/api/ai/**").authenticated()
```

- `/api/auth/**`는 기존 `permitAll` 유지.
- AI 엔드포인트는 **ROLE_USER** 이상.

### 6.5 DB 스키마 (Phase 3, JPA 예시)

**`chat_session`**

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | UUID PK | `sessionId` |
| `user_id` | FK | 로그인 사용자 |
| `created_at` | timestamp | |
| `updated_at` | timestamp | |

**`chat_message`**

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | bigint PK | |
| `session_id` | FK | |
| `role` | varchar | `user` / `assistant` |
| `content` | text | |
| `recommendations_json` | text nullable | assistant만 |
| `created_at` | timestamp | |

---

## 7. Flutter 클라이언트 설계

### 7.1 파일 구조 (현재)

```text
lib/features/
├── aicoach.dart                       # 화면 UI
└── aicoach/
    ├── ai_coach_model.dart            # 메시지, 추천 카드, 상태, 컨텍스트 DTO
    ├── ai_coach_provider.dart         # Notifier: messages, sessionId, isSending
    └── ai_coach_service.dart          # Dio POST /api/ai/chat + mock fallback
```

- 라우터 [`router.dart`](../lib/core/router.dart)는 기존 `features/aicoach.dart` import를 유지한다.

### 7.2 `ChatMessage` 모델

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | `String` | 클라이언트 UUID (UI key) |
| `role` | `enum` | `user` / `assistant` |
| `content` | `String` | 버블 텍스트 |
| `createdAt` | `DateTime` | 타임스탬프 표시 |
| `recommendations` | `List<CoachRecommendation>?` | assistant만 |

### 7.3 컨텍스트 스냅샷

- [`ai_coach_service.dart`](../lib/features/aicoach/ai_coach_service.dart)에서 `AiCoachContextSnapshot`을 생성한다.
- `ref.read(todoListProvider).value`에서 전달된 todo 중 `status != done` 필터.
- 오늘 날짜의 `deletedOverrides`에 포함된 반복 todo는 제외.
- `upcomingEvents`는 현재 빈 배열. 캘린더 연동 시 Phase 4에서 추가.

### 7.4 `AiCoachService`

```dart
Future<AiCoachSendResult> sendMessage({
  required String message,
  required List<TodoItem> todos,
  String? sessionId,
});
```

- `dioProvider` 사용.
- `POST /api/ai/chat` 성공 시 서버 응답을 `AiCoachMessage`로 파싱.
- `404`/`501`/`502`/연결 실패는 mock 응답 fallback.
- `401`/`400`/`429`/`AI_DISABLED`는 `AiCoachServiceException`으로 변환해 UI 에러로 표시.
- AI 전용 60초 타임아웃은 백엔드 API가 준비된 뒤 추가 검토.

### 7.5 `AiCoachNotifier` (Riverpod)

| 상태 | 설명 |
|------|------|
| `messages` | `List<ChatMessage>` |
| `sessionId` | 서버에서 받은 UUID 유지 |
| `isSending` | 전송 중 true, 입력·버튼 비활성 |
| `lastError` | 스낵바용 |

**`sendMessage(String text)` 흐름**

1. user 메시지 즉시 append (optimistic UI).
2. `isSending = true`.
3. `todoListProvider`의 현재 todo 목록을 `service.sendMessage(...)`에 전달.
4. 서비스가 컨텍스트 스냅샷 생성 후 `/api/ai/chat` 호출.
5. assistant append, `sessionId` 갱신.
6. catch → user 메시지 유지, 에러 배너 표시, `isSending = false`.

### 7.6 `aicoach.dart` UI 변경 요약

| 항목 | 변경 |
|------|------|
| 위젯 | `ConsumerStatefulWidget` |
| ListView | 하드코딩 제거 → `state.messages.map` |
| TextField | `TextEditingController`, Enter/전송 |
| 전송 버튼 | `onPressed: isLoading ? null : _send` |
| 빠른 제안 | 텍스트 설정 후 `_send()` |
| 로딩 | 하단 AI 버블 + `CircularProgressIndicator` |
| `tagLevel` → 색 | `urgent→red`, `scheduled→blue`, `review→orange` |
| 미로그인 | 헤더 아래 배너 + 입력 비활성 |

기존 `_buildUserMessage`, `_buildAiMessage`, `_buildRecommendationCard`, `_buildQuickSuggestion` **재사용**.

### 7.7 Dio 타임아웃

기존 `receiveTimeout: 3초`는 AI에 부적합. 다음 중 하나:

- AI 호출만 `Options(receiveTimeout: Duration(seconds: 60))`
- `aiDioProvider` 분리 (baseUrl 동일, 타임아웃만 상향)

---

## 8. 컨텍스트·프롬프트 정책 (제품)

| 규칙 | 설명 |
|------|------|
| 할 일 우선 | 마감 임박·urgency/importance 높은 항목을 먼저 언급 |
| 추천 카드 | 0~3개. 실행 가능한 시간대 제안 |
| 환각 방지 | `context.todos`에 없는 과제명을 “확인된 일정”처럼 단정하지 말 것 (시스템 프롬프트) |
| 빠른 제안 칩 | 고정 문구 3개는 그대로 API `message`로 전송 |

---

## 9. 구현 Phase

### Phase 0 — 설계 확정 (0.5~1일)

- [ ] LLM 벤더·모델·JSON 출력 방식 확정
- [ ] `POST /api/ai/chat` 요청/응답·에러 코드 확정
- [ ] `tagLevel` ↔ UI 색상 매핑 확정
- [ ] 본 문서 리뷰

### Phase 1 — 백엔드 MVP (3~5일)

- [ ] `AiCoachController`, `AiCoachService`, `PromptBuilder`
- [ ] `LlmClient` + 환경변수 API 키
- [ ] `POST /api/ai/chat` (세션 DB 없이 stateless 또는 메모리 세션)
- [ ] Security: `/api/ai/**` authenticated
- [ ] Rate limit (간단: Bucket4j 또는 인메모리)
- [ ] curl / Postman으로 로그인 쿠키 포함 수동 테스트

**완료 기준:**

```bash
# 1) 로그인으로 세션 쿠키 획득
curl -c cookies.txt -X POST http://dontdelay.duckdns.org:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test"}'

# 2) 채팅
curl -b cookies.txt -X POST http://dontdelay.duckdns.org:8080/api/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"오늘 할 일 추천해줘","context":{"today":"2026-05-28","todos":[]}}'
```

→ `200` + `reply.content` + `recommendations` 배열.

### Phase 2 — Flutter 연동 (2~4일)

- [ ] `lib/features/aicoach/` 모듈 분리
- [ ] `ai_coach_service`, `ai_coach_provider`, `ai_context_builder`
- [ ] `aicoach.dart` 동적 채팅·전송·로딩·에러
- [ ] `aiDioProvider` 또는 per-request 타임아웃 60초
- [ ] 미로그인 UX
- [ ] 로그인 후 E2E: 질문 → 추천 카드 표시

**완료 기준:** 앱에서 실제 LLM 답변이 버블에 표시되고, 하드코딩 데모 제거.

### Phase 3 — 대화 지속·초기화 (2~3일)

- [ ] DB `chat_session`, `chat_message`
- [ ] `GET .../messages`, `DELETE .../sessions/{id}`
- [ ] 화면 “새 대화” 버튼
- [ ] 앱 시작 시 마지막 `sessionId` 로컬 저장 (`flutter_secure_storage` 또는 shared_preferences)

### Phase 4 — 컨텍스트·UX 확장 (2~4일, 선택)

- [ ] 캘린더 `upcomingEvents` 스냅샷
- [ ] 추천 카드 → “할 일로 추가” (`todoListProvider.addTodo`)
- [ ] `reply.content` 간단 마크다운 렌더
- [ ] 서버 usage 모니터링·일일 quota per user
- [ ] 스트리밍 응답 (SSE)

---

## 10. 일정 요약

| Phase | 기간(1인 기준) | 산출물 |
|-------|----------------|--------|
| 0 설계 | 0.5~1일 | API·LLM 확정 |
| 1 백엔드 MVP | 3~5일 | `/api/ai/chat` |
| 2 Flutter | 2~4일 | 실연동 채팅 UI |
| 3 지속 대화 | 2~3일 | DB 히스토리 |
| 4 확장 | 2~4일 | 캘린더·할 일 추가 |
| **합계** | **약 2~3주** | |

**권장 순서:** Phase 0 → Phase 1 (curl) → Phase 2 → Phase 3 → Phase 4.

---

## 11. 테스트·확인 사항

### 백엔드

- [ ] 미로그인 `POST /api/ai/chat` → `401`
- [ ] 빈 `message` → `400`
- [ ] Rate limit 초과 → `429`
- [ ] LLM 키 누락/잘못됨 → `502` 또는 `503`, 스택은 클라이언트에 노출 안 함
- [ ] `context.todos` 0건 vs 30건 응답 품질
- [ ] `recommendations` JSON 파싱 실패 시 fallback(텍스트만 반환)

### Flutter

- [ ] 전송 중 중복 클릭 방지
- [ ] 네트워크 끊김 → 스낵바, user 메시지 유지
- [ ] 긴 응답 스크롤·타임아웃 60초
- [ ] 빠른 제안 칩 3종 동작
- [ ] 로그아웃 후 AI 화면 접근 시 안내

### 통합

- [ ] 할 일 추가/완료 후 같은 세션에서 다시 질문 시 최신 `context` 반영
- [ ] 세션 쿠키 만료 → `401` → 재로그인

---

## 12. 제약 및 참고

| 항목 | 설명 |
|------|------|
| 할 일 저장 위치 | 현재 **로컬** `DontDelay/todos.json`. 서버는 스냅샷만 수신. |
| 캘린더 | [`calender.dart`](../lib/features/calender.dart) 인메모리. 서버 일정 API 없으면 `upcomingEvents`는 빈 배열. |
| 인증 서버 | [`auth_provider.dart`](../lib/features/auth/auth_provider.dart) — `baseUrl`, `/api/auth/login` |
| UI 목업 | [`aicoach.dart`](../lib/features/aicoach.dart) — 버블·카드 컴포넌트 재사용 |
| Todo 패턴 | [`todo_provider.dart`](../lib/features/todo/todo_provider.dart) — Notifier·Service 분리 참고 |
| URL 로컬 API | [`PLAN_BROWSER_EXTENSION.md`](PLAN_BROWSER_EXTENSION.md) — AI 코치와 **별도** (원격 Spring만 사용) |
| 프로젝트 구조 | [`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md) |

---

## 13. 환경 변수 체크리스트 (운영)

```text
# Spring (예시)
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-4o-mini
AI_COACH_ENABLED=true
AI_RATE_LIMIT_PER_MINUTE=10
```

---

## 14. 변경 이력

| 일자 | 내용 |
|------|------|
| 2026-05-28 | 초안 작성 (백엔드 연동 AI 코치) |
