# 할 일 화면 — 아이젠하워 매트릭스 & 긴급·중요도(0~10) 계획서

## 1. 목표

- 할 일 화면에서 **보기 전환**: 기존 **칸반**(해야 할 일 / 진행 중 / 완료) ↔ **아이젼하워 플롯**.
- 아이젼하워 모드에서 **가로 = 긴급도(0~10)**, **세로 = 중요도(0~10)** 인 2차원 영역에 카드를 배치한다.
- 카드를 **드래그 앤 드롭**해 놓은 위치에 따라 해당 할 일의 `urgency`, `importance` 정수 값이 갱신된다.
- 배경에는 2×2 분면(시각 가이드)·축 라벨(긴급도/중요도)을 유지해 사용자가 익숙한 아이젠하워 틀을 제공한다.

---

## 2. 범위 및 비범위

| 포함 | 제외(이번 단계) |
|------|-----------------|
| `urgency` / `importance` (0~10) 필드 및 JSON 저장 | 실제 AI 자동 분류 |
| 보기 토글(UI) | 매트릭스에서의 “일괄 레이아웃 최적화”(겹침 회피 고급 알고리즘) |
| 드롭 시 좌표 → 0~10 변환·저장 | 웹/모바일(데스크탑만 가정) |

---

## 3. 데이터 모델

### 3.1 필드 추가

`TodoItem`에 다음을 추가한다.

| 필드 | 타입 | 의미 |
|------|------|------|
| `urgency` | `int` | 긴급도, **0~10** (클램프) |
| `importance` | `int` | 중요도, **0~10** (클램프) |

### 3.2 기존 필드와의 관계

- **칸반 `status`(todo / inProgress / done)** 는 유지한다. “진행 단계”는 칸반 전용.
- **기존 `priority`(high / medium / low)** 와의 정책(택 1, 구현 시 확정 권장):

  - **옵션 A (권장):** 매트릭스는 `urgency`·`importance`만 사용. `priority`는 레거시/UI 보조(또는 초기 마이그레이션용)로만 두거나, 장기적으로 Deprecated.
  - **옵션 B:** 새 카드 생성 시 `priority`로 `urgency`·`importance` 초기값을 추정 후, 이후에는 매트릭스가 단일 출처.

### 3.3 JSON (`todos.json`)

- `toJson` / `fromJson`에 `urgency`, `importance` 추가.
- 구버전 파일: 필드 없으면 기본값 **`5` / `5`**(중앙) 또는 `priority` 기반 매핑표로 1회 초기화.

---

## 4. UI — 보기 전환

- 헤더 영역에 **토글**(예: `SegmentedButton` 또는 탭): `칸반` | `아이젼하워`.
- 상태는 `StateProvider` 또는 `TodoScreen`의 `enum TodoViewMode { kanban, eisenhower }` 로 관리.

---

## 5. UI — 아이젼하워 캔버스

### 5.1 좌표계

- **가로축:** 왼쪽 = 긴급도 **0**, 오른쪽 = **10**.
- **세로축:** 아래 = 중요도 **0**, 위 = **10** (“중요도는 위가 높음”).

플롯 **내부** 사각형(패딩 제외 영역)에 대해 정규화:

```text
uNorm = clamp( (releaseX - left) / plotWidth , 0, 1 )
urgency     = round( uNorm * 10 )

iNorm = clamp( (bottom - releaseY) / plotHeight , 0, 1 )
importance = round( iNorm * 10 )
```

- `releaseX`, `releaseY` 는 드롭 시점의 로컬 좌표(또는 글로벌→로컬 변환).
- `round` 결과를 `clamp(0, 10)`으로 한 번 더 보정.

### 5.2 배경(시각 가이드)

- 2×2 분면: 색·한글 라벨·(선택) Do / Decide / Delegate / Delete 스타일은 기획 이미지에 맞춤.
- (선택) 1단위 격자선 또는 눈금으로 0~10 직관 강화.

### 5.3 카드 배치

- 표시 위치(드래그 전 “고정” 위치):

```text
x = left + (urgency / 10) * plotWidth
y = top  + (1 - importance / 10) * plotHeight
```

- 카드 크기와 패딩을 빼서 **중심점** 기준으로 맞출지, **왼쪽 상단** 기준으로 맞출지 구현 시 통일.
- 다수 카드가 같은 점수에 몰리면 **소폭 오프셋**(겹침 완화)은 **2단계**로 미룰 수 있음.

### 5.4 드래그 앤 드롭

- `LongPressDraggable` 또는 `Draggable` + 플롯 위 `DragTarget` 조합.
- **드롭 성공 시:** 위 수식으로 `urgency`·`importance` 계산 → `TodoListNotifier` 경유 저장(기존 JSON 저장 파이프라인 재사용).
- 플롯 **밖**에 드롭: 값 변경 없음 또는 이전 위치로 복귀.

---

## 6. 상태 관리 / 저장

- `TodoListNotifier`에 예: `updateUrgencyImportance(String id, int urgency, int importance)` 추가.
- 내부에서 `0~10` 클램프 후 리스트 갱신 → `TodoService.saveTodos`.
- 저장 실패 시 기존과 동일하게 **롤백 + 스낵바** 정책 유지.

---

## 7. 칸반 화면과의 정합성

- 칸반에서도 동일한 `TodoItem`을 사용. 필요 시 카드에 **소형 뱃지**로 `U:7 I:3` 같이 표시(선택).
- 새 할 일 다이얼로그: **1단계**는 칸반만 유지해도 됨(기본 5/5). **2단계**에서 긴급·중요 슬라이더 또는 “매트릭스에서만 조정”도 가능.

---

## 8. 구현 단계(권장 순서)

1. **모델 + JSON** — `urgency`, `importance`, 마이그레이션, `priority` 정책 확정.
2. **Notifier** — 업데이트 메서드 + 클램프 + 저장.
3. **토글** — `TodoScreen`에서 칸반 / 아이젼하워 분기.
4. **아이젼하워 위젯** — 축·분면 배경·플롯 영역 `LayoutBuilder`로 크기 확보.
5. **카드 위치** — 점수 → `Positioned` (또는 `Transform`).
6. **드래그 → 좌표 → 점수** — 드롭 시 저장 및 리스트 리빌드.
7. **문서** — `PROJECT_STRUCTURE.md`에 새 필드·화면 설명 반영.

---

## 9. 테스트·확인 사항

- 경계: 플롯 모서리 드롭 시 0 또는 10이 정확히 나오는지.
- HDPI / 창 크기 변경 시 `LayoutBuilder`로 플롯 크기 변경 후에도 비율이 유지되는지.
- 빈 목록일 때 플롯만 표시되는지.

---

## 10. 참고

- 현재 할 일 저장 경로: 앱 문서 폴더 하위 `DontDelay/todos.json` (상세는 [`PROJECT_STRUCTURE.md`](PROJECT_STRUCTURE.md)).

---

## 변경 이력

| 일자 | 내용 |
|------|------|
| 2026-05-28 | 초안 작성 |
| 2026-05-27 | 칸반/아이젼하워 토글·`TodoItem` `urgency`/`importance`·드롭 매핑·JSON 반영 구현 |
