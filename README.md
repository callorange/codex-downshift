# codex-downshift

> **Keep the parent model in control, downshift bounded execution to Luna & Terra.**

`codex-downshift`는 OpenAI Codex에서 **Sol** 또는 **Terra**를 주력(부모) 모델로 사용할 때, Gate A Safety → Gate B Decision Authority → Economic Gate를 통과한 실행 작업만을 **Luna** (`gpt-5.6-luna`) 또는 **Terra** (`gpt-5.6-terra`) 서브에이전트로 다운시프트(하향 위임)하여 Codex 사용량과 반복 비용을 절감하는 경량 Agent Skill입니다.

---

## 💡 왜 Router가 아니라 "Downshift(Delegator)"인가?

본 프로젝트는 모델 간에 사용자를 임의로 스위칭하거나 복잡한 라우팅 규칙을 적용하는 일반적인 Model Router가 아닙니다.

1. **Parent Authority (부모 모델의 판단권 유지)**: 요구사항 해석, 아키텍처 설계, Public API, 보안, 비즈니스 결정 등 고난도 추론은 사용자가 선택한 Active Parent(Sol/Terra)가 끝까지 책임지며, Parent 역할 자체는 Child에게 위임되지 않습니다.
2. **단방향 하향 위임 (Downshift Only)**: 상위 부모 모델의 판단이 끝난 실행 작업만 하위 모델(`Sol ➔ Terra/Luna`, `Terra ➔ Luna`)로 내려보냅니다.
3. **Leaf Worker / No Chaining**: 모든 자식 워커는 Leaf Worker로 동작하며 다른 에이전트 생성이나 다단계 체이닝(`Sol ➔ Terra ➔ Luna`)이 엄격히 금지됩니다.
4. **Safety Before Routing (Gate A → Gate B → Economic Gate)**: Bounded, Verifiable, Limited Consequence(저위험/가역적)를 먼저 확인하고, 남은 권한에 맞는 후보를 고른 뒤 준비·검증보다 leverage가 클 때만 위임합니다. DB migration이나 보안 등 High Consequence 작업은 구현이 닫혀 있어도 **부모 모델이 직접 수행**합니다.
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

## 🧭 결정적 라우팅 파이프라인 (Gate A → Gate B → Economic Gate)

```text
Active Parent (Sol or Terra)
  │
  ├─ 1. 상위 판단 미결 (Semantic / Architecture / Security)?
  │    YES ──────────────────────────────────────────→ Parent Direct (상위 추론/판단 직접 수행)
  │    NO (상위 판단 완료)
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
│ ├─ Implementation-local 분석/선택 남음                    │
│ │  ──────────────────────────→ Terra Medium Child (5.35×)│
│ ├─ Implementation 닫힘 + 경량 위치 탐색 필요              │
│ │  ──────────────────────────→ Luna Medium Child (2.61×) │
│ └─ Implementation까지 닫힌 기계적 조립/테스트              │
│    ──────────────────────────→ Luna Low Child (1.00×)    │
│                                                          │
│ (Active Terra Parent)                                    │
│ ├─ Implementation-local 분석/선택 남음                    │
│ │  ──────────────────────────→ Terra Parent Direct       │
│ ├─ Implementation 닫힘 + 경량 위치 탐색 필요              │
│ │  ──────────────────────────→ Luna Medium Child (2.61×) │
│ └─ Implementation까지 닫힌 기계적 조립/테스트              │
│    ──────────────────────────→ Luna Low Child (1.00×)    │
└──────────────────────────────────────────────────────────┘
                             │ candidate selected
                             ▼
┌──────────────────────────────────────────────────────────┐
│ Economic Gate: Delegation Preparation Test                │
│ all four conditions true → selected Child; else Parent Direct│
└──────────────────────────────────────────────────────────┘
```

### 🚀 Routing signals and Economic Gate
LOC·파일 수는 약한 secondary signal일 뿐이며 Parent Direct 또는 delegation을 독립적으로 결정하지 않습니다. trivial literal/mechanical edit, fixed-rule bounded execution, bounded search, 예상 test/fix loop, implementation-local decision, high-consequence/irreversible work 같은 관찰 가능한 작업 속성이 라우팅을 이끕니다. Gate A와 Gate B 후 Economic Gate에서 Delegation Preparation Test 네 조건을 모두 확인합니다.

Luna Low는 구현과 target locations가 닫힌 기계적 실행, Luna Medium은 구현이 닫히고 parent-fixed Match Rule 및 bounded Search가 필요한 작업입니다. `all matches`는 Search 경계 전체를 검사하며 non-exhaustive examples를 전체 목록으로 오인하지 않습니다. Terra Medium은 Sol Parent에서 외부 계약은 고정됐지만 implementation-local 선택이 남은 경우에만 후보이고, Terra Parent는 직접 처리합니다. 후보여도 경제성이 비슷하면 Parent Direct입니다.

> [!NOTE]
> Luna 2× 및 Terra 3×는 공식 break-even이나 token formula가 아닌 비공식 잠정 운영 휴리스틱입니다. 상세 계약은 [Task Capsule Template](skills/codex-downshift/references/task-capsule-template.md)과 [Model Economics](skills/codex-downshift/references/model-economics.md)를 참조하세요.

### 🔍 Parent Direct 조건
trivial literal/mechanical edit, high-consequence/irreversible work, 또는 Delegation Preparation Test를 충족하지 못한 작업은 Parent Direct입니다. LOC·파일 수만으로 경로를 결정하지 않습니다.

---

## 🚀 Native Subagent Spawn Contract & 비용 모델

다운시프트 실행 시 부모 모델은 Codex Native Subagent 생성을 통해 모델 상속을 방지하고 독립 컨텍스트로 자식 워커를 실행합니다:

```text
# Sol ➔ Luna 또는 Terra ➔ Luna (기계적 조립/테스트)
spawn_agent(
    model = "gpt-5.6-luna",          # [필수] 부모 모델 상속 방지
    fork_turns = "none",             # [필수] 부모 대화 제외, fresh context
    reasoning_effort = "low",        # [필수] 기본값: low (경량 탐색 시 medium)
    task_name = "<task_name>",
    message = "<Task Capsule>"
)

# Sol ➔ Terra (로컬 구현 위임, Sol Parent 전용)
spawn_agent(
    model = "gpt-5.6-terra",         # [필수] Terra 모델 명시
    fork_turns = "none",             # [필수] 부모 대화 제외, fresh context
    reasoning_effort = "medium",     # [필수] 기본값: medium
    task_name = "<task_name>",
    message = "<Task Capsule>"
)
```

### ⚙️ Estimated Codex Consumption Index 및 비용 모델

#### 1) Codex 공식 크레딧 단가표
| 모델 | Input (1M당) | Cached Input (1M당) | Output / Reasoning (1M당) |
| :--- | ---: | ---: | ---: |
| **Luna** | **5** | **0.5** | **30** |
| **Terra** | **50** (10×) | **5** (10×) | **300** (10×) |
| **Sol** | **100** (20×) | **10** (20×) | **500** (16.7×) |

#### 2) Estimated Codex Consumption Index (예상 실질 소모 지수)
> [!IMPORTANT]
> 아래 값은 OpenAI가 공개한 Plus/Pro Codex allowance 공식 환산식이 아닙니다.
> OpenAI의 공식 token-credit rate와 Codex Radar / CursorBench의 공개 agent 사용량 관측치를 결합하여
> 설정 간 상대적인 비용 효율을 비교하기 위해 만든 **추정 상대 소모 지수(Estimated Consumption Index)**입니다.
> 실제 5시간/주간 allowance 감소율은 context 크기, cache 비율, output, reasoning,
> tool call, agent step, subagent 및 서버 측 metering 정책에 따라 달라질 수 있습니다.

| 모델 \ 추론 | Light (`low`) | Medium (`medium`) | High (`high`) | XHigh | Max |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Luna** | 🟢 **1.00×** (디폴트) | 🟢 **2.61×** (경량 탐색) | 🟢 **6.00×** (자동선택 금지) | 🟡 **8.77×** | 🟠 **18.31×** |
| **Terra** | 🟢 **4.46×** | 🟢 **5.35×** (고지능 워커) | 🟡 **8.39×** | 🟠 **13.99×** | 🔴 **28.85×** |
| **Sol** | 🟡 **9.40×** | 🟠 **18.04×** (부모 기준선) | 🔴 **25.63×** | 🔴 **35.62×** | 🔴 **52.50×** |

#### 3) 부모 기준선별 예상 상대 절감률 비교
| 자식 설정 | 예상 소모 지수 | vs Sol Low (9.40×) | vs Sol Medium (18.04×) | 주요 적용 작업 |
| :--- | :---: | :---: | :---: | :--- |
| **Luna Low** | **1.00×** | **~89.4% lower** | **~94.5% lower** | 확정된 기계적 조립, 단위 테스트, 정형 린트/수정 |
| **Luna Medium** | **2.61×** | **~72.2% lower** | **~85.5% lower** | 구현 닫힘 + 경량 심볼/위치 로컬 탐색 |
| **Terra Medium** | **5.35×** | **~43.1% lower** | **~70.3% lower** | 로컬 알고리즘/클래스 내부 설계 (Sol Parent 전용) |

#### 4) 핵심 운용 규칙
1. **Luna-First 원칙**: 구현 패턴이 닫힌 작업은 예상 소모 지수가 가장 낮은 Luna Low(1.00×) 또는 Luna Medium(2.61×)을 우선 활용합니다. (Luna Medium은 구현 판단 권한을 확장하지 않음).
2. **Luna High vs Terra Medium 및 Sol-Parent Golden Switch**:
   - CursorBench 3.2 관측상 Luna High(Score 56.8% / Steps 40)는 일부 벤치마크 점수가 높지만, 예상 소모 지수가 더 높고(6.00× vs 5.35×) Agent step이 2배(40 vs 20)입니다.
   - 따라서 Sol Parent에서 Implementation-local 분석/선택이 필요한 작업은 Luna High 대신 **Terra Medium(5.35×, 20 steps)**을 선택하는 것이 시간과 예상 소모 효율 측면에서 더 적합합니다.
   - **Terra Parent**는 Downshift Only 원칙에 따라 Terra Child를 부를 수 없으므로 **Terra Direct**로 직접 수행합니다.
3. **프롬프트 캐시 단순 단가 비교 주의점**:
   - 단순 token-rate 계산상 Sol 40k cached context를 읽는 비용은 약 0.4 credits이며, Luna fresh worker 3k uncached input은 약 0.015 credits로 입력부만 비교 시 약 26.7배 차이가 납니다.
   - 단, 실제 작업 전체 비용은 output, reasoning, 추가 도구 호출 및 반복 스텝에 따라 달라지므로 전체 세션 비용으로 일반화하지 않습니다.
   - *(자세한 산출 근거 및 주의사항은 [Model Economics Reference](skills/codex-downshift/references/model-economics.md) 참조)*

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
Scope:
- Search: <검색 대상 경로/심볼; optional>
- Modify: <수정 허용 파일·심볼; optional>
Decisions already made: <부모가 확정한 요구사항, API, 동작 결정>
Delegated authority: <Luna: Predetermined execution / Terra: Implementation-local choice>
Must not decide: <부모 모델 고유의 판단 영역>
Apply: <Exact | All matches within scope | Implementation-local choice>
Rule: <필요한 경우 parent-fixed rule>
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
            ├── model-economics.md
            └── task-capsule-template.md
```

---

## 📖 문서 및 참조 자료

- [Project Specification (기획 명세)](docs/codex-downshift-spec.md)
- [Delegation Examples & Behavioral Scenarios (11대 실전 시나리오)](skills/codex-downshift/references/delegation-examples.md)
- [Model Economics & Estimated Consumption Index (비용 모델)](skills/codex-downshift/references/model-economics.md)
- [Task Capsule & Terminal Return Protocols (프롬프트 서식)](skills/codex-downshift/references/task-capsule-template.md)
- [Changelog (변경 이력)](CHANGELOG.md)
- [Contributing Guide (기여 가이드)](CONTRIBUTING.md)

---

## 🙏 Acknowledgements

Parts of the delegation safety design and execution constraints were inspired by [codex-auto-model-router](https://github.com/orange-the-weak/codex-auto-model-router), particularly its bounded task delegation, task capsule structure, validation budget, and fail-safe execution concepts. `codex-downshift` was independently redesigned and implemented to serve as a lightweight, instruction-only skill focusing strictly on Parent-controlled downshifting with Tiered Downshift and Gate A → Gate B → Economic Gate.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

