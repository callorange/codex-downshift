# codex-downshift

> **Keep the parent model in control, downshift bounded execution to Luna & Terra.**

`codex-downshift`는 OpenAI Codex에서 **Sol** 또는 **Terra**를 주력(부모) 모델로 사용할 때, 사전에 검증된 2단계 안전 게이트(Gate A Safety ➔ Gate B Decision Authority)에 따라 충분히 결정된 실행 작업만을 **Luna** (`gpt-5.6-luna`) 또는 **Terra** (`gpt-5.6-terra`) 서브에이전트로 다운시프트(하향 위임)하여 Codex 사용량과 반복 비용을 절감하는 경량 Agent Skill입니다.

---

## 💡 왜 Router가 아니라 "Downshift(Delegator)"인가?

본 프로젝트는 모델 간에 사용자를 임의로 스위칭하거나 복잡한 라우팅 규칙을 적용하는 일반적인 Model Router가 아닙니다.

1. **Parent Authority (부모 모델의 판단권 유지)**: 요구사항 해석, 아키텍처 설계, Public API, 보안, 비즈니스 결정 등 고난도 추론은 사용자가 선택한 Active Parent(Sol/Terra)가 끝까지 책임지며, Parent 역할 자체는 Child에게 위임되지 않습니다.
2. **단방향 하향 위임 (Downshift Only)**: 상위 부모 모델의 판단이 끝난 실행 작업만 하위 모델(`Sol ➔ Terra/Luna`, `Terra ➔ Luna`)로 내려보냅니다.
3. **Leaf Worker / No Chaining**: 모든 자식 워커는 Leaf Worker로 동작하며 다른 에이전트 생성이나 다단계 체이닝(`Sol ➔ Terra ➔ Luna`)이 엄격히 금지됩니다.
4. **Safety Before Routing (2단계 게이트)**: Bounded, Verifiable, Limited Consequence(저위험/가역적)를 만족하는 작업만 위임하며, DB migration이나 보안 등 High Consequence 작업은 구현이 닫혀 있어도 **부모 모델이 직접 수행**합니다.
5. **Fail-Closed Fallback**: Child spawn 실패 또는 라우팅 모호 시 타 모델 우회 없이 **부모 모델이 직접 수행**합니다.
6. **Evidence Before Completion**: Parent는 Child의 성공 보고를 맹신하지 않고, 자신의 완료 보고 범위와 일치하는 독립적인 **Minimum Sufficient Fresh Verification을 직접 수행**합니다.

---

## 📊 지원 모델 및 위임 매트릭스

| 부모 모델 (Active Parent) | 위임 대상 (Child) | 대상 작업 (Decision Authority) |
| :--- | :--- | :--- |
| **Sol** | ✅ **`gpt-5.6-luna`** | `Semantic Closed` + `Implementation Closed` (단순 TDD 반복, docstring, 정형 린트/타입 수정 등 기계적 실행) |
| **Sol** | ✅ **`gpt-5.6-terra`** | `Semantic Closed` + `Implementation-Local Decision Remains` (외부 계약 확정, 내부 로컬 알고리즘/구현 선택 위임) |
| **Terra** | ✅ **`gpt-5.6-luna`** | `Implementation Closed` (정형 docstring, 린트/타입 수정, 단순 단위 테스트 등 기계적 실행) |
| **Terra** | 🛑 **Terra Direct** | 구현 판단이 남은 작업은 Downshift Only 원칙에 따라 Terra 부모가 직접 수행 |
| **Luna** | ❌ **비활성화** | 사용자가 Luna를 주 모델로 선택한 경우 상위 모델 자동 호출 없음 (직접 처리) |

> [!NOTE]
> 상향 에스컬레이션(`Luna/Terra ➔ Sol`)이나 동일 티어 재위임(`Terra Parent ➔ Terra Child`, `Sol Parent ➔ Sol Child`)은 절대 발생하지 않습니다.

---

## 🧭 2단계 결정적 라우팅 파이프라인 (Routing Pipeline)

```text
Active Parent (Sol or Terra)
  │
  ├─ 1. 상위 판단 미결 (Semantic / Architecture / Security)?
  │    YES ──────────────────────────────────────────→ Parent Direct (상위 추론/판단 직접 수행)
  │    NO (상위 판단 완료)
  ▼
  ├─ 2. 다운시프트 손익분기점(BEP) 미달 (≤3줄 오타/상수 단발 수정)?
  │    YES ──────────────────────────────────────────→ Parent Direct (오버헤드 방지)
  │    NO (10줄 이상, 테스트 사이클, 다중 파일 등 BEP 충족)
  ▼
┌──────────────────────────────────────────────────────────┐
│ Gate A: Delegation Safety Gate                           │
│ - Bounded: 수정 범위와 영향 표면을 충분히 특정 가능한가?          │
│ - Verifiable: 객관적 Acceptance와 결정적 검증 수단이 있는가?    │
│ - Limited Consequence: 실패 영향이 국소적/가역적인가?         │
│ - No High-Impact: 보안/권한/DB Migration/배포/파괴적 변경 배제│
└────────────────────────────┬─────────────────────────────┘
                             │
            ANY NO (위험/모호) ┴──────────────→ Parent Direct (Fail-Closed)
                             │ ALL PASS
                             ▼
┌──────────────────────────────────────────────────────────┐
│ Gate B: Decision Authority Gate                          │
│                                                          │
│ (Active Sol Parent)                                      │
│ ├─ Semantic 닫힘 + Implementation-local 분석/선택 남음    │
│ │  ─────────────────────────────────────────→ Terra Child│
│ └─ Implementation까지 닫힌 기계적 조립/테스트              │
│    ──────────────────────────→ Luna Child (low [1.00×])  │
│                                                          │
│ (Active Terra Parent)                                    │
│ ├─ Implementation까지 닫힌 기계적 조립/테스트              │
│ │  ──────────────────────────→ Luna Child (low [1.00×])  │
│ └─ 그 외 로컬 구현 작업                                  │
│    ─────────────────────────────────────────→ Terra Direct│
└──────────────────────────────────────────────────────────┘
```

### 🚀 Downshift Mandatory Trigger (손익분기점 기반 즉시 호출)
상위 판단이 완료된 실행 작업 중 다음 3가지 중 하나라도 해당하면 Sol 직접 수정보다 위임이 무조건 이득이 되는 손익분기점(BEP)을 초과하므로 **반드시 하위 워커를 호출**:
1. **테스트/검증 루프**: 단위 테스트를 작성하거나 테스트 명령어를 실행해 결과를 검증해야 하는 작업.
2. **코드 규모**: 10줄 이상(또는 함수/클래스 1개 단위)의 코드 작성/수정.
3. **다중 파일 범위**: 2개 이상의 파일에 걸친 변경 (배치 위임).

### 🔍 Parent Direct 엄격 한정 조건 (오버헤드 방지)
- 단일 파일 내 **3줄 이하** 수정
- 로직/분기문 추가가 없는 단순 오타, 리터럴/상수값 1개 변경, 단순 import 추가
- 수정 후 테스트 루프나 디버깅 없이 1턴에 검증 종료

---

## 🚀 Native Subagent Spawn Contract & 토큰 경제학

다운시프트 실행 시 부모 모델은 Codex Native Subagent 생성을 통해 모델 상속을 방지하고 독립 컨텍스트로 자식 워커를 실행합니다:

```text
# Sol ➔ Luna 또는 Terra ➔ Luna (기계적 조립/테스트)
spawn_agent(
    model = "gpt-5.6-luna",          # [필수] 부모 모델 상속 방지
    fork_turns = "none",             # [필수] 부모 대화 제외, fresh context
    reasoning_effort = "low",        # [필수] Light (1.00× 최적 효율)
    task_name = "<task_name>",
    message = "<Task Capsule>"
)

# Sol ➔ Terra (로컬 구현 위임, Sol Parent 전용)
spawn_agent(
    model = "gpt-5.6-terra",         # [필수] Terra 모델 명시
    fork_turns = "none",             # [필수] 부모 대화 제외, fresh context
    reasoning_effort = "low"|"medium", # [필수] Light(1.84×) ~ Medium(2.46×)
    task_name = "<task_name>",
    message = "<Task Capsule>"
)
```

### ⚙️ GPT-5.6 실측 토큰 비율 및 운용 규칙 (기준: Luna Light = 1.00×)

| 모델 \ 추론 레벨 | Light (`low`) | Medium (`medium`) | High (`high`) | XHigh | Max |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Luna** | **1.00×** (스위트 스팟) | **3.54×** | **10.45×** | **16.60×** | **27.06×** |
| **Terra** | **1.84×** | **2.46×** (고효율) | **4.61×** | **7.99×** | **17.52×** |
| **Sol** | **3.23×** | **6.15×** (일반 부모) | **8.61×** | — | — |

1. **Luna는 `low` (1.00×) 고정**: Medium으로 올리면 토큰이 3.54×로 급증하여 Terra Medium(2.46×)보다 비싸집니다.
2. **로컬 판단은 Terra 라우팅**: 내부 알고리즘 선택이 필요할 때는 Luna Medium(3.54×) 대신 Terra Light(1.84×) 또는 Medium(2.46×)을 사용하여 토큰을 약 30% 절감합니다.
3. **High / Max 자동 선택 절대 금지**: `Luna High (10.45×)`는 `Sol High (8.61×)`보다 비싸 비용 역전이 발생하므로 사전 승인 없이 자동 선택이 차단됩니다.

---

## 💻 설치 (Installation)

### 1. Agent Skills 표준 CLI로 설치 (권장)

```bash
# 글로벌 Codex 스킬로 설치
npx skills@latest add callorange/codex-downshift --skill codex-downshift --agent codex --global

# 또는 현재 프로젝트에 로컬 스킬로 설치
npx skills@latest add callorange/codex-downshift --skill codex-downshift --agent codex
```

### 2. 수동 설치 및 경로 격리 정책

- **글로벌 스킬 설치 (전역 격리)**: `~/.codex/skills/codex-downshift/`
  > 타 에이전트(Claude Code, Antigravity 등)가 전역 `$HOME/.agents/skills/`를 조회하여 Codex 전용 스킬을 오인식하는 문제를 방지하기 위해 Codex 전용 디렉터리에 격리 설치합니다.
- **프로젝트 로컬 설치**: `<project-root>/.agents/skills/codex-downshift/`

---

## 🔄 업데이트 (Updating)

```bash
# 글로벌로 설치된 codex-downshift 업데이트
npx skills@latest update codex-downshift -g -y

# Windows 환경 fallback 재설치
npx skills@latest add callorange/codex-downshift --skill codex-downshift --agent codex --global -y
```

---

## 📋 Task Capsule & 4대 반환 프로토콜

### 1. Task Capsule 핵심 서식
```text
TASK CAPSULE

Role: You are a leaf worker.
Goal: <명확한 단일 작업 목표>
Target / Scope: <허용된 파일 / 심볼 경로>
Decisions already made: <부모가 확정한 요구사항, API, 동작 결정>
Delegated authority: <Luna: Predetermined execution / Terra: Implementation-local choice>
Must not decide: <부모 모델 고유의 판단 영역>
Exact change: <결과 형태가 계약인 경우 필수: final text 또는 고정 변환 규칙>
Preserve: <유지해야 하는 기존 동작/호환성>
Do not touch: <수정 금지 영역>
Acceptance criteria:
- [ ] <유지해야 할 의미·동작 불변조건>
- [ ] <기계적 검증 결과>
Validation:
- <검증 명령 1>
- <검증 명령 2>
Recovery policy: At most ONE recovery attempt when appropriate. If recovery is not appropriate or validation still fails, return TASK_FAILED.
Worker constraints: Leaf worker only. No subagent spawning. No destructive rollbacks.
Return protocol: TASK_COMPLETED, TASK_FAILED, NEEDS_PARENT_DECISION, NEEDS_PARENT_ACTION
```

### 2. 4대 반환 프로토콜
- **`TASK_COMPLETED`**: 다중 Validation 증거와 Acceptance 대조 완료 보고
- **`TASK_FAILED`**: 1회 복구 실패 또는 미시도 후 작업트리를 보존하며 실패 상세 보고
- **`NEEDS_PARENT_DECISION`**: 새 설계 판단/모호성 직면 시 부모에게 제어권 반환
- **`NEEDS_PARENT_ACTION`**: git push, deploy 등 외부 부수효과 필요 시 부모에게 제어권 반환

---

## 📦 프로젝트 구조

```text
codex-downshift/
├── .gitignore
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── AGENTS.md
├── docs/
│   ├── README.md
│   └── codex-downshift-spec.md
└── skills/
    └── codex-downshift/
        ├── SKILL.md
        └── references/
            ├── delegation-examples.md
            └── task-capsule-template.md
```

---

## 📖 문서 및 참조 자료

- [Project Specification (기획 명세)](docs/codex-downshift-spec.md)
- [Delegation Examples & Behavioral Scenarios (11대 실전 시나리오)](skills/codex-downshift/references/delegation-examples.md)
- [Task Capsule & Terminal Return Protocols (프롬프트 서식)](skills/codex-downshift/references/task-capsule-template.md)
- [Changelog (변경 이력)](CHANGELOG.md)
- [Contributing Guide (기여 가이드)](CONTRIBUTING.md)

---

## 🙏 Acknowledgements

Parts of the delegation safety design and execution constraints were inspired by [codex-auto-model-router](https://github.com/orange-the-weak/codex-auto-model-router), particularly its bounded task delegation, task capsule structure, validation budget, and fail-safe execution concepts. `codex-downshift` was independently redesigned and implemented to serve as a lightweight, instruction-only skill focusing strictly on Parent-controlled downshifting with Tiered Downshift and 2-stage safety gates.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

