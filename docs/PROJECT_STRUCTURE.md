# DontDelay 프로젝트 구조 문서

> **안미룬이 - AI Study Coach**
> Flutter 기반 데스크탑 학습 관리 애플리케이션

---

## 전체 디렉토리 트리

```
DontDelay/
├── lib/                          # Dart 소스 코드 (핵심 개발 영역)
│   ├── main.dart                 # 앱 진입점
│   ├── core/                     # 앱 전역 설정
│   │   └── router.dart           # GoRouter 라우팅 설정
│   ├── features/                 # 기능별 화면 모음
│   │   ├── dashboard.dart        # 대시보드 화면
│   │   ├── todo/                 # 할 일 관리 기능
│   │   │   └── todo.dart         # 칸반 보드 화면
│   │   ├── calender.dart         # 캘린더 화면
│   │   ├── keepurl.dart          # URL 보관함 화면
│   │   ├── diary.dart            # 일기 화면
│   │   ├── exammode.dart         # 시험기간 모드 화면
│   │   └── aicoach.dart          # AI 코치 화면
│   └── layout/                   # 레이아웃 컴포넌트
│       └── main_layout.dart      # 사이드바 + 메인 콘텐츠 레이아웃
│
├── windows/                      # Windows 네이티브 빌드 설정
│   ├── CMakeLists.txt            # CMake 빌드 스크립트
│   ├── runner/                   # Windows 실행 파일 관련
│   │   ├── main.cpp              # Windows 앱 진입점 (C++)
│   │   ├── flutter_window.cpp    # Flutter 윈도우 래퍼
│   │   ├── win32_window.cpp      # Win32 윈도우 관리
│   │   ├── utils.cpp             # 유틸리티 함수
│   │   ├── Runner.rc             # 리소스 스크립트 (아이콘, 메타데이터)
│   │   ├── resource.h            # 리소스 상수 정의
│   │   ├── runner.exe.manifest   # Windows 앱 매니페스트
│   │   └── resources/
│   │       └── app_icon.ico      # 앱 아이콘
│   └── flutter/                  # Flutter 엔진 연동 설정
│       ├── CMakeLists.txt        # Flutter 빌드 설정
│       ├── generated_plugins.cmake
│       ├── generated_plugin_registrant.cc
│       ├── generated_plugin_registrant.h
│       └── ephemeral/            # 빌드 시 자동 생성 (수정 금지)
│
├── macos/                        # macOS 네이티브 빌드 설정
│   ├── Runner/                   # Xcode 프로젝트 소스
│   │   ├── AppDelegate.swift     # macOS 앱 델리게이트
│   │   ├── MainFlutterWindow.swift
│   │   ├── Info.plist            # 앱 메타데이터
│   │   ├── Assets.xcassets/      # 앱 아이콘 에셋
│   │   └── Configs/              # 빌드 설정 파일
│   ├── Runner.xcodeproj/         # Xcode 프로젝트 파일
│   ├── Runner.xcworkspace/       # Xcode 워크스페이스
│   ├── Podfile                   # CocoaPods 의존성
│   └── Flutter/                  # Flutter macOS 엔진 설정
│
├── test/                         # 테스트 코드
│   └── widget_test.dart          # 위젯 테스트 (기본 템플릿)
│
├── build/                        # 빌드 출력물 (자동 생성, Git 무시)
│   └── windows/x64/runner/Debug/
│       └── dontdelay.exe         # 빌드된 Windows 실행 파일
│
├── .dart_tool/                   # Dart 도구 캐시 (자동 생성, Git 무시)
├── docs/                         # 프로젝트 문서
│
├── pubspec.yaml                  # 프로젝트 설정 및 의존성 정의
├── pubspec.lock                  # 의존성 버전 잠금 파일
├── analysis_options.yaml         # Dart 정적 분석 규칙
├── .metadata                     # Flutter 프로젝트 메타데이터
├── .gitignore                    # Git 추적 제외 파일 목록
└── README.md                     # 프로젝트 소개
```

---

## 핵심 파일 상세 설명

### `lib/main.dart` — 앱 진입점

앱이 시작되는 파일입니다. 두 가지 핵심 역할을 합니다:

1. **윈도우 설정**: `window_manager` 패키지로 데스크탑 창의 크기, 최소 크기, 위치를 설정
2. **앱 실행**: `MaterialApp.router`로 GoRouter 기반 라우팅을 설정하고, Riverpod 상태 관리를 초기화

| 설정 항목 | 값 |
|----------|-----|
| 초기 창 크기 | 1280 × 800 |
| 최소 창 크기 | 1024 × 768 |
| 테마 색상 | Deep Purple Accent |
| 폰트 | Pretendard (설정만 됨, 폰트 파일 미포함) |

---

### `lib/core/router.dart` — 라우팅 설정

`go_router` 패키지를 사용하여 SPA(Single Page Application) 스타일의 라우팅을 구현합니다.

**구조**: `ShellRoute` 안에 모든 페이지가 중첩되어, 사이드바(`MainLayout`)는 유지된 채 콘텐츠 영역만 바뀝니다.

| 경로 | 화면 | 위젯 |
|------|------|------|
| `/dashboard` | 대시보드 (초기 화면) | `DashboardScreen` |
| `/todo` | 할 일 관리 | `TodoScreen` |
| `/calendar` | 캘린더 | `CalendarScreen` |
| `/keepurl` | URL 보관함 | `UrlScreen` |
| `/diary` | 일기 | `DiaryScreen` |
| `/exam_mode` | 시험기간 모드 | `ExamModeScreen` |
| `/ai_coach` | AI 코치 | `AiCoachScreen` |

---

### `lib/layout/main_layout.dart` — 메인 레이아웃

전체 앱의 뼈대입니다. 좌우 2분할 구조:

```
┌──────────────┬─────────────────────────────┐
│              │                             │
│   사이드바    │      메인 콘텐츠 영역         │
│   (240px)    │      (child 위젯)            │
│              │                             │
│  · 대시보드   │      ← GoRouter가 전달한      │
│  · 할 일     │         현재 화면을 렌더링     │
│  · 캘린더    │                             │
│  · URL 보관함 │                             │
│  · 일기      │                             │
│  · 시험모드   │                             │
│  · AI 코치   │                             │
│              │                             │
└──────────────┴─────────────────────────────┘
```

- 현재 경로(`currentPath`)에 따라 사이드바 메뉴의 활성화 상태가 결정됩니다.
- 테마 컬러: 보라색 계열 (`#6D28D9`, `#F3E8FF`)

---

## 기능별 화면 (`lib/features/`)

### 1. `dashboard.dart` — 대시보드

앱 첫 화면. 좌우 6:4 비율 레이아웃.

- **좌측**: AI 추천 배너, 오늘의 할 일, 오늘 일정
- **우측**: 학습 진행률 (프로그레스 바), 복습 알림, 저장한 콘텐츠

> 현재 모든 데이터는 하드코딩된 더미 데이터입니다.

### 2. `todo/todo.dart` — 할 일 관리 (칸반 보드)

3개 컬럼의 칸반(Kanban) 보드 UI:

| 컬럼 | 설명 |
|------|------|
| 해야 할 일 | 아직 시작하지 않은 태스크 |
| 진행 중 | 현재 작업 중인 태스크 |
| 완료 | 끝난 태스크 |

- 각 카드에 제목, 날짜, 우선순위(높음/보통/낮음), 태그 표시
- 점선 테두리의 "카드 추가" 버튼 (커스텀 `CustomPaintDecoration` 사용)
- AI 자동 분류 버튼 (기능 미구현)

### 3. `calender.dart` — 캘린더

`table_calendar` 패키지 기반 달력 화면. 좌우 7:3 비율.

- **좌측**: 월별 달력 (이벤트 마커 표시)
- **우측**: 다가오는 일정 리스트
- 이벤트 타입: 시험(빨강), 마감(주황), 일정(파랑)

### 4. `keepurl.dart` — URL 보관함

학습 자료 URL을 카테고리별로 보관하는 화면.

- 검색 + 필터 바
- 카테고리 칩: 전체, 개발, 전공, 학습법, 자기계발
- AI 자동 분류 배너
- 2열 그리드 카드 레이아웃

### 5. `diary.dart` — 일기

학습 일기 작성/조회 화면.

- 검색 기능
- 2열 그리드 카드 (이모지, 제목, 내용 미리보기, 태그)

### 6. `exammode.dart` — 시험기간 모드

시험 기간 집중 모드 화면.

- D-Day 카드 (과목별 시험까지 남은 일수)
- 포모도로 타이머 (25분 집중, 시작/일시정지/정지 버튼)
- 오늘의 필수 목표 체크리스트 + 진행률 바
- 방해금지 모드 표시

### 7. `aicoach.dart` — AI 코치

AI 채팅 인터페이스.

- 채팅 버블 UI (사용자: 보라색, AI: 회색)
- AI 응답에 추천 할 일 카드 포함 가능
- 빠른 제안 칩 (예: "오늘 할 일 추천해줘")

---

## 의존성 (`pubspec.yaml`)

| 패키지 | 버전 | 용도 |
|--------|------|------|
| `flutter` | SDK | 프레임워크 |
| `go_router` | ^17.2.3 | 라우팅 (URL 기반 페이지 이동) |
| `flutter_riverpod` | ^3.3.1 | 상태 관리 |
| `table_calendar` | ^3.2.0 | 캘린더 위젯 |
| `window_manager` | ^0.5.1 | 데스크탑 윈도우 크기/위치 제어 |
| `cupertino_icons` | ^1.0.8 | iOS 스타일 아이콘 |
| `flutter_lints` | ^5.0.0 | 코드 품질 린팅 규칙 (dev) |

**Dart SDK 요구 버전**: `^3.9.0`

---

## 빌드 및 실행

### 개발 모드 실행

```bash
flutter run -d windows    # Windows
flutter run -d macos       # macOS
```

### 릴리스 빌드

```bash
flutter build windows      # build/windows/x64/runner/Release/
flutter build macos        # build/macos/
```

### 빌드 출력 위치

| 플랫폼 | Debug 실행 파일 경로 |
|--------|---------------------|
| Windows | `build/windows/x64/runner/Debug/dontdelay.exe` |

---

## 자동 생성 폴더 (수정 금지)

| 폴더/파일 | 설명 |
|-----------|------|
| `.dart_tool/` | Dart 분석기, 패키지 캐시 등 |
| `build/` | 빌드 출력물 (컴파일된 바이너리, 에셋) |
| `windows/flutter/ephemeral/` | Flutter 엔진 바이너리, 플러그인 심볼릭 링크 |
| `macos/Flutter/ephemeral/` | macOS용 Flutter 엔진 설정 |
| `pubspec.lock` | 의존성 정확한 버전 잠금 (자동 생성이지만 Git에 포함) |
| `.metadata` | Flutter 프로젝트 메타데이터 |
| `.flutter-plugins-dependencies` | 플러그인 의존성 그래프 |

---

## 아키텍처 다이어그램

```
┌─────────────────────────────────────────────────┐
│                    main.dart                     │
│          (윈도우 설정 + ProviderScope)             │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│             MaterialApp.router                   │
│               (GoRouter)                         │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│               ShellRoute                         │
│           ┌──────────────┐                       │
│           │  MainLayout  │                       │
│           │  (사이드바)   │                       │
│           └──────┬───────┘                       │
│                  │                               │
│    ┌─────────────┼─────────────┐                 │
│    ▼             ▼             ▼                  │
│ /dashboard   /todo    /calendar  ...             │
│ Dashboard    Todo     Calendar                   │
│ Screen       Screen   Screen                     │
└─────────────────────────────────────────────────┘
```

---

## 현재 개발 상태

| 기능 | UI | 데이터 | 비즈니스 로직 |
|------|:---:|:------:|:------------:|
| 대시보드 | ✅ | 더미 | ❌ |
| 할 일 관리 | ✅ | 더미 | ❌ |
| 캘린더 | ✅ | 더미 | ❌ |
| URL 보관함 | ✅ | 더미 | ❌ |
| 일기 | ✅ | 더미 | ❌ |
| 시험기간 모드 | ✅ | 더미 | ❌ (타이머 토글만) |
| AI 코치 | ✅ | 더미 | ❌ |

> 모든 화면의 UI는 완성되어 있으나, 실제 데이터 저장/불러오기 및 비즈니스 로직은 아직 구현되지 않았습니다.
