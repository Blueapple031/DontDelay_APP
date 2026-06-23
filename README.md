# DontDelay

학습플러스코칭동아리_팀 안미룬이 입니다.

Flutter로 만든 **데스크탑 학습 코치** 앱입니다. (Windows · macOS)

---

## 사전 준비

1. **[Flutter SDK](https://docs.flutter.dev/get-started/install)** 설치  
   - 설치 후 터미널에서 `flutter doctor` 로 환경 점검
2. **데스크탑 지원 켜기**
   ```bash
   flutter config --enable-windows-desktop
   flutter config --enable-macos-desktop
   ```
3. **macOS에서 빌드·실행**하려면 **Xcode**(App Store)와 Xcode Command Line Tools 필요

---

## 프로젝트 받기

Git으로 클론하거나 ZIP으로 내려받은 뒤, 프로젝트 루트(`DontDelay`)로 이동합니다.

```bash
cd DontDelay
flutter pub get
```

---

## Windows에서 실행

### 한 번만: 개발자 모드 (권장)

플러그인 빌드에 **심볼릭 링크**가 필요합니다. 개발자 모드를 켜지 않으면 실행 시 안내가 뜰 수 있습니다.

1. `Win + I` → **시스템** → **개발자용** → **개발자 모드** 켜기  
2. 또는 실행:
   ```powershell
   start ms-settings:developers
   ```

### 개발 모드로 앱 실행

```powershell
flutter run -d windows
```

### 릴리스 빌드(배포용 실행 파일)

```powershell
flutter build windows
```

생성 위치: `build\windows\x64\runner\Release\`  
`dontdelay.exe`만내면 실행되지 않을 수 있습니다. **`Release` 폴더 전체**를 ZIP으로 보내거나, 아래 설치 프로그램을 사용하세요.

### 설치 프로그램 만들기 (Inno Setup)

1. [Inno Setup 6](https://jrsoftware.org/isdl.php) 설치
2. 프로젝트 루트에서:

```powershell
flutter build windows
.\installer\build_setup.ps1
```

> 명령어는 **`windows`** (복수)입니다. `flutter build window` 는 오타입니다.

3. 생성 파일: `installer\output\DontDelay_Setup_1.0.0.exe`  
   이 **setup.exe 하나**만 배포하면 됩니다.

Inno Setup만 설치된 경우: 먼저 `flutter build windows` 실행 후 `installer\dontdelay.iss` 를 **Compile** 하세요.

받는 PC에 **Visual C++ 재배포 패키지**가 없으면 실행 오류가 날 수 있습니다.

---

## macOS에서 실행

### 개발 모드로 앱 실행

```bash
flutter run -d macos
```

### 릴리스 빌드

```bash
flutter build macos
```

생성 위치: `build/macos/Build/Products/Release/`  
앱 번들(`.app`)을 더블 클릭해 실행하거나, 다른 Mac에 복사해 사용할 수 있습니다.  
처음 실행 시 **보안·개인 정보 보호**에서 개발자를 허용해야 할 수 있습니다.

---

## 자주 쓰는 명령

| 목적 | 명령 |
|------|------|
| 연결된 기기·에뮬레이터 확인 | `flutter devices` |
| 분석 | `flutter analyze` |
| 테스트 | `flutter test` |

---

## 참고

- [Flutter 데스크탑 지원](https://docs.flutter.dev/platform-integration/desktop)
- [첫 Flutter 앱 튜토리얼](https://docs.flutter.dev/get-started/codelab)
- [Cookbook](https://docs.flutter.dev/cookbook)
- 프로젝트 폴더 구조: [`docs/PROJECT_STRUCTURE.md`](docs/PROJECT_STRUCTURE.md)
