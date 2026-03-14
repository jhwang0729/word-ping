# Word Ping - App Specification

## 1. Overview

- **App Name**: Word Ping
- **Platform**: Cross-platform (iOS, Android)
- **Description**: 단어 사전 앱. 단어를 저장하고, 저장된 단어에 플래시 카드 기능을 제공하고 퀴즈를 풀 수 있으며, 알람 해제 시 퀴즈를 맞춰야 하는 기능이 핵심.
- **Target Users**: 영어 공부를 하고 싶은 모든 한국인들 혹은 외국인들
- **Tech Stack**:
  - **Framework**: Flutter (Dart)
  - **로컬 DB**: sqflite — 단어장-단어, 알람-단어장 등 관계형 데이터가 있어서 SQL 기반이 적합. Flutter에서 가장 성숙하고 문서가 풍부함
  - **상태 관리**: Riverpod — Flutter의 현재 권장 패턴. Provider의 후속으로, 타입 안전하고 테스트가 쉬움
  - **Dictionary API**: Free Dictionary API (dictionaryapi.dev) — 무료, API 키 불필요, 발음기호/뜻/예문 제공. 구현 전 공식 문서 확인 필요. Wiktionary API도 fallback으로 검토
  - **알람**: android_alarm_manager_plus (Android) + flutter_local_notifications (iOS/Android)

## 2. Core Concepts

> 앱 전반에서 사용되는 도메인 용어. 코드의 클래스명, 변수명에 그대로 사용한다.

| Term | Definition |
|------|------------|
| WordEntry | 하나의 영단어와 그에 속한 발음기호, 뜻(최대 3개), 예문을 묶은 단위. 반드시 하나의 Wordbook에 속함 |
| Meaning | WordEntry에 속한 개별 뜻. 품사(partOfSpeech) + 정의(definition) + 예문(example)으로 구성 |
| Wordbook | 단어를 분류하는 폴더. 사용자가 이름을 지정하여 생성/삭제. 플래시카드와 퀴즈의 단위 |
| Quiz | Wordbook 내 단어를 무작위 선택하여 4지선다로 뜻을 맞추는 기능. 최소 5단어 필요 |
| AlarmQuiz | 알람 해제 시 풀어야 하는 퀴즈. 틀리면 맞춰야 할 단어 수가 1개씩 증가 |

## 3. Features

### 홈
* 앱에 들어왔을때 가장 기본적인 화면이야
* 우선 모든 기능 페이지와 홈에 공통적으로 하단에 nav bar가 있을거야
  * 총 세가지 버튼이 있고
  * 왼쪽 : 단어장
  * 오른쪽 : 알람
  * 가운데 : 돋보기 모양을 하고 있고, 해당버튼을 누르면 홈 페이지로 항상 돌아와
    * 해당 버튼은 동그랗게 되어 있고, 동그라미 안에 돋보기 모양이 있어
* 화면 상단 (검색창이 최상단 보다는 조금 아래에 위치해 있어. 한 1/5?? 정도에 위치해 있어)
  * 유저가 검색할 수 있는 검색창이 있어
  * 검색창 왼쪽에는 돋보기 모양이 있어
  * 창은 왼쪽 오른쪽에 조금씩 margin이 있어
  * 오른쪽 상단에는 설정으로 누를 수 있는 버튼이 있어

### 검색
* 유저는 홈에서 검색을 시작할 수 있어.
  * 검색창은 위에서 설명한 대로 생겼고, 검색의 시작점이야
* 유저는 여기서 정확한 단어를 입력해야 할거고, 입력한 단어를 api를 통해서 단어의 뜻을 불러올거야.
* 우리는 다음과 같은 api를 고려하고 있어
  * FreeDictionaryAPI.com
  * 나중에 구현하기 전에 해당 홈페이지에 들어가서 document를 읽어봐
    * 추가로 Free Dictionary API 혹은 Wiktionary API (공식)도 생각중이니 한 번 찾아는 봐줘
* 유저가 해당 단어를 검색하면 바로 단어의 뜻을 설명하는 상세 페이지가 나올거야.
  * 해당 상세 페이지에서는 다음과 같은 기능을 지원해
    * 왼쪽 상단에 검색한 단어가 있고, 바로 옆에 해당 단어의 발음 기호를 표시할거야
      * 만약 api 답변으로 여러개가 온다면 파싱해서 가장 많이 나온 발음 기호를 사용할거야
    * 오른쪽 상단에는 별표 모양이 있고, 해당 별표 모양을 클릭함으로써 단어장에 저장할 수 있어
      * 이 때, 단어장 섹션을 여러개 설정할 수 있고, 해당 페이지에서 저장하고 싶은 단어의 섹션을 설정하거나 단어의 섹션을 추가로 설정할 수 있어
    * 단어의 바로 밑에는 발음 기호를 바탕으로 미국 영어의 발음을 나타내는 기호를 만들어줘
    * 발음 기호 옆에 스피커 아이콘을 두고, 탭하면 TTS로 해당 단어의 발음을 재생
    * 그 다음에는 단어의 뜻과 예문이 나올거야. 이 때, api의 답변이 여러개가 온다면 해당 리스트를 모두 파싱해서 보여줘. 너무 많다면 5개까지만 사용해줘

### 단어장
* 단어장은 비교적 간단해
* 해당 페이지로 들어가면 단어장의 여러 종류가 나올것이고, 해당 종류별로 오른쪽에 플래시 카드 혹은 퀴즈 tab을 만들거야
  * 이 때, 아무 단어도 저장이 되어 있지 않다면 tab을 비활성화 해줘
* 해당 페이지에서 단어장 종류를 삭제/추가할 수 있어
* tab에서 단어장 종류 이름과 더불어 저장되어 있는 단어 개수를 표시해줘

#### 단어장 삭제 규칙
* 단어장 삭제 시 안에 있는 단어도 함께 삭제
* 해당 단어장에 연결된 알람이 있으면, 확인 팝업을 띄워서:
  * "연결된 알람도 함께 삭제" 또는
  * "단어장 삭제 취소" 중 선택

#### 플래시 카드
* 특정 단어장 종류에 있는 단어들을 섞어서 플래시 카드를 만들어 줘. 이 때, 두 가지 방법이 있고, 해당 방법은 설정에서 설정할 수 있어
  * 단어를 앞면으로 표현하는 경우
    * 뒤집으면 뜻이 나올거야. 근데 해당 단어의 뜻을 두개까지 표현해줘. 예문도 같이 표현해주면 좋을것 같아
  * 뜻을 앞면으로 표현하는 경우
    * 저장된 단어의 첫번째 뜻을 표현해줘

#### 퀴즈
* 단어장 종류별로 퀴즈 버튼을 클릭해서 해당 단어들에 대한 퀴즈를 볼 수 있어
* 퀴즈 활성화 조건: 해당 단어장에 최소 5개 단어 저장 필요
* 퀴즈 개수: 설정에서 5, 10, 15, 20 중 선택 가능
  * 단어 수가 부족하면 선택 가능한 개수도 제한됨 (예: 5개 저장 -> 5개만 선택 가능)
* 해당 단어장 내 단어를 무작위 선택하여 하나씩 보여주고, 4개의 객관식 선택지 제공
* 오답 선택지는 같은 단어장 내 다른 단어의 뜻에서 생성
* 정답: 초록색 UI로 강조 -> 다음 문제
* 오답: 붉은색 UI로 강조 -> 다음 문제
* 마지막 문제 후 결과 화면: 총 맞춘 개수 + 틀린 단어의 뜻과 풀이 표시
* 확인 버튼 -> 단어장 리스트 페이지로 돌아감

### 알람
* 알람 페이지에 진입하면 알람 리스트를 보여줘. CRUD를 모두 할 수 있어
* (+) 버튼을 통해서 신규 알람을 만들 수 있어
* 알람 설정 항목:
  * 알람 이름 (최대 12글자)
  * 알람 시간 및 울리는 요일
  * 알람 사운드 선택
  * 단어 퀴즈 활성화 on/off
  * 퀴즈 활성화 시: 연결할 단어장 선택, 기본 맞춰야 할 단어 수 설정
* 알람 퀴즈 동작:
  * 알람이 울리면 연결된 단어장에서 무작위로 단어 풀이가 나오고 4개 선택지 중 정답을 맞춰야 알람 해제
  * 틀릴 때마다 맞춰야 할 단어 수 +1 증가
* 알람 리스트:
  * 토글로 알람 사용 여부 결정
  * 내일 울리는 알람은 색상 강조
  * 울리는 요일 표시
  * 기존 알람 클릭 -> 수정 페이지 (생성 페이지와 동일 레이아웃)
  * 수정 페이지 하단에 삭제 버튼
* 앱이 꺼져 있어도 알람이 울려야 함 (네이티브 알람 서비스 사용)

### 설정
* 다크 모드 on/off
* 글자 크기 (작게, 보통, 크게)
* 플래시카드 앞면 표시 (단어 / 뜻)
* 기본 퀴즈 개수 (5, 10, 15, 20)
* 앱 정보

## 4. Data Model

> 주요 엔티티와 관계를 정의합니다.

### Wordbook
- `id`: int (PK, auto-increment)
- `name`: String (단어장 이름)
- `createdAt`: DateTime

### WordEntry
- `id`: int (PK, auto-increment)
- `word`: String (영단어, e.g. "apple")
- `phonetic`: String (발음기호, e.g. "/ˈæp.əl/")
- `wordbookId`: int (FK -> Wordbook)
- `createdAt`: DateTime

### Meaning
- `id`: int (PK, auto-increment)
- `wordEntryId`: int (FK -> WordEntry)
- `partOfSpeech`: String (품사, e.g. "noun", "verb")
- `definition`: String (뜻, e.g. "사과")
- `example`: String? (예문, nullable)
- `orderIndex`: int (표시 순서, 0부터 시작. 최대 2 = 3개까지 저장)

### Alarm
- `id`: int (PK, auto-increment)
- `name`: String (알람 이름, 최대 12자)
- `hour`: int (0-23)
- `minute`: int (0-59)
- `repeatDays`: String (반복 요일, e.g. "1,2,3,4,5" = 월~금)
- `soundName`: String (알람 사운드 이름)
- `isEnabled`: bool (알람 활성화 여부)
- `isQuizEnabled`: bool (단어 퀴즈 활성화 여부)
- `wordbookId`: int? (FK -> Wordbook, nullable. 퀴즈 비활성화 시 null)
- `quizWordCount`: int (맞춰야 할 기본 단어 수, default 3)
- `createdAt`: DateTime

### Settings (SharedPreferences로 저장)
- `darkMode`: bool (default: false)
- `fontSize`: String (small / medium / large, default: medium)
- `flashcardFrontDisplay`: String (word / meaning, default: word)
- `defaultQuizCount`: int (5 / 10 / 15 / 20, default: 20)

### 관계도

```
Wordbook (1) ──< (N) WordEntry (1) ──< (N) Meaning
Wordbook (1) ──< (N) Alarm
```

## 5. Screens

> 주요 화면 목록과 각 화면의 역할. UI 레퍼런스는 `ui/` 디렉토리의 HTML 파일 참조.

| Screen | UI 파일 | Description |
|--------|---------|-------------|
| Home | `home.html` | 검색창 + 하단 네비게이션. 앱 진입점 |
| Word Detail | `word.html` | 검색 결과 상세. 단어/발음기호/뜻/예문 표시, 별표로 단어장에 저장 |
| Wordbook List | `wordbook.html` | 단어장 목록. 각 단어장별 단어 수, 플래시카드/퀴즈 버튼 |
| Flashcard | `flashcard.html` | 플래시카드. 탭하여 앞/뒤 뒤집기, 좌우 넘기기 |
| Quiz | `quiz.html` | 4지선다 퀴즈. 문제 번호 표시, 정답/오답 피드백 |
| Quiz Result | `quiz-result.html` | 퀴즈 결과. 점수 + 틀린 단어 복습 목록 |
| Alarm List | `alarm-list.html` | 알람 목록. 토글, 시간, 요일, 연결된 단어장 표시 |
| Alarm Setting | `alarm-setting.html` | 알람 생성/수정. 시간, 요일, 사운드, 퀴즈 설정 |
| Alarm Ring | `alarm-ring.html` | 알람 울림 화면. 빨간 배경, 단어 퀴즈로 해제 |
| Settings | `settings.html` | 앱 설정. 다크모드, 글자크기, 플래시카드/퀴즈 옵션 |

## 6. Constraints & Non-functional Requirements

- **오프라인 지원**: 단어 검색은 인터넷 필요. 그 외 모든 기능(단어장, 플래시카드, 퀴즈, 알람)은 오프라인에서 정상 작동
- **성능**: 단어장당 최대 100개 단어 지원
- **저장 제한**: 단어당 뜻은 최대 3개까지 로컬 저장 (API 응답이 더 많아도 3개로 제한)
- **보안**: 로컬 데이터만 사용. 외부 서버 전송 없음

## 7. Out of Scope (v1)

> 첫 버전에서 제외할 기능을 명시합니다.

- 검색 자동완성 (v2에서 검토)
- 데이터 백업/복원 (클라우드 동기화, JSON 내보내기 등)
- 퀴즈 히스토리/통계 저장
- 다국어 UI 지원 (현재 한국어 고정)
