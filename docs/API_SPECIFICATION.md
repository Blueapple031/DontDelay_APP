# API 명세 (요약)

전체 연동 가이드: [`FRONTEND_INTEGRATION_GUIDE.md`](FRONTEND_INTEGRATION_GUIDE.md)

Base URL: `http://dontdelay.duckdns.org:8080` (로컬: `http://localhost:8080`)

인증: Spring Security **세션 쿠키** (`JSESSIONID`). JWT 없음.

## Health

`GET /api/health` — 인증 불필요

```json
{ "status": "UP", "timestamp": "2026-06-06T20:00:00" }
```

## POST /api/auth/signup

인증 불필요.

```json
{
  "username": "testuser",
  "password": "mypassword123",
  "realName": "홍길동",
  "email": "hong@example.com",
  "department": "컴퓨터공학과"
}
```

- `200`: `{ "message": "회원가입 성공" }`
- `400`: 사용자명/이메일 중복 등

## POST /api/auth/login

인증 불필요.

```json
{ "username": "testuser", "password": "mypassword123" }
```

- `200`: 프로필 + `Set-Cookie: JSESSIONID`
- `401`: `{ "error": "INVALID_CREDENTIALS", "message": "..." }`

## GET /api/auth/me

세션 쿠키 필요.

```json
{
  "username": "testuser",
  "realName": "홍길동",
  "email": "hong@example.com",
  "department": "컴퓨터공학과",
  "major": "컴퓨터공학과"
}
```

- `401`: `{ "error": "UNAUTHORIZED", "message": "로그인이 필요합니다." }`

## 트러블슈팅

| 증상 | 확인 |
|------|------|
| 로그인 401 + `로그인이 필요합니다` | `/api/auth/**` permitAll 설정 |
| 로그인 401 + `INVALID_CREDENTIALS` | 아이디·비밀번호 확인 |
| 연결 불가 | `GET /api/health` → `status: UP` |
| 로그인 후 /me 401 | `PersistCookieJar` + 동일 CookieJar 사용 |
