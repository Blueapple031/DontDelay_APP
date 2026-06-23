# DontDelay URL Saver — 개인정보처리방침

Chrome 확장 프로그램 **DontDelay URL Saver**에 적용됩니다.  
**DontDelay 전체 개인정보처리방침**은 [PRIVACY.md](../PRIVACY.md)를 참고하세요.

---

## 요약

- 확장 프로그램이 처리하는 URL·제목·메모는 **사용자 PC에서 실행 중인 DontDelay 앱(`127.0.0.1`)으로만** 전달됩니다.
- 연동 토큰·포트 설정은 **Chrome 로컬 저장소**에만 보관됩니다.
- **외부 서버·제3자·광고 네트워크로 데이터를 전송하지 않습니다.**
- 저장된 URL은 데스크톱 앱의 `urls.json`에 **로컬로만** 기록되며 외부 유출 염려가 없습니다.

---

## 수집·이용 정보

| 정보 | 용도 | 저장 위치 |
|------|------|-----------|
| 연동 토큰, 포트 | DontDelay 앱과 연결 | `chrome.storage.local` |
| 저장 요청 시 URL·제목·메모 | URL 보관함에 추가 | localhost → 앱 `urls.json` |
| 마지막 저장 기록 | 팝업 표시용 | `chrome.storage.local` |

---

## 이용자 권리

- 확장 설정에서 토큰·포트 삭제 가능
- 확장 제거 시 로컬 저장 데이터 삭제
- 할 일·일정·회고록 등 **그 외 DontDelay 데이터**는 데스크톱 앱 로컬 파일에만 있으며 [전체 방침](../PRIVACY.md)을 따릅니다.

---

## 문의

[PRIVACY.md](../PRIVACY.md) 10장 문의처를 참고하세요.
