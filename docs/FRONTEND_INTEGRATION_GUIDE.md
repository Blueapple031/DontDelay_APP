# DontDelay 백엔드 → 프론트(Flutter) 연동 가이드

## 1. 서버 주소

| 환경 | Base URL |
|------|----------|
| **운영** | `http://dontdelay.duckdns.org:8080` |
| **로컬** | `http://localhost:8080` |

- 포트: **8080**
- JSON 필드명: **camelCase** (`documentId`, `realName` 등)
- 날짜: **ISO-8601** (`2026-06-06T12:00:00+09:00`)

로컬 서버 테스트:

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8080
```

---

## 2. 인증 방식 (중요)

| 항목 | 값 |
|------|-----|
| 방식 | **세션 쿠키** (`JSESSIONID`) |
| JWT / Bearer | **없음** |
| 로그인 후 | `Set-Cookie: JSESSIONID=...` 저장 후 **모든 인증 API에 자동 전송** |

### Flutter Dio 설정 (필수)

앱 구현: [`lib/core/api_client.dart`](../lib/core/api_client.dart)

- `dioProvider` — 일반 API (타임아웃 30초)
- `examDioProvider` — PDF 업로드·인덱싱 (타임아웃 120초)
- `PersistCookieJar` + `CookieManager` — **동일 CookieJar 공유**

- `withCredentials` / `CookieManager` 없으면 로그인 후에도 Exam API가 **401**
- CORS: `allowCredentials: true` — 백엔드에서 `dontdelay.duckdns.org`, `localhost` 허용됨

### 인증 필요 여부

| 경로 | 로그인 없이 호출 |
|------|------------------|
| `POST /api/auth/signup` | ✅ |
| `POST /api/auth/login` | ✅ |
| `GET /api/auth/me` | ✅ (세션 없으면 401) |
| `GET /api/health` | ✅ |
| `/api/exam/**` | ❌ **필수** |

---

## 3. Auth API

### 3.1 회원가입

`POST /api/auth/signup` · 인증 불필요

**Request**
```json
{
  "username": "testuser",
  "password": "mypassword123",
  "realName": "홍길동",
  "email": "hong@example.com",
  "department": "컴퓨터공학과"
}
```

| 필드 | 필수 | 설명 |
|------|------|------|
| username | O | 고유 아이디 |
| password | O | |
| realName | O | 실명 |
| email | O | 고유, 이메일 형식 |
| department | O | 학과/전공 |

**Response**

| Status | Body |
|--------|------|
| 200 | `{ "message": "회원가입 성공" }` |
| 400 | `{ "message": "이미 존재하는 사용자명입니다." }` |
| 400 | `{ "message": "이미 등록된 이메일입니다." }` |

---

### 3.2 로그인

`POST /api/auth/login` · 인증 불필요

**Request**
```json
{
  "username": "testuser",
  "password": "mypassword123"
}
```

**Response 200**
```json
{
  "message": "로그인 성공",
  "username": "testuser",
  "realName": "홍길동",
  "email": "hong@example.com",
  "department": "컴퓨터공학과",
  "major": "컴퓨터공학과"
}
```

| 필드 | 설명 |
|------|------|
| major | 전공 (`department`와 동일 값) |

**Response 401 (실패)**
```json
{
  "error": "INVALID_CREDENTIALS",
  "message": "아이디 또는 비밀번호가 올바르지 않습니다."
}
```

→ `Set-Cookie: JSESSIONID=...` 저장

---

### 3.3 현재 사용자

`GET /api/auth/me` · **세션 쿠키 필요**

**Response 200**
```json
{
  "username": "testuser",
  "realName": "홍길동",
  "email": "hong@example.com",
  "department": "컴퓨터공학과",
  "major": "컴퓨터공학과"
}
```

**Response 401**
```json
{
  "error": "UNAUTHORIZED",
  "message": "로그인이 필요합니다."
}
```

### 앱 로그인 플로우

```
1. POST /api/auth/login
2. (선택) GET /api/auth/me 로 세션·프로필 확인
3. 이후 모든 /api/exam/** 요청에 쿠키 자동 포함
4. 401 UNAUTHORIZED → 로그인 화면으로
```

---

## 4. Health API

`GET /api/health` · 인증 불필요

```json
{
  "status": "UP",
  "timestamp": "2026-06-06T20:00:00"
}
```

---

## 5. Exam Generator API (구현 완료)

모두 **세션 인증 필수**. 타 사용자 `documentId` → **404**.

### 5.1 PDF 업로드

`POST /api/exam/documents` · `multipart/form-data`

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| file | file | O | PDF만, 최대 **50MB** |
| title | string | X | 없으면 파일명 |
| subject | string | X | 과목명 |

**Response 201**
```json
{
  "documentId": "550e8400-e29b-41d4-a716-446655440000",
  "title": "3장_행렬식.pdf",
  "subject": "선형대수",
  "status": "UPLOADED",
  "fileSizeBytes": 2048576,
  "createdAt": "2026-05-28T10:00:00+09:00"
}
```

업로드 직후 백그라운드 인덱싱 시작.

**Dio 예시**
```dart
final formData = FormData.fromMap({
  'file': await MultipartFile.fromFile(pdfPath, filename: 'sample.pdf'),
  'subject': '선형대수',
  'title': '3장 PDF',
});
await ref.read(examDioProvider).post('/api/exam/documents', data: formData);
```

---

### 5.2 문서 목록

`GET /api/exam/documents`

| Query | 기본값 | 설명 |
|-------|--------|------|
| status | (없음) | `UPLOADED`, `EXTRACTING`, `INDEXING`, `READY`, `FAILED` |
| page | 0 | |
| size | 20 | |

**Response 200**
```json
{
  "items": [
    {
      "documentId": "uuid",
      "title": "3장_행렬식.pdf",
      "subject": "선형대수",
      "status": "READY",
      "pageCount": 24,
      "chunkCount": 48,
      "createdAt": "...",
      "updatedAt": "..."
    }
  ],
  "total": 1
}
```

---

### 5.3 문서 상세 (폴링용)

`GET /api/exam/documents/{documentId}`

**Response 200**
```json
{
  "documentId": "uuid",
  "title": "3장_행렬식.pdf",
  "subject": "선형대수",
  "status": "INDEXING",
  "progress": 65,
  "pageCount": 24,
  "chunkCount": 31,
  "errorCode": null,
  "errorMessage": null,
  "createdAt": "...",
  "updatedAt": "..."
}
```

### DocumentStatus (문서 처리 상태)

| status | UI 표시 | 설명 |
|--------|---------|------|
| `UPLOADED` | 대기 | 업로드 완료, 추출 대기 |
| `EXTRACTING` | 처리 중 | PDF/OCR 텍스트 추출 |
| `INDEXING` | 처리 중 | chunk + 임베딩 |
| `READY` | 준비됨 | 문제 생성 가능 |
| `FAILED` | 실패 | `errorCode` 참고 |

**실패 시 errorCode 예시** (문서 상세 필드)

| errorCode | 의미 |
|-----------|------|
| `EMPTY_PDF` | 텍스트 없음 |
| `ENCRYPTED_PDF` | 암호 PDF |
| `OCR_FAILED` | OCR 실패 |
| `INDEXING_FAILED` | 기타 인덱싱 오류 |

### 폴링 권장

- `EXTRACTING` / `INDEXING` 중 → **2~3초**마다 `GET /documents/{id}`
- `READY` 또는 `FAILED` → 폴링 중단

---

## 6. 에러 응답 형식

### 공통 (인증)

```json
{
  "error": "UNAUTHORIZED",
  "message": "로그인이 필요합니다."
}
```

### Exam API (`ExamApiException`)

```json
{
  "error": "INVALID_FILE",
  "message": "PDF 확장자(.pdf)만 업로드할 수 있습니다.",
  "details": { }
}
```

| HTTP | error | 앱 처리 |
|------|-------|---------|
| 400 | `INVALID_FILE` | PDF·50MB 검증 스낵바 |
| 401 | `UNAUTHORIZED` | 로그인 화면 |
| 404 | `NOT_FOUND` | 목록 새로고침 |
| 429 | `RATE_LIMITED` | "잠시 후 재시도" (업로드 **시간당 10건**) |
| 503 | `EXAM_DISABLED` | 기능 비활성 안내 |

---

## 7. 아직 미구현 API (연동 예정)

프론트 UI 설계는 가능, **호출은 404** until 백엔드 Phase 3~4.

| Method | Path | 설명 |
|--------|------|------|
| POST | `/api/exam/documents/{id}/search` | RAG 검색 |
| POST | `/api/exam/jobs` | 시험 생성 Job |
| GET | `/api/exam/jobs/{jobId}` | Job 상태·미리보기 |
| GET | `/api/exam/jobs` | Job 히스토리 |
| GET | `/api/exam/exams/{examId}` | 시험 전체 JSON |
| GET | `/api/exam/exams/{examId}/download` | PDF 다운로드 |
| DELETE | `/api/exam/documents/{id}` | 문서 삭제 |
| POST | `/api/exam/documents/{id}/reindex` | 재인덱싱 |

### 예정 Job 상태 (`ExamJobStatus`)

`PENDING` → `GENERATING` → `RENDERING` → `COMPLETED` / `FAILED`

---

## 8. 제한·정책

| 항목 | 값 |
|------|-----|
| PDF 최대 크기 | 50MB |
| 업로드 Rate limit | 사용자당 **시간당 10건** |
| 업로드 타임아웃 | Dio **120초** 권장 |
| 데이터 격리 | 본인 `documentId`만 조회 (타인 → 404) |
| 비밀키 | 앱에 **OpenAI·Upstage·AWS 키 넣지 않음** (전부 서버) |

---

## 9. 화면별 API 매핑 (exam_generator)

| 화면 동작 | API |
|-----------|-----|
| 회원가입 | `POST /api/auth/signup` |
| 로그인 | `POST /api/auth/login` |
| 프로필 표시 | `GET /api/auth/me` 또는 login 응답 재사용 |
| PDF 업로드 | `POST /api/exam/documents` |
| 문서 목록 | `GET /api/exam/documents` |
| 처리 중 진행률 | `GET /api/exam/documents/{id}` 폴링 |
| 문제 생성 (예정) | `POST /api/exam/jobs` |
| 생성 진행 (예정) | `GET /api/exam/jobs/{id}` 폴링 |
| PDF 저장 (예정) | `GET /api/exam/exams/{id}/download` |

---

## 10. curl로 빠른 검증

```bash
# 로그인
curl -c cookies.txt -X POST http://dontdelay.duckdns.org:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"비밀번호"}'

# 프로필
curl -b cookies.txt http://dontdelay.duckdns.org:8080/api/auth/me

# 문서 목록
curl -b cookies.txt http://dontdelay.duckdns.org:8080/api/exam/documents

# 업로드
curl -b cookies.txt -X POST http://dontdelay.duckdns.org:8080/api/exam/documents \
  -F "file=@sample.pdf" -F "subject=테스트"
```

**로그인 200** + 쿠키 저장되면 앱에서도 동일하게 동작합니다.

---

## 11. 체크리스트 (프론트 구현 시)

- [x] Dio + `CookieManager` / `PersistCookieJar` ([`api_client.dart`](../lib/core/api_client.dart))
- [x] 로그인 실패: `INVALID_CREDENTIALS` vs `UNAUTHORIZED` 구분 ([`api_error.dart`](../lib/core/api_error.dart))
- [ ] Exam API 401 → 로그인 화면
- [x] 업로드 `examDio` 타임아웃 120초
- [ ] `DocumentStatus` 뱃지 + 폴링
- [ ] `READY` 전 문제 생성 버튼 비활성 (409 예정)
- [x] `major` / `department` 둘 다 옴 (마이페이지 표시)

---

## 관련 문서

- Auth 요약: [`API_SPECIFICATION.md`](API_SPECIFICATION.md)
- Exam 상세: [`PLAN_EXAM_GENERATOR.md`](PLAN_EXAM_GENERATOR.md) §6
