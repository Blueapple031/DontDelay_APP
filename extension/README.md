# DontDelay URL Saver — 브라우저 확장

Chrome / Edge에서 현재 페이지 URL을 DontDelay 앱 URL 보관함에 저장합니다.

## 사전 조건

1. **DontDelay 앱**이 실행 중이어야 합니다 (로컬 API 서버가 앱과 함께 기동됩니다).
2. 앱 **URL 보관함 → 브라우저 연동** 패널에서 **포트**와 **토큰**을 확인합니다.

## 설치 (개발자 모드)

### Chrome

1. 주소창에 `chrome://extensions` 입력
2. **개발자 모드** 켜기
3. **압축해제된 확장 프로그램을 로드합니다** 클릭
4. 이 폴더(`extension/`) 선택

### Edge

1. `edge://extensions`
2. **개발자 모드** 켜기
3. **압축을 푼 확장 로드** → `extension/` 폴더 선택

## 사용 방법

1. 확장 아이콘 클릭 → popup에서 **포트·토큰** 입력 (한 번만)
2. **연결 테스트**로 DontDelay 실행 여부 확인
3. 저장 방법 (택 1):
   - popup **현재 탭 저장**
   - 페이지 빈 곳 **우클릭 → DontDelay에 저장 (이 페이지)**
   - 링크 **우클릭 → DontDelay에 저장 (이 링크)**
   - 단축키 **Alt+Shift+S**

> 코드 수정 후 `chrome://extensions`에서 확장 **새로고침** 버튼을 눌러 주세요.

## API

앱이 수신하는 엔드포인트:

- `GET http://127.0.0.1:{port}/api/health`
- `POST http://127.0.0.1:{port}/api/urls` (Authorization: Bearer {token})

## 문제 해결

| 증상 | 해결 |
|------|------|
| 연결 실패 | DontDelay 앱 실행 여부 확인 |
| 401 unauthorized | 앱 브라우저 연동 패널의 토큰과 확장 설정 토큰 일치 확인 |
| 409 duplicate | 이미 저장된 URL |
| 포트 충돌 | `Documents/DontDelay/connection.json`의 port 변경 후 앱 재시작 |

## 관련 문서

- [`docs/PLAN_BROWSER_EXTENSION.md`](../docs/PLAN_BROWSER_EXTENSION.md)
