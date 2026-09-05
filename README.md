# codex-downshift

> **Keep the parent model in control, downshift bounded execution to Luna & Terra.**

`codex-downshift`는 OpenAI Codex에서 **Sol** 또는 **Terra**를 주력(부모) 모델로 사용할 때, Gate A Safety → Gate B Decision Authority → Economic Gate를 통과한 실행 작업만을 **Luna** (`gpt-5.6-luna`) 또는 **Terra** (`gpt-5.6-terra`) 서브에이전트로 다운시프트(하향 위임)하여 Codex 사용량과 반복 비용을 절감하는 경량 Agent Skill입니다.

---

## 빠른 시작

### 준비 사항

- Sol 또는 Terra를 부모 모델로 사용하는 Codex 환경이 필요합니다.
- 위임 실행에는 모델과 reasoning effort를 지정할 수 있는 Native Subagent 기능이 필요합니다. 부모 모델을 확인할 수 없거나 자식 생성에 실패하면 부모가 직접 처리합니다.
- 아래 CLI 설치에는 Node.js와 `npx`가 필요합니다. 스킬 자체는 Markdown 지침으로 구성되어 별도의 데몬이나 실행 서버를 요구하지 않습니다.

### 설치

전역 또는 프로젝트 설치 중 사용할 범위를 선택합니다.

```bash
# 전역 설치
npx skills@latest add callorange/codex-downshift --skill codex-downshift --agent codex --global

# 현재 프로젝트에 설치
npx skills@latest add callorange/codex-downshift --skill codex-downshift --agent codex
```

명령과 옵션은 [skills CLI 문서](https://github.com/vercel-labs/skills#readme)를 참고하세요. CLI가 출력하는 실제 설치 경로를 확인하세요.

| 설치 방식 | 경로·확인 기준 |
| --- | --- |
| 프로젝트 수동 설치 | `<project-root>/.agents/skills/codex-downshift/` |
| 사용자 수동 설치 | `~/.agents/skills/codex-downshift/` — 공식 Codex 로컬 탐색 경로 |
| skills CLI의 Codex 설치 | CLI 문서는 프로젝트 `.agents/skills/`, 전역 `~/.codex/skills/`로 표기한다. 설치 버전·방식에 따른 실제 경로와 링크 대상은 CLI 출력으로 확인한다. |

수동 설치는 이 저장소의 `skills/codex-downshift/` 폴더 전체를 복사하고 `SKILL.md`와 `references/`를 함께 유지한다.
CLI의 agent 선택이나 경로 이름만으로 다른 에이전트와의 격리를 보장하지 않는다. CLI는 공용 원본을 가리키는 symlink 또는 복사 방식을 사용할 수 있다.
확인일: **2026-09-04**. 근거: [Codex 로컬 스킬 탐색](https://learn.chatgpt.com/docs/build-skills#where-codex-loads-local-skills), [skills CLI 설치 방식·에이전트별 경로](https://github.com/vercel-labs/skills#supported-agents).

### 사용 예시

Codex에 스킬 이름과 함께 작업 범위, 유지할 동작, 검증 기준을 전달합니다. 다음은 요청 예시이며 경로와 명령은 작업 프로젝트에 맞게 바꿉니다.

```text
codex-downshift 스킬을 사용해줘.
src/formatters/에서 기존 문자열 포맷 규칙을 따르도록 반복 구현을 수정해줘.
공개 함수의 인자와 반환값은 유지하고, tests/formatters/의 관련 테스트로 검증해줘.
위임 조건을 충족하는 작업만 하위 모델에 맡겨줘.
```

부모는 요구사항을 정리하고 위임 가능 여부를 판단합니다. 위임하는 경우 Task Capsule 작성과 자식 모델 선택까지 수행하므로 사용자가 spawn 파라미터를 직접 작성할 필요는 없습니다. 준비·검증 비용에 비해 실행량이 작으면 **Parent Direct**로 처리하는 것이 정상입니다.

[위임 기준](#위임-기준) · [비용 비교와 실행 계약](#-native-subagent-spawn-contract--비용-모델) · [지원 모델](#-지원-모델-및-위임-매트릭스) · [업데이트](#-업데이트-updating) · [참조 문서](#-문서-및-참조-자료)

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

이 스킬은 이미 선택된 Parent를 유지하고 실행 작업만 하향 위임합니다.
사용자가 모델 설정을 비교할 때 참고할 비용·역할·경험 기반 평가는
[모델 경제성 가이드](skills/codex-downshift/references/model-economics.md#8-active-parent-recommendation-non-official-heuristics)에 정리했습니다.

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

## 위임 기준

먼저 현재 runtime/session 정보로 실제 부모 모델을 확인하고, 부모가 요구사항·공개 계약·보안 등 상위 판단을 확정합니다. 그다음 아래 순서로 평가합니다.

| 단계 | 확인할 내용 | 통과하지 못하면 |
| :--- | :--- | :--- |
| **Gate A — 안전성** | 수정 범위와 영향이 명확하고, 객관적으로 검증할 수 있으며, 실패 영향이 국소적·가역적인가? | Parent Direct |
| **Gate B — 판단 권한** | 구현 방법까지 확정되었는가, 아니면 고정된 외부 계약 안에서 내부 구현 선택이 남아 있는가? | 부모 권한을 벗어나는 위임 없이 직접 처리 |
| **Economic Gate — 경제성** | 부모의 준비·검증 비용이 자식에게 맡길 실행량보다 명확히 작은가? | Parent Direct |

Economic Gate는 다음 네 조건을 **모두** 요구합니다. 이를 통과해도 추가 재지시·재작업·검증 부담이 실행 절감분을 상쇄하면 Parent Direct입니다.

1. 부모가 목표, 범위, 확정된 결정, 완료 기준을 이미 알고 있다.
2. 위임 준비에 직접 실행과 맞먹는 분석이 필요하지 않다.
3. 자식이 의미 있는 범위 내 탐색, 반복 구현 또는 테스트·수정 작업을 대신한다.
4. 부모의 준비와 검증 부담이 대체되는 실행 부담보다 명확히 작다.

파일 수나 코드 줄 수만으로 위임을 결정하지 않습니다. DB migration, 보안·권한·배포 변경 등 고위험 작업은 Gate A에서 부모가 직접 처리합니다.
저위험·가역적인 단순 오타 수정은 Gate A 통과 후 Gate B에서 후보를 선정하고, Economic Gate에서 위임 이점이 확인되지 않으면 부모가 직접 처리합니다.

### 작업별 후보 예시

아래는 Gate A를 통과했을 때의 후보입니다. 실제 위임은 Economic Gate까지 통과해야 합니다.

| 작업 상태 | Sol 부모 | Terra 부모 |
| :--- | :--- | :--- |
| 구현 방법과 수정 위치가 모두 확정됨 | Luna Light | Luna Light |
| 구현 방법과 매칭 규칙은 확정되었으나 제한된 범위에서 위치 탐색 필요 | Luna Medium | Luna Medium |
| 외부 동작은 확정되었으나 내부 알고리즘·구현 선택이 남음 | Terra Medium | Parent Direct |
| 제품 동작·공개 API·보안 판단이 미결 | Parent Direct | Parent Direct |

Luna Medium은 탐색 여유를 늘리며 구현 판단 권한은 확대하지 않습니다. `all matches` 요청은 지정한 검색 범위 전체에 고정 규칙을 적용합니다. High 이상은 자동 선택하지 않습니다.

### Routing Notice

라우팅을 실제 평가하면 최종 결정을 한 번 표시합니다. 다음은 출력 예시입니다.

```text
[codex-downshift] → gpt-5.6-luna (low) | formatter_cleanup | 구현과 수정 위치 확정, 반복 실행 위임
[codex-downshift] → Parent Direct | typo_fix | 준비·검증 부담이 직접 실행과 비슷함
```

스킬이 적용되지 않은 요청에는 notice가 없으며, spawn 실패 시 추가 routing notice 없이 부모가 직접 처리합니다. 상세 계약은 [SKILL.md](skills/codex-downshift/SKILL.md)를 따릅니다.

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
│    ──────────────────────────→ Luna Light Child (1.00×)  │
│                                                          │
│ (Active Terra Parent)                                    │
│ ├─ Implementation-local 분석/선택 남음                    │
│ │  ──────────────────────────→ Terra Parent Direct       │
│ ├─ Implementation 닫힘 + 경량 위치 탐색 필요              │
│ │  ──────────────────────────→ Luna Medium Child (2.61×) │
│ └─ Implementation까지 닫힌 기계적 조립/테스트              │
│    ──────────────────────────→ Luna Light Child (1.00×)  │
└──────────────────────────────────────────────────────────┘
                             │ candidate selected
                             ▼
┌──────────────────────────────────────────────────────────┐
│ Economic Gate: Delegation Preparation Test                │
│ Four preparation conditions pass AND net benefit remains │
│ → selected Child; otherwise → Parent Direct              │
└──────────────────────────────────────────────────────────┘
```

### 🚀 Routing signals and Economic Gate
LOC·파일 수는 약한 secondary signal일 뿐이며 Parent Direct 또는 delegation을 독립적으로 결정하지 않습니다. trivial literal/mechanical edit, fixed-rule bounded execution, bounded search, 예상 test/fix loop, implementation-local decision, high-consequence/irreversible work 같은 관찰 가능한 작업 속성이 라우팅을 이끕니다. Gate A와 Gate B 후 Economic Gate에서 Delegation Preparation Test 네 조건을 모두 확인합니다.

Luna Light는 구현과 target locations가 닫힌 기계적 실행, Luna Medium은 구현이 닫히고 parent-fixed Match Rule 및 bounded Search가 필요한 작업입니다. `all matches`는 Search 경계 전체를 검사하며 non-exhaustive examples를 전체 목록으로 오인하지 않습니다. Terra Medium은 Sol Parent에서 외부 계약은 고정됐지만 implementation-local 선택이 남은 경우에만 후보이고, Terra Parent는 직접 처리합니다. 후보여도 경제성이 비슷하면 Parent Direct입니다.

> [!NOTE]
> 경제성은 Delegation Preparation Test로 판단하며, 근거 미확정의 운영 가설을 라우팅 기준으로 사용하지 않습니다. 상세 계약과 근거는 [Task Capsule Template](skills/codex-downshift/references/task-capsule-template.md)과 [Model Economics](skills/codex-downshift/references/model-economics.md)를 참조하세요.

### 🔍 Parent Direct 조건
- high-consequence/irreversible work는 Gate A에서 Parent Direct입니다.
- 저위험·가역적인 trivial literal/mechanical edit는 Gate A 통과 후 Gate B에서 후보를 선정합니다. Economic Gate의 Delegation Preparation Test를 충족하지 못하면 Parent Direct입니다.
- LOC·파일 수만으로 경로를 결정하지 않습니다.

### 👁️ Routing Notice
Gate A → Gate B → Economic Gate를 실제로 평가한 routing 결정은 사용자에게 정확히 한 번 `[codex-downshift] → <model> (<effort>) | <task_name> | <brief reason>` 형식으로 표시합니다. Child delegation은 기존 Spawn Notice를 사용하고, Parent Direct도 `[codex-downshift] → Parent Direct | <task_name> | <first decisive gate or brief reason>`로 표시합니다. 결정적 gate 또는 이유만 짧게 표시하며, 스킬이 적용되지 않아 routing 평가가 없었거나 spawn이 실패한 경우에는 추가 routing notice를 출력하지 않습니다. Canonical 규칙은 [SKILL.md](skills/codex-downshift/SKILL.md)를 따릅니다.

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

아래 수치와 비교는 프로젝트가 보존하는 **2026-09-03 기준 snapshot**입니다. 요율 출처와 추정 지수의 해석 범위는 [Model Economics](skills/codex-downshift/references/model-economics.md)를 참고하세요.

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
> 기존 지수는 산출 재현 미확인 snapshot이다. [산출 근거와 한계](skills/codex-downshift/references/model-economics.md#지수-산출-근거의-재현-상태)를 함께 참고한다.

| 모델 \ 추론 | Light (`low`) | Medium (`medium`) | High (`high`) | XHigh | Max |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Luna** | 🟢 **1.00×** (디폴트) | 🟢 **2.61×** (경량 탐색) | 🟢 **6.00×** (자동선택 금지) | 🟡 **8.77×** | 🟠 **18.31×** |
| **Terra** | 🟢 **4.46×** | 🟢 **5.35×** (고지능 워커) | 🟡 **8.39×** | 🟠 **13.99×** | 🔴 **28.85×** |
| **Sol** | 🟡 **9.40×** | 🟠 **18.04×** (부모 기준선) | 🔴 **25.63×** | 🔴 **35.62×** | 🔴 **52.50×** |

#### 3) 부모 기준선별 예상 상대 절감률 비교
| 자식 설정 | 예상 소모 지수 | vs Sol Light (9.40×) | vs Sol Medium (18.04×) | 주요 적용 작업 |
| :--- | :---: | :---: | :---: | :--- |
| **Luna Light** | **1.00×** | **~89.4% lower** | **~94.5% lower** | 확정된 기계적 조립, 단위 테스트, 정형 린트/수정 |
| **Luna Medium** | **2.61×** | **~72.2% lower** | **~85.5% lower** | 구현 닫힘 + 경량 심볼/위치 로컬 탐색 |
| **Terra Medium** | **5.35×** | **~43.1% lower** | **~70.3% lower** | 로컬 알고리즘/클래스 내부 설계 (Sol Parent 전용) |

#### 4) 핵심 운용 규칙
1. **Luna-First 원칙**: 구현 패턴이 닫힌 작업은 예상 소모 지수가 가장 낮은 Luna Light(1.00×) 또는 Luna Medium(2.61×)을 우선 활용합니다. (Luna Medium은 구현 판단 권한을 확장하지 않음).
2. **Luna High vs Terra Medium 및 Sol-Parent Golden Switch**:
   - CursorBench 3.2 관측상 Luna High(Score 56.8% / Steps 40)는 일부 벤치마크 점수가 높지만, 예상 소모 지수가 더 높고(6.00× vs 5.35×) Agent step이 2배(40 vs 20)입니다.
   - Sol Parent의 implementation-local 선택은 역할 정책에 따라 **Terra Medium** 후보로 처리하고 Economic Gate를 적용합니다. 추정 지수·Steps는 Terra가 낮지만 CursorBench의 금전 비용은 Luna High가 낮습니다. Steps를 소요 시간으로 간주하지 않습니다. [비교 기준과 외부 관측](skills/codex-downshift/references/model-economics.md#4-luna-high-vs-terra-medium-비교-및-sol-parent-golden-switch)을 참조하세요.
   - **Terra Parent**는 Downshift Only 원칙에 따라 Terra Child를 부를 수 없으므로 **Terra Direct**로 직접 수행합니다.
3. **프롬프트 캐시 단순 단가 비교 주의점**:
   - 단순 token-rate 계산상 Sol 40k cached context를 읽는 비용은 약 0.4 credits이며, Luna fresh worker 3k uncached input은 약 0.015 credits로 입력부만 비교 시 약 26.7배 차이가 납니다.
   - 단, 실제 작업 전체 비용은 output, reasoning, 추가 도구 호출 및 반복 스텝에 따라 달라지므로 전체 세션 비용으로 일반화하지 않습니다.
   - *(자세한 산출 근거 및 주의사항은 [Model Economics Reference](skills/codex-downshift/references/model-economics.md) 참조)*

---

## 🔄 업데이트 (Updating)

```bash
# 글로벌로 설치된 codex-downshift 업데이트
npx skills@latest update codex-downshift -g -y

# Windows 환경 fallback 재설치
npx skills@latest add callorange/codex-downshift --skill codex-downshift --agent codex --global -y
```

---

## Task Capsule과 결과 검증

`Apply`는 처리할 대상 범위, `Delegated authority`는 그 안에서 허용되는 구현 재량을 뜻합니다. 고정 결과가 필요하면 `Rule`과 acceptance에 명시합니다.

여러 산출물·all-matches 작업에서 대상별 확인이 필요할 때만 completion set과 탐색·처리 근거를 사용합니다. 검증 명령이 없더라도 관찰 가능한 확인 절차와 통과 기준은 필요합니다. 상세 서식은 [Task Capsule Template](skills/codex-downshift/references/task-capsule-template.md)을 따릅니다.

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
Apply: <Exact | All matches within scope>
Rule: <필요한 경우 parent-fixed rule>
Preserve: <유지해야 하는 기존 동작/호환성>
Do not touch: <수정 금지 영역>
Acceptance criteria:
- [ ] <유지해야 할 의미·동작 불변조건>
- [ ] <기계적 검증 결과>
Validation:
- <검증 명령 또는 관찰 가능한 확인 절차·통과 기준 1>
- <검증 명령 또는 관찰 가능한 확인 절차·통과 기준 2>
Recovery policy: At most ONE recovery attempt when appropriate. If recovery is not appropriate or validation still fails, return TASK_FAILED.
Worker constraints: Leaf worker only. Do not spawn or delegate to other agents or models. Do not perform external side-effects or destructive operations. Do not perform destructive git rollbacks. Stop at one of the four terminal return states.
Return protocol: TASK_COMPLETED, TASK_FAILED, NEEDS_PARENT_DECISION, NEEDS_PARENT_ACTION
```


부모는 위임할 때 목표, 검색·수정 범위, 확정된 결정, 금지 사항, 완료 기준과 검증 명령을 [Task Capsule](skills/codex-downshift/references/task-capsule-template.md)로 전달합니다. 자식은 부모 대화를 상속하지 않는 독립 컨텍스트(`fork_turns = "none"`)에서 지정된 모델과 reasoning effort로 실행되며, 추가 에이전트를 생성할 수 없습니다.

| 반환 상태 | 의미 |
| :--- | :--- |
| `TASK_COMPLETED` | 완료 기준 충족과 검증 통과 증거를 보고 |
| `TASK_FAILED` | 복구 미시도 또는 최대 1회 복구 실패 후 작업트리와 실패 원인을 보존하여 보고 |
| `NEEDS_PARENT_DECISION` | 위임 범위를 넘는 새로운 설계·동작 판단이 필요 |
| `NEEDS_PARENT_ACTION` | push, deploy 등 부모의 권한 또는 외부 작업이 필요 |

부모는 자식의 성공 보고 후에도 diff와 완료 기준을 확인하고, 최종 보고 범위에 맞는 최소한의 검증을 직접 수행합니다. spawn 호출 규격은 [SKILL.md](skills/codex-downshift/SKILL.md), 전체 캡슐 서식과 반환 필드는 [Task Capsule Template](skills/codex-downshift/references/task-capsule-template.md)을 참고하세요.

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

| 문서 | 역할 |
| --- | --- |
| [SKILL.md](skills/codex-downshift/SKILL.md) | 에이전트가 적용하는 실행 규칙 원본 |
| [Project Specification](docs/codex-downshift-spec.md) | 설계 의도·정책 근거·성공 기준 |
| [Delegation Examples](skills/codex-downshift/references/delegation-examples.md) | Gate와 반환 계약의 실전 시나리오 |
| [Model Economics](skills/codex-downshift/references/model-economics.md) | 공식 요율, 보존된 추정 지수, 외부 평가와 사용자 설정 추천 |
| [Task Capsule Template](skills/codex-downshift/references/task-capsule-template.md) | Child 입력과 Terminal Return Protocol 서식 |
| [Documentation Index](docs/README.md) | 핵심 문서의 기준과 동기화 관계 |
| [Changelog](CHANGELOG.md) · [Contributing Guide](CONTRIBUTING.md) | 변경 이력과 기여 절차 |

---

## 🙏 Acknowledgements

Parts of the delegation safety design and execution constraints were inspired by [codex-auto-model-router](https://github.com/orange-the-weak/codex-auto-model-router), particularly its bounded task delegation, task capsule structure, validation budget, and fail-safe execution concepts. `codex-downshift` was independently redesigned and implemented to serve as a lightweight, instruction-only skill focusing strictly on Parent-controlled downshifting with Tiered Downshift and Gate A → Gate B → Economic Gate.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
