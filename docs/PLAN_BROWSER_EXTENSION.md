# URL 보관함 — 브라우저 확장 + 로컬 API 연동 계획서

## 1. 목표

- **URL 보관함**(`keepurl`)에서 더미 데이터를 제거하고, 실제 URL 저장·조회·필터 기능을 구현한다.
- **Chrome / Edge 브라우저 확장 프로그램**으로 현재 탭 URL을 DontDelay 앱에 저장한다.
- 확장은 **툴바 버튼**, **우클릭 컨텍스트 메뉴**, **단축키**를 통해 URL을 전송한다.
- DontDelay(Flutter 데스크탑)는 **로컬 HTTP 서버**를 띄워 확장의 요청을 받고, 기존 Todo와 동일한 방식으로 JSON 파일에 영속화한다.

---

## 2. 범위 및 비범위

| 포함 | 제외(이번 단계) |
|------|-----------------|
| 앱 내 URL CRUD (수동 추가·삭제·검색·카테고리 필터) | Chrome Web Store 정식 배포 |
| 로컬 HTTP API (`127.0.0.1`) | Native Messaging 자동 페어링 |
| Chrome / Edge MV3 확장 (개발자 모드 로드) | Firefox 확장 (2차) |
| 토큰 기반 인증 + `connection.json` | 브라우저 “링크 주소 복사” 메뉴 가로채기 |
| 확장 ↔ 앱 연결 테스트 UI | AI 자동 분류 실연동 (UI 배너만 유지, 2차) |
| 중복 URL 처리 | 모바일 Share Intent |

---

## 3. 전체 아키텍처

```text
┌─────────────────────────────────────────────────────────────┐
│  Chrome / Edge (Manifest V3)                                │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ 툴바 버튼 │  │ 우클릭 메뉴   │  │ Alt+Shift+S  │         │
│  └────┬─────┘  └──────┬───────┘  └──────┬───────┘         │
│       └────────────────┼─────────────────┘                  │
│                        ▼                                    │
│              background.js (Service Worker)                   │
│                        │                                    │
└────────────────────────┼────────────────────────────────────┘
                         │ POST /api/urls
                         │ Authorization: Bearer {token}
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  DontDelay (Flutter Desktop)                                │
│  ┌──────────────────┐    ┌─────────────────┐               │
│  │ url_api_server   │───▶│ url_service     │               │
│  │ 127.0.0.1:{port} │    │ urls.json       │               │
│  └──────────────────┘    └────────┬────────┘               │
│                                     ▼                        │
│                          url_provider (Riverpod)             │
│                                     ▼                        │
│                          keepurl.dart (UI)                   │
└─────────────────────────────────────────────────────────────┘
```

**동작 요약**

1. DontDelay 실행 시 로컬 HTTP 서버 기동.
2. 확장이 현재 탭의 `url`, `title`을 POST.
3. 앱이 `urls.json`에 저장하고 UI를 갱신.
4. (선택) Windows 토스트 / 스낵바로 저장 완료 피드백.

---

## 4. 데이터 모델

### 4.1 `UrlItem` 필드

`lib/features/keepurl/url_model.dart` (신규)에 정의한다. Todo의 `TodoItem` 패턴을 따른다.

| 필드 | 타입 | 의미 |
|------|------|------|
| `id` | `String` | UUID v4 |
| `url` | `String` | 저장 URL (정규화: trim, trailing slash 정책 확정) |
| `title` | `String` | 페이지 제목 (확장 또는 수동 입력) |
| `category` | `String` | 카테고리 (기본: `미분류`, UI 칩: 전체/개발/전공/학습법/자기계발) |
| `tags` | `List<String>` | 태그 목록 |
| `watchLater` | `bool` | 나중에 보기 |
| `source` | `String` | `extension` \| `manual` |
| `savedAt` | `DateTime` | 저장 시각 (ISO 8601) |
| `iconType` | `String` | `youtube` \| `web` \| `document` (URL 패턴으로 추론) |

### 4.2 JSON (`urls.json`)

- 저장 경로: 앱 문서 폴더 하위 `DontDelay/urls.json`
- Windows 예: `%USERPROFILE%\Documents\DontDelay\urls.json`
- 루트는 `List<Map>` 배열 (Todo의 `todos.json`과 동일 구조).
- `toJson` / `fromJson` + 형식 오류 시 `UrlStorageException` (Todo와 동일 정책).

### 4.3 연결 정보 (`connection.json`)

| 필드 | 타입 | 의미 |
|------|------|------|
| `port` | `int` | 로컬 서버 포트 (기본 `17823`) |
| `token` | `String` | Bearer 인증 토큰 (앱 최초 실행 시 생성, UUID) |

- 저장 경로: `DontDelay/connection.json`
- 앱 시작 시 없으면 생성; 있으면 재사용.

---

## 5. 로컬 HTTP API

### 5.1 엔드포인트

| 메서드 | 경로 | 설명 |
|--------|------|------|
| `GET` | `/api/health` | 앱 실행·버전 확인 (인증 불필요) |
| `POST` | `/api/urls` | URL 저장 (Bearer 필수) |

### 5.2 `GET /api/health`

**응답 200**

```json
{
  "app": "DontDelay",
  "version": "1.0.0",
  "port": 17823
}
```

### 5.3 `POST /api/urls`

**요청 헤더**

```text
Authorization: Bearer {token}
Content-Type: application/json
```

**요청 본문**

```json
{
  "url": "https://example.com/page",
  "title": "페이지 제목",
  "source": "extension"
}
```

**응답**

| 코드 | 본문 | 의미 |
|------|------|------|
| `201` | `{ "id": "...", "message": "saved" }` | 저장 성공 |
| `400` | `{ "message": "invalid url" }` | URL 형식 오류 |
| `401` | `{ "message": "unauthorized" }` | 토큰 불일치 |
| `409` | `{ "message": "duplicate" }` | 동일 URL 이미 존재 |
| `500` | `{ "message": "..." }` | 서버 내부 오류 |

### 5.4 보안

- **bind 주소:** `127.0.0.1`만 허용 (외부 IP 바인딩 금지).
- **인증:** `POST /api/urls`는 Bearer 토큰 필수.
- **CORS:** 확장 `Origin` 또는 `localhost`만 허용 (shelf 미들웨어).
- **입력 검증:** URL은 `Uri.tryParse` + `http`/`https` 스킴만 허용.

### 5.5 구현 패키지

| 패키지 | 용도 |
|--------|------|
| `shelf` | HTTP 서버 |
| `shelf_router` | 라우팅 (선택) |

---

## 6. Flutter 앱 구현

### 6.1 디렉터리 구조 (목표)

```text
lib/features/keepurl/
├── keepurl.dart           # UI (기존 파일 이동·리팩터)
├── url_model.dart         # UrlItem, iconType 추론
├── url_service.dart       # urls.json CRUD
├── url_provider.dart      # Riverpod AsyncNotifier
└── url_api_server.dart    # shelf 로컬 서버
```

### 6.2 `url_service.dart`

- Todo의 `TodoService`와 동일 패턴.
- `loadUrls()`, `saveUrls()`, `addUrl()`, `deleteUrl()`, `updateUrl()`.
- 중복 URL 정책: **409 반환** (확장에서 “이미 저장됨” 표시).

### 6.3 `url_provider.dart`

- `urlListProvider`: `AsyncNotifierProvider<UrlListNotifier, List<UrlItem>>`.
- `addUrl`, `deleteUrl`, `updateUrl`, `toggleWatchLater` 등.
- API 서버에서 POST 성공 시 동일 Notifier 경유 저장 → UI 자동 갱신.

### 6.4 `url_api_server.dart`

- 앱 `main()` 또는 Provider 초기화 시 `start()` / 앱 종료 시 `stop()`.
- `connection.json` 읽기/쓰기.
- POST 처리 시 `UrlListNotifier` 또는 `UrlService` 직접 호출.

### 6.5 `keepurl.dart` UI

| 영역 | 변경 |
|------|------|
| 더미 `_urlList` | 제거 → `urlListProvider` 연동 |
| URL 추가 버튼 | 다이얼로그 (URL, 제목, 카테고리, 태그, 나중에 보기) |
| 검색 | 제목·태그 필터 (클라이언트) |
| 카테고리 칩 | `category` 필드 필터 |
| AI 분류 배너 | UI 유지, 버튼은 2차 (비활성 또는 “준비 중”) |
| **브라우저 연동 패널** (신규) | 연결 상태, 포트·토큰 표시, 복사, 연결 테스트 |

### 6.6 앱 생명주기

- `main.dart`: `WidgetsFlutterBinding.ensureInitialized()` 이후 API 서버 시작.
- `window_manager` 종료 시 서버 `close()` (가능하면).

---

## 7. 브라우저 확장 프로그램

### 7.1 디렉터리 구조

```text
extension/
├── manifest.json
├── background.js
├── popup/
│   ├── popup.html
│   └── popup.js
├── icons/
│   ├── icon16.png
│   ├── icon48.png
│   └── icon128.png
└── README.md              # 개발자 모드 설치 방법
```

### 7.2 `manifest.json` (MV3 요약)

```json
{
  "manifest_version": 3,
  "name": "DontDelay URL Saver",
  "version": "1.0.0",
  "description": "현재 페이지를 DontDelay URL 보관함에 저장합니다.",
  "permissions": ["activeTab", "contextMenus", "storage", "notifications"],
  "host_permissions": ["http://127.0.0.1:*/*"],
  "background": { "service_worker": "background.js" },
  "action": {
    "default_popup": "popup/popup.html",
    "default_icon": { "16": "icons/icon16.png", "48": "icons/icon48.png" }
  },
  "commands": {
    "save-url": {
      "suggested_key": { "default": "Alt+Shift+S" },
      "description": "DontDelay에 현재 탭 저장"
    }
  }
}
```

### 7.3 `background.js` 역할

1. **컨텍스트 메뉴:** `chrome.contextMenus.create` → “DontDelay에 저장”.
2. **현재 탭 조회:** `chrome.tabs.query({ active: true, currentWindow: true })`.
3. **저장 요청:** `fetch` → `POST http://127.0.0.1:{port}/api/urls`.
4. **단축키:** `chrome.commands.onCommand` → `save-url`.
5. **연결 확인:** `GET /api/health` (popup 또는 저장 전).
6. **피드백:** 성공 시 badge `✓`, 실패 시 `chrome.notifications` 또는 badge `!`.

### 7.4 Popup (`popup.html` / `popup.js`)

- **설정:** 포트, Bearer 토큰 입력 → `chrome.storage.local` 저장.
- **연결 테스트:** health + 샘플 POST 없이 health만.
- **상태 표시:** ● 연결됨 / ○ DontDelay 실행 필요.
- **최근 저장:** (선택) 마지막 3건 URL 미리보기.

### 7.5 페어링 UX (1차: 수동)

1. DontDelay → URL 보관함 → “브라우저 연동” 패널.
2. 포트·토큰 표시 + “복사” 버튼.
3. 확장 popup에 붙여넣기 → 저장.
4. “연결 테스트” 클릭 → 성공 메시지.

> Native Messaging으로 `connection.json` 자동 읽기는 **2차** 옵션.

### 7.6 개발자 설치 (Chrome / Edge)

1. `chrome://extensions` (Edge: `edge://extensions`).
2. **개발자 모드** 켜기.
3. **압축해제된 확장 프로그램을 로드합니다** → `extension/` 폴더 선택.

---

## 8. 구현 Phase

### Phase 0 — 설계 확정 (0.5~1일)

- [ ] `UrlItem` 필드·중복 URL 정책 확정
- [ ] API 스펙·포트(`17823`)·토큰 생성 방식 확정
- [ ] 본 문서 리뷰

### Phase 1 — 앱 CRUD (2~3일)

- [ ] `url_model.dart`, `url_service.dart`, `url_provider.dart`
- [ ] `keepurl.dart` 더미 제거, Riverpod 연동
- [ ] URL 추가/삭제/나중에 보기/검색/카테고리 필터
- [ ] 앱 재시작 후 `urls.json` 유지 확인

**완료 기준:** 확장 없이 앱만으로 URL 관리 가능.

### Phase 2 — 로컬 API 서버 (2~3일)

- [ ] `url_api_server.dart` + `shelf` 의존성
- [ ] `connection.json` 생성·로드
- [ ] `GET /api/health`, `POST /api/urls`
- [ ] `main.dart`에서 서버 시작/종료
- [ ] keepurl “브라우저 연동” 패널 (토큰·포트·복사·테스트)
- [ ] curl / PowerShell로 API 수동 테스트

**완료 기준:**

```powershell
curl -X POST http://127.0.0.1:17823/api/urls `
  -H "Authorization: Bearer YOUR_TOKEN" `
  -H "Content-Type: application/json" `
  -d '{"url":"https://example.com","title":"Test","source":"manual"}'
```

→ `201` + keepurl UI 즉시 반영.

### Phase 3 — 브라우저 확장 (3~5일)

- [ ] `extension/` 스켈레톤 (manifest, background, popup, icons)
- [ ] 툴바 / popup → 저장
- [ ] 우클릭 “DontDelay에 저장”
- [ ] 단축키 `Alt+Shift+S`
- [ ] 앱 미실행·토큰 오류·중복 URL 사용자 메시지
- [ ] Edge에서 동일 확장 로드 확인

**완료 기준:** 브라우저에서 클릭 한 번으로 DontDelay URL 보관함에 항목 추가.

### Phase 4 — UX·부가 기능 (2~4일, 선택)

- [ ] 저장 시 `dio`로 제목/OG 메타 보강 (제목 비어 있을 때)
- [ ] Windows 토스트 알림 (백그라운드 저장)
- [ ] AI 자동 분류 (`aicoach` 연동)
- [ ] Firefox MV3 포팅
- [ ] Chrome Web Store 배포 준비

---

## 9. 일정 요약

| Phase | 기간(1인 기준) | 산출물 |
|-------|----------------|--------|
| 0 설계 | 0.5~1일 | API·모델 확정 |
| 1 CRUD | 2~3일 | `urls.json` + keepurl UI |
| 2 API | 2~3일 | 로컬 서버 + 연동 패널 |
| 3 확장 | 3~5일 | Chrome/Edge MV3 |
| 4 polish | 2~4일 | 알림, AI, 배포 |
| **합계** | **약 2~3주** | |

**권장 순서:** Phase 1 → Phase 2 → curl 테스트 → Phase 3 (서버 없이 확장부터 만들지 않음).

---

## 10. 테스트·확인 사항

### 앱

- [ ] 빈 목록·대량 URL·특수문자 URL 저장
- [ ] 앱 재시작 후 목록·연결 정보 유지
- [ ] 잘못된 토큰 → 401
- [ ] 중복 URL → 409
- [ ] 서버 포트 충돌 시 처리 (에러 로그 + UI 안내)

### 확장

- [ ] DontDelay 종료 시 “앱을 실행해 주세요” 안내
- [ ] `http`/`https` 외 스킴 거부
- [ ] 여러 탭 연속 저장
- [ ] 토큰 변경 후 재페어링

### 통합

- [ ] 확장 저장 → keepurl 그리드 즉시 갱신 (Riverpod)
- [ ] 수동 추가와 확장 추가 항목 구분 (`source` 필드)

---

## 11. 제약 및 참고

| 항목 | 설명 |
|------|------|
| 앱 실행 필수 | 로컬 서버가 DontDelay 프로세스 안에서 동작 |
| 우클릭 가로채기 불가 | 브라우저 기본 “링크 주소 복사” 대체 불가 → **새 메뉴 항목** 추가 |
| Web Store | 팀 내부는 개발자 모드 로드로 충분; 공개 배포는 별도 심사 |
| Todo 패턴 재사용 | [`todo_service.dart`](../lib/features/todo/todo_service.dart), [`todo_provider.dart`](../lib/features/todo/todo_provider.dart) 구조 참고 |
| 프로젝트 구조 | [`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md) |

---

## 12. 변경 이력

| 일자 | 내용 |
|------|------|
| 2026-05-28 | Phase 1~3 구현 (앱 CRUD, 로컬 API, Chrome 확장) |
