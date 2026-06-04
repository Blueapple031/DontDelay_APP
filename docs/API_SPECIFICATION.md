# API 명세

Base URL: `http://dontdelay.duckdns.org:8080`

인증은 Spring Security 세션 쿠키를 사용합니다.

## POST /api/auth/signup

회원가입.

### 요청 본문

```json
{
  "username": "testuser",
  "password": "mypassword123",
  "realName": "홍길동",
  "email": "hong@example.com",
  "department": "컴퓨터공학과"
}
```

| 필드 | 설명 |
|------|------|
| `username` | 아이디 (필수) |
| `password` | 비밀번호 (필수) |
| `realName` | 실명 (필수) |
| `email` | 이메일 (필수, 형식 검증, DB 고유값) |
| `department` | 학과 (필수) |

### 응답

- `200`: 가입 성공
- `400`: 필수값·이메일 형식 검증 실패, 사용자명 중복(`이미 존재하는 사용자명입니다.`), 이메일 중복(`이미 등록된 이메일입니다.`)

## POST /api/auth/login

로그인. 성공 시 세션 쿠키 발급.

## GET /api/auth/me

로그인한 사용자 프로필 조회.

### 응답 예시 (200)

```json
{
  "username": "testuser",
  "realName": "홍길동",
  "email": "hong@example.com",
  "department": "컴퓨터공학과"
}
```

- `401`: 미로그인, 또는 세션은 있으나 DB에 사용자가 없는 경우
