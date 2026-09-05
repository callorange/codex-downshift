# codex-downshift

> **Keep the parent model in control, downshift bounded execution to a strictly lower model configuration.**

`codex-downshift`는 OpenAI Codex에서 **Sol** 또는 **Terra**를 주력(부모) 모델로 사용할 때, Gate A Safety → Gate B Decision Authority → Economic Gate를 통과한 실행 작업만을 더 낮은 모델 tier 또는 같은 모델의 더 낮은 reasoning effort를 사용하는 서브에이전트로 다운시프트(하향 위임)하여 Codex 사용량과 반복 비용을 절감하는 경량 Agent Skill입니다.

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
위임 조건을 충족하는 작업만 더 낮은 모델 구성에 맡겨줘.
```

부모는 요구사항을 정리하고 위임 가능 여부를 판단합니다. 위임하는 경우 Task Capsule 작성과 자식 모델 선택까지 수행하므로 사용자가 spawn 파라미터를 직접 작성할 필요는 없습니다. 준비·검증 비용에 비해 실행량이 작으면 **Parent Direct**로 처리하는 것이 정상입니다.

[위임 기준](#위임-기준) · [비용 비교와 실행 계약](#-실행-계약과-비용-근거) · [지원 모델](#-지원-모델-및-위임-매트릭스) · [업데이트](#-업데이트-updating) · [참조 문서](#-문서-및-참조-자료)

---

## 💡 왜 Router가 아니라 "Downshift(Delegator)"인가?

본 프로젝트는 모델 간에 사용자를 임의로 스위칭하거나 복잡한 라우팅 규칙을 적용하는 일반적인 Model Router가 아닙니다.

1. **Parent Authority (부모 모델의 판단권 유지)**: 요구사항 해석, 아키텍처 설계, Public API, 보안, 비즈니스 결정 등 고난도 추론은 사용자가 선택한 Active Parent(Sol/Terra)가 끝까지 책임지며, Parent 역할 자체는 Child에게 위임되지 않습니다.
2. **단방향 하향 위임 (Downshift Only)**: 상위 부모 모델의 판단이 끝난 실행 작업만 더 낮은 모델 tier(`Sol ➔ Terra/Luna`, `Terra ➔ Luna`) 또는 같은 모델의 더 낮은 effort로 내려보냅니다.
3. **Leaf Worker / No Chaining**: 모든 자식 워커는 Leaf Worker로 동작하며 다른 에이전트 생성이나 다단계 체이닝(`Sol ➔ Terra ➔ Luna`)이 엄격히 금지됩니다.
4. **Safety Before Routing (Gate A → Gate B → Economic Gate)**: Bounded, Verifiable, Limited Consequence(저위험/가역적)를 먼저 확인하고, 남은 권한에 맞는 후보를 고른 뒤 준비·검증보다 leverage가 클 때만 위임합니다. DB migration이나 보안 등 High Consequence 작업은 구현이 닫혀 있어도 **부모 모델이 직접 수행**합니다.
5. **Fail-Closed Fallback**: Child spawn 실패 또는 라우팅 모호 시 타 모델 우회 없이 **부모 모델이 직접 수행**합니다.
6. **Evidence Before Completion**: Parent는 Child의 성공 보고를 맹신하지 않고, 자신의 완료 보고 범위와 일치하는 독립적인 **Minimum Sufficient Fresh Verification을 직접 수행**합니다.

---

## 📊 지원 모델 및 위임 매트릭스

이 스킬은 이미 선택된 Parent를 유지하고 실행 작업만 하향 위임합니다.
사용자가 모델 설정을 비교할 때 참고할 비용·역할·경험 기반 평가는
[모델 선택 가이드](skills/codex-downshift/references/model-selection.md)에 정리했습니다.

| Parent | Child 구성 | 대상 작업과 추가 조건 |
| :--- | :--- | :--- |
| **Sol 또는 Terra** | ✅ **Luna Light/Medium** | `Implementation Closed`. Light는 target까지 고정된 기계적 실행, Medium은 고정 Rule의 bounded search·1회 복구 실행 |
| **Sol** | ✅ **Terra Light/Medium** | `External Contract Closed`. Light는 기존 패턴으로 좁혀진 선택, Medium은 일반 implementation-local 선택 |
| **Terra** | ✅ **Terra Light/Medium** | 같은 모델 effort 하향. 실제 Parent effort가 target보다 높아야 하며 작업에 낮은 effort가 충분해야 함 |
| **Sol** | ✅ **Sol Light/Medium** | 같은 모델 effort 하향. 상호 의존 관계나 독립 요구사항을 함께 추적하고 결정적 검증만으로 누락 확인이 어려워 Terra가 Parent 수동 검증·재작업을 늘리며, 실제 Parent effort가 target보다 높아야 함 |
| **Sol 또는 Terra** | 🛑 **Parent Direct** | 적격인 엄격한 하위 구성이 없거나 준비·검증 부담이 실행 절감분을 상쇄함 |
| **Luna** | ❌ **비활성화** | 사용자가 Luna를 Parent로 선택한 경우 상위 모델 자동 호출 없음 |

> [!NOTE]
> 상위 모델 호출과 같은 모델의 동일·상위 effort 위임은 허용하지 않습니다. 같은 모델 경로는 실제 Parent effort를 확인한 뒤 `Light < Medium < High < XHigh < Max` 순서상 엄격히 낮은 Light 또는 Medium만 자동 선택합니다.

---

## 위임 기준

먼저 현재 runtime/session 정보로 실제 부모 모델을 확인합니다. 같은 모델 경로를 검토하려면 실제 Parent effort도 확인합니다. 부모가 요구사항·공개 계약·보안 등 상위 판단을 확정한 뒤 아래 순서로 평가합니다.

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
| 구현은 닫혀 있고 bounded search 또는 검증 실패에 고정 Rule로 대응하는 1회 복구가 실행의 실질적 부분 | Luna Medium | Luna Medium |
| 기존 패턴으로 선택지가 좁은 implementation-local 작업 | Terra Light | Parent가 Medium 이상이면 Terra Light, 아니면 Parent Direct |
| 일반 implementation-local 선택이 남음 | Terra Medium | Parent가 High 이상이면 Terra Medium, 아니면 Parent Direct |
| 상호 의존 관계나 독립 요구사항을 함께 추적하고 결정적 검증만으로 누락 확인이 어려움 | Terra가 Parent 수동 검증·재작업을 늘리면, Parent가 Medium 이상일 때 Sol Light 또는 High 이상일 때 Sol Medium | 해당 없음 |
| 제품 동작·공개 API·보안 판단이 미결 | Parent Direct | Parent Direct |

Luna Medium은 닫힌 구현의 bounded 탐색·고정 복구 실행에 추론 여유를 늘리며 구현 판단 권한은 확대하지 않습니다. 단순 검증 명령 실행만으로 Medium을 선택하지 않습니다. `all matches` 요청은 지정한 검색 범위 전체에 고정 규칙을 적용합니다. 같은 모델 유지 자체는 effort-only 경로의 근거가 아니며, lower-model 후보가 충분하면 해당 후보를 먼저 경제성 비교 대상으로 삼습니다. High 이상은 자동 선택하지 않습니다.

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
Active Configuration Resolution
  │ actual Parent model 확인; same-model 후보는 actual effort도 확인
  │ 확인 불가 시 해당 후보 제외 또는 Parent Direct
  ▼
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
│ Gate B: Decision Authority & Capability Fit              │
│ - closed mechanical execution ─────────────→ Luna Light  │
│ - closed bounded search/fixed recovery ────→ Luna Medium │
│ - narrow established local choice ─────────→ Terra Light │
│ - general implementation-local choice ─────→ Terra Medium│
│ - lower tier raises rework/verification cost              │
│   ───────────────→ same-model strictly lower Light/Medium │
│ - no eligible strictly lower configuration ─→ Parent Direct│
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

Luna Light는 구현과 target locations가 닫힌 기계적 실행, Luna Medium은 구현이 닫힌 상태에서 parent-fixed Match Rule에 따른 bounded Search 또는 검증 실패에 고정 Rule로 대응하는 1회 복구가 실행의 실질적 부분인 작업입니다. `all matches`는 Search 경계 전체를 검사하며 non-exhaustive examples를 전체 목록으로 오인하지 않습니다. Terra Light/Medium은 implementation-local 선택의 폭에 따라 고릅니다. Terra Parent의 same-model 경로와 Sol Parent의 Sol 경로는 실제 Parent effort보다 target이 낮아야 합니다. lower tier가 충분하면 먼저 비교하고, 어느 후보든 경제성이 비슷하면 Parent Direct입니다.

> [!NOTE]
> 경제성은 Delegation Preparation Test로 판단하며, 근거 미확정의 운영 가설을 라우팅 기준으로 사용하지 않습니다. 상세 계약과 근거는 [Task Capsule Template](skills/codex-downshift/references/task-capsule-template.md)과 [Model Economics](skills/codex-downshift/references/model-economics.md)를 참조하세요.

### 🔍 Parent Direct 조건
- high-consequence/irreversible work는 Gate A에서 Parent Direct입니다.
- 저위험·가역적인 trivial literal/mechanical edit는 Gate A 통과 후 Gate B에서 후보를 선정합니다. Economic Gate의 Delegation Preparation Test를 충족하지 못하면 Parent Direct입니다.
- LOC·파일 수만으로 경로를 결정하지 않습니다.

### 👁️ Routing Notice
Gate A → Gate B → Economic Gate를 실제로 평가한 routing 결정은 사용자에게 정확히 한 번 `[codex-downshift] → <model> (<effort>) | <task_name> | <brief reason>` 형식으로 표시합니다. Child delegation은 기존 Spawn Notice를 사용하고, Parent Direct도 `[codex-downshift] → Parent Direct | <task_name> | <first decisive gate or brief reason>`로 표시합니다. 결정적 gate 또는 이유만 짧게 표시하며, 스킬이 적용되지 않아 routing 평가가 없었거나 spawn이 실패한 경우에는 추가 routing notice를 출력하지 않습니다. Canonical 규칙은 [SKILL.md](skills/codex-downshift/SKILL.md)를 따릅니다.

---

## 🚀 실행 계약과 비용 근거

다운시프트 실행은 `model`, `fork_turns = "none"`, `reasoning_effort`, `task_name`, `message`를 모두 명시해 Parent 설정 상속을 막습니다. 실제 `message`에는 [Task Capsule Template](skills/codex-downshift/references/task-capsule-template.md)의 Minimum Sufficient Context를 담습니다.

| 경로 | 추가 조건 | 모델·effort | 보존된 예상 소모 지수 |
| --- | --- | --- | ---: |
| Sol 또는 Terra Parent → Luna Light | model 하향 | `gpt-5.6-luna` · `low` | 1.00× |
| Sol 또는 Terra Parent → Luna Medium | model 하향 | `gpt-5.6-luna` · `medium` | 2.61× |
| Sol Parent → Terra Light/Medium | model 하향 | `gpt-5.6-terra` · `low` / `medium` | 4.46× / 5.35× |
| Terra Parent → Terra Light/Medium | 실제 Parent effort가 target보다 높음 | `gpt-5.6-terra` · `low` / `medium` | 4.46× / 5.35× |
| Sol Parent → Sol Light/Medium | 실제 Parent effort가 target보다 높고 Terra에서 누락 위험 때문에 Parent 수동 검증·재작업이 늘어나는 근거가 있음 | `gpt-5.6-sol` · `low` / `medium` | 9.40× / 18.04× |

공식 Token-Credit Rate와 전체 Estimated Consumption Index는 [Model Economics](skills/codex-downshift/references/model-economics.md), 모델·추론 레벨별 관측값은 [Model Benchmarks](skills/codex-downshift/references/model-benchmarks.md), 비용·성능·human steering·rework·verification을 함께 고려한 추천은 [Model Selection Guide](skills/codex-downshift/references/model-selection.md)를 기준으로 합니다. 기존 지수는 산출 재현 미확인 snapshot이며 공식 allowance 환산식이 아닙니다.

벤치마크 점수만으로 경로와 권한을 정하지 않습니다. 현재 정책은 model tier 하향과 같은 모델의 effort 하향을 모두 Downshift Only로 다루며, 같은 모델 경로에는 실제 Parent effort 확인과 lower-tier 부적합 근거를 추가로 요구합니다. Luna Medium은 bounded search뿐 아니라 검증 실패에 고정 Rule로 대응하는 1회 복구가 실질적 실행량일 때도 후보입니다. High 이상은 자동 선택하지 않습니다.

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
            ├── model-benchmarks.md
            ├── model-economics.md
            ├── model-selection.md
            ├── terminal-scenarios.md
            └── task-capsule-template.md
```

---

## 📖 문서 및 참조 자료

| 문서 | 역할 |
| --- | --- |
| [SKILL.md](skills/codex-downshift/SKILL.md) | 에이전트가 적용하는 실행 규칙 원본 |
| [Project Specification](docs/codex-downshift-spec.md) | 설계 의도·정책 근거·성공 기준 |
| [Delegation Examples](skills/codex-downshift/references/delegation-examples.md) | Gate와 권한별 라우팅 시나리오 |
| [Terminal & Recovery Scenarios](skills/codex-downshift/references/terminal-scenarios.md) | Child 반환·복구·예외 effort와 Parent 검증 사례 |
| [Model Economics](skills/codex-downshift/references/model-economics.md) | 공식 요율, 보존된 추정 지수와 위임 비용 모델 |
| [Model Benchmarks](skills/codex-downshift/references/model-benchmarks.md) | 모델·추론 레벨별 외부 평가 snapshot과 적용 한계 |
| [Model Selection Guide](skills/codex-downshift/references/model-selection.md) | 비용·성능·실제 작업 부담을 종합한 설정 추천 |
| [Task Capsule Template](skills/codex-downshift/references/task-capsule-template.md) | Child 입력과 Terminal Return Protocol 서식 |
| [Documentation Index](docs/README.md) | 핵심 문서의 기준과 동기화 관계 |
| [Changelog](CHANGELOG.md) · [Contributing Guide](CONTRIBUTING.md) | 변경 이력과 기여 절차 |

---

## 🙏 Acknowledgements

Parts of the delegation safety design and execution constraints were inspired by [codex-auto-model-router](https://github.com/orange-the-weak/codex-auto-model-router), particularly its bounded task delegation, task capsule structure, validation budget, and fail-safe execution concepts. `codex-downshift` was independently redesigned and implemented to serve as a lightweight, instruction-only skill focusing strictly on Parent-controlled downshifting with Tiered Downshift and Gate A → Gate B → Economic Gate.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
