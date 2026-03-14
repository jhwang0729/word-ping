# Claude Code 기능 가이드 & Word Ping 셋업 추천

Claude Code를 효과적으로 활용하기 위한 핵심 기능 설명과, Word Ping 프로젝트에 맞는 단계별 셋업 추천.

---

## Part 1: Claude Code 핵심 기능

### 1. CLAUDE.md (프로젝트 메모리)

- **무엇:** Claude가 매 세션 시작 시 자동으로 읽는 마크다운 파일
- **역할:** 프로젝트의 기술 스택, 코딩 컨벤션, 디렉토리 구조, 빌드/테스트 명령어 등을 기록해두면 매번 설명할 필요 없이 Claude가 알아서 맥락을 파악

**위치 계층 (우선순위순):**

| 위치 | 용도 | Git 공유 |
|------|------|----------|
| `~/.claude/CLAUDE.md` | 개인 전역 설정 (모든 프로젝트) | X |
| `./CLAUDE.md` 또는 `./.claude/CLAUDE.md` | 프로젝트 설정 | O |
| `./CLAUDE.local.md` | 개인 프로젝트 설정 | X |

**베스트 프랙티스:**

- 200줄 이하로 유지 (너무 길면 효과 떨어짐)
- 구체적으로 작성 ("코드 깔끔하게" X -> "들여쓰기 2칸, 세미콜론 사용" O)
- `@path/to/file` 구문으로 다른 파일 참조 가능

**추가 규칙 파일:** `.claude/rules/*.md`에 주제별 규칙 파일을 분리 가능 (예: `api-design.md`, `testing.md`)

---

### 2. Plan Mode (계획 모드)

- **무엇:** 코드를 수정하지 않고 읽기만 하면서 구현 계획을 세우는 모드
- **역할:** 복잡한 기능을 구현하기 전에 코드베이스를 분석하고, 어떤 파일을 어떻게 수정할지 계획을 먼저 세움

**사용법:**

- `Shift+Tab` -- 모드 전환 (Normal -> Auto-Accept -> Plan -> Normal)
- `claude --permission-mode plan` -- 세션을 plan 모드로 시작

**언제 쓰면 좋은지:**

- 새로운 기능 구현 전 설계할 때
- 여러 파일에 걸친 리팩토링 전
- 코드베이스 탐색하면서 이해할 때

---

### 3. Subagents (서브 에이전트)

- **무엇:** 메인 대화와 별도로 특정 작업을 수행하는 하위 AI 에이전트

**빌트인 타입:**

| 타입 | 역할 | 권한 |
|------|------|------|
| `Explore` | 코드베이스 탐색 전문 | 읽기 전용 |
| `Plan` | 구현 계획 수립 | 읽기 전용 |
| `general-purpose` | 범용 | 읽기 + 쓰기 |

**커스텀 에이전트 정의:** `.claude/agents/<이름>/<이름>.md`

```yaml
---
name: code-reviewer
description: 코드 리뷰 전문가
tools: Read, Grep, Glob
model: sonnet
---
너는 코드 리뷰어야. 버그, 성능 이슈, 보안 취약점을 찾아줘.
```

**주요 설정 옵션:**

- `tools` / `disallowedTools` -- 사용 가능한 도구 제한
- `model` -- `sonnet`, `opus`, `haiku` 중 선택
- `permissionMode` -- 권한 수준 설정
- `isolation: worktree` -- 독립된 git worktree에서 실행

**언제 쓰면 좋은지:**

- 코드 리뷰를 별도 에이전트에게 맡길 때
- 메인 대화 컨텍스트를 보존하면서 부수 작업할 때
- 테스트 작성, 문서 생성 등 패턴화된 작업

---

### 4. Skills (스킬 / 커스텀 슬래시 명령어)

- **무엇:** `/명령어`로 실행하는 재사용 가능한 워크플로우
- **위치:** `.claude/skills/<이름>/SKILL.md`

**예시:**

```yaml
---
name: component
description: 새 UI 컴포넌트를 생성합니다
argument-hint: <component-name>
---
$ARGUMENTS 이름으로 새 컴포넌트를 생성해줘:
1. 컴포넌트 파일 생성
2. 스타일 파일 생성
3. 테스트 파일 생성
```

**빌트인 스킬:**

- `/simplify` -- 변경된 코드의 품질/효율성 리뷰
- `/code-review` -- PR 코드 리뷰

**주요 옵션:**

- `disable-model-invocation: true` -- 수동 실행만 가능 (자동 호출 방지)
- `context: fork` -- 별도 서브에이전트에서 실행
- `$ARGUMENTS`, `$0`, `$1` -- 명령어 인자 참조

**언제 쓰면 좋은지:**

- 새 컴포넌트/화면 생성 같은 반복 작업
- 배포, 빌드 같은 수동 워크플로우
- 팀 전체가 공유하는 표준 프로세스

---

### 5. Hooks (자동화 훅)

- **무엇:** Claude Code의 특정 이벤트에 자동으로 실행되는 스크립트

**주요 이벤트:**

| 이벤트 | 시점 | 용도 |
|--------|------|------|
| `PreToolUse` | 도구 실행 전 | 차단, 검증 |
| `PostToolUse` | 도구 실행 후 | 포맷팅, 린트 |
| `UserPromptSubmit` | 프롬프트 제출 시 | 로깅, 전처리 |
| `SessionStart` | 세션 시작 시 | 환경 초기화 |
| `Notification` | 알림 발생 시 | 외부 알림 |

**핸들러 타입:**

- `command` -- 셸 명령어 실행 (가장 일반적)
- `prompt` -- Claude 모델에 yes/no 판단 요청
- `agent` -- 서브에이전트로 검증

**설정 방법:** `/hooks` 명령어로 인터랙티브 설정, 또는 `.claude/settings.json` 직접 편집

**언제 쓰면 좋은지:**

- 파일 수정 후 자동 포맷팅 (Prettier, ESLint)
- 특정 파일 수정 차단 (설정 파일 보호)
- 프롬프트 로깅

---

### 6. MCP Servers (외부 도구 연동)

- **무엇:** Model Context Protocol 서버. Claude에게 외부 도구, DB, API 접근 권한을 부여

**설정 방법:**

```bash
# HTTP 서버 추가
claude mcp add --transport http github https://api.githubcopilot.com/mcp/

# 목록 확인
claude mcp list
```

**설정 파일 위치:**

| 파일 | 용도 | Git 공유 |
|------|------|----------|
| `~/.claude.json` | 개인 설정 | X |
| `./.mcp.json` | 프로젝트 공유 설정 | O |

**언제 쓰면 좋은지:**

- GitHub PR/이슈 관리
- 라이브러리 최신 문서 조회 (context7)
- DB 쿼리, Slack 연동 등 외부 서비스 접근

---

### 7. Worktrees (Git 워크트리 격리)

- **무엇:** Git worktree를 이용해 별도 작업 디렉토리에서 Claude를 실행
- **사용법:** `claude --worktree feature-name`
- **특징:** 파일 충돌 없이 여러 기능을 병렬로 개발 가능

**언제 쓰면 좋은지:**

- 여러 기능을 동시에 개발할 때
- 실험적 변경을 메인 브랜치에 영향 없이 시도할 때

---

### 8. Task Management (작업 관리)

- **무엇:** 멀티스텝 작업의 진행 상황을 추적하는 내장 기능
- **사용법:** `Ctrl+T`로 작업 목록 토글
- **언제 쓰면 좋은지:** 복잡한 기능 구현 시 단계별 추적

---

## Part 2: Word Ping 프로젝트 추천 셋업

### 즉시 셋업 (프로젝트 시작 전)

1. **CLAUDE.md** -- 프로젝트 개요, 기술 스택, 코딩 규칙
2. **.claude/ 디렉토리 구조** -- settings, skills, agents, rules 폴더

### 개발 시작 후 셋업

3. **Skills** -- `/component`, `/screen` 등 반복 작업 자동화
4. **Subagents** -- `code-reviewer` 등 품질 관리

### 안정기 셋업

5. **Hooks** -- 자동 포맷팅, 린트
6. **추가 MCP** -- 필요에 따라

### 불필요 (현 단계)

- **Agent Teams** -- 실험적 기능, 1인 개발에 과함
- **Worktrees** -- 초기 단계에서는 불필요
