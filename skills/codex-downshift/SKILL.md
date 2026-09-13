---
name: codex-downshift
description: Use for non-trivial coding implementation, modification, debugging, or testing performed by an Active Parent model (Astra, Sol, or Terra) when bounded execution may be worth downshifting, including Child/subagent model and effort selection. Evaluates delegation safety, decision authority, and end-to-end economics against Parent Direct. Do not use for explanation-only, research-only, planning or brainstorming without implementation, non-development requests, or read-only review, audit, inspection, or diagnosis.
---

# Codex Downshift (Execution Delegator Skill)

본 스킬은 OpenAI Codex 환경에서 부모 모델(**Astra**, **Sol** 또는 **Terra**)이 상위 판단을 완료한 후, 안전 게이트와 남은 판단 권한(Decision Authority)에 따라 구체적인 실행 작업을 더 낮은 모델 tier 또는 같은 모델의 더 낮은 reasoning effort를 사용하는 Leaf Child로 다운시프트하여 Codex 사용량과 반복 비용을 절감하는 실행 지침입니다.

---

## 🎯 1. 핵심 철학 및 10대 불변 규칙 (10 Core Invariants)

> **"Safe enough to delegate → delegate only the remaining authority → keep every child leaf-only → return structured evidence → let the Parent review the evidence behind every completion claim."**

사용자의 명시적 목표·범위·결과 선호는 일반 default보다 우선한다. Child routing과 configuration은 Gate A, Gate B, Economic Gate, Downshift Only 및 delegated-authority 계약을 따른다. 요청한 Child가 이 계약에 적합하지 않으면 Parent Direct로 결과를 수행한다.

### 1. Parent Authority (부모 모델 권한 보존)

사용자가 선택한 Active Parent(Astra, Sol 또는 Terra)는 요구사항 해석, 제품 동작, 아키텍처, Public API, 보안, 호환성 등 모든 상위 미결 판단을 직접 소유한다. Parent 역할 자체는 Child에게 위임되지 않는다.

### 2. Downshift Only (구성 기준 단방향 하향 위임)

Child 구성은 Active Parent보다 다음 중 한 방식으로 엄격히 낮아야 한다.

- **모델 하향**: 모델 tier `Astra > Sol > Terra > Luna`에서 Parent보다 낮은 tier를 선택한다. 하위 모델의 effort는 별도 effort 정책과 작업 적합성을 따른다.
- **effort 하향**: 같은 모델에서 `Light < Medium < High < XHigh < Max` 순서상 Parent보다 낮은 effort를 명시한다.
- **금지**: 상위 모델 호출, 같은 모델의 동일·상위 effort, 실제 Parent model/effort를 추정한 같은 모델 위임.
- **자동 경로**: Child target effort는 Light 또는 Medium만 사용한다. `high`·`xhigh`·`max` target은 사용자 명시적 요청·승인이 있는 예외다.
- *(단, Child가 `NEEDS_PARENT_*` 또는 `TASK_FAILED`로 Parent에게 제어권을 반환하는 것은 상향 위임이 아니며 정상 프로토콜임)*

### 3. Safety Before Routing (Gate A)

모델 선택 전에 반드시 **Gate A (Delegation Safety Gate)**를 먼저 통과해야 한다. 저위험·가역적·검증 가능한 작업이 아니면 모델 판단 없이 무조건 **Parent Direct**.

### 4. Task-Based Delegated Authority (작업별 위임 권한)

의미와 외부 계약은 모든 Child에서 확정되어야 한다. 모델을 고르기 전에 다음 권한을 Capsule에 명시한다.

| 작업 상태 | 위임 권한 | 반환 경계 |
| --- | --- | --- |
| Implementation Closed | Predetermined execution: 확정된 구현·Match Rule 적용 | Rule 변경이나 새 구현 선택이 필요하면 `NEEDS_PARENT_DECISION` |
| Implementation-Local Decision Remains | Implementation-local choice: 고정 외부 계약 안의 내부 구현 분석·선택 | 제품·아키텍처·Public API·보안·호환성 판단이 필요하면 `NEEDS_PARENT_DECISION` |

권한은 작업 상태로 먼저 결정하되, 모델별 적격 범위는 구분한다. Luna Child는 `Implementation Closed`인 Predetermined execution만 수행한다.
Implementation-local choice에는 Terra 이상에서 충분한 하위 구성을 선택한다. 높은 모델·effort도 위임 권한을 확장하지 않는다.
`all matches`는 지정한 검색 경계 전체를 확인하고 non-exhaustive examples를 전체 목록으로 오인하지 않는다.

### 5. Leaf Worker / No Chaining

모든 Child는 Leaf Worker이며 다른 agent나 model을 spawn/invoke/delegate할 수 없다. `Sol ➔ Terra ➔ Luna` 다단계 체이닝 금지.

### 6. Fail Closed

Child spawn 실패, 라우팅 모호성, 또는 권한 불확실 시 다른 하위 모델로 우회하지 않고 **부모 모델이 직접 수행**.

### 7. Reasoning Effort & 모델 정책

- 자동 Child target은 Light (`low`) 또는 Medium (`medium`)이다. `high`·`xhigh`·`max`는 사용자 명시적 요청·승인 시에만 예외로 허용한다.
- 작업 권한에 적격인 lower-model과 same-model lower-effort 후보를 비교한다. 같은 모델 경로는 실제 Parent effort가 확인되고 target이 엄격히 낮으면 작업 종류와 무관하게 평가할 수 있다.
- 모델 유지나 낮은 단가만으로 선택하지 않는다. 능력 적합성과 준비·실행·검증·재작업을 포함한 예상 비용으로 Parent Direct와 비교한다. 불확실성이 커서 이점을 판단할 수 없으면 Parent Direct다.
- 설정별 후보 추천은 [Model Selection Guide](references/model-selection.md), 비용 근거는 [Model Economics](references/model-economics.md)를 필요할 때 읽는다.

### 8. Bounded Recovery

Child의 기본 recovery budget은 최초 구현·검증 뒤 corrective attempt 1회다. Parent가 Capsule에 0 이상의 유한한 `Corrective attempts` 값을 명시한 경우에만 그 값으로 확장하거나 축소한다. corrective attempt는 실패한 validation을 해결하려고 허용된 작업 산출물을 새로 수정한 뒤 영향받는 validation을 다시 수행하는 한 cycle이다. 작업 산출물을 바꾸지 않는 잘못된 명령·인자·working directory 교정은 budget을 소비하지 않지만 같은 실행 오류를 반복하지 않는다. 최초 validation 전의 formatter·safe auto-fix는 정상적인 기계적 수렴이며 corrective attempt가 아니다.

budget 소진, 위임 권한 초과, 허용 scope 밖 수정 필요, 구체적인 외부·Parent action 필요, 또는 같은 진단 원인에 대한 수정 뒤 같은 validation failure가 유지되고 다른 수정 근거가 없으면 즉시 적절한 terminal state로 종료한다. 모델 tier만으로 budget을 바꾸거나 Child가 실행 중 delegation ROI를 다시 판단하지 않는다.

### 9. Structured Return Protocols

Child는 반드시 4대 반환 프로토콜(`TASK_COMPLETED`, `TASK_FAILED`, `NEEDS_PARENT_DECISION`, `NEEDS_PARENT_ACTION`) 중 하나로 종료하며, 임의로 destructive rollback(`git reset --hard` 등)을 수행하지 않음.

### 10. Evidence Before Completion (Scope Matching)

Parent는 Child 결과를 Blind Trust하지 않고 실제 변경과 validation evidence를 검토하며, Completion Claim과 evidence scope가 일치하는지 확인한다. Parent-side validation은 evidence가 부족하거나 변경·claim 범위·미해결 위험 때문에 필요할 때만 수행한다.

---

## 🛑 The Parent Execution Protocol (4단계 다운시프트 루프)

원래 사용자 요청은 전체 목표이지 반드시 위임 후보는 아니다. 요청 자체가 이미 bounded execution unit인 경우를 제외하고, 전체 프롬프트를 기본 후보 하나로 취급하지 않는다. Parent는 현재 실제로 수행하려는 논리적으로 닫힌 실행 단위 또는 bounded batch를 candidate로 형성하고, 각 candidate마다 게이트를 한 번 평가한다. 파일 읽기·함수 검색·한 줄 수정·개별 shell command·formatter 실행 같은 tool-call 단위로 쪼개거나 매 편집 호출마다 재평가하지 않는다.
범위·권한·위험이 실질적으로 바뀌거나 실패로 기존 판단 근거가 무효화되면 재평가한다.
Child delegation이면 2–4단계를 수행하고 Parent Direct이면 해당 candidate를 직접 실행·검증한다. Parent Direct는 candidate-local이며 사용자 요청의 나머지 작업으로 전파되지 않는다.

### 1. Trigger, Candidate Formation & Gate Check

- **Parent Analysis / Candidate Formation**: Parent가 소유할 미결 요구사항·제품 동작·아키텍처·Public API·보안·호환성 판단을 식별하고 먼저 해결한다. Parent-owned decision과 predetermined execution이 섞여 있으면 분리한다. 판단이 남아 있는 상태는 전체 요청의 Parent Direct 최종 판정이 아니라 routing 보류다. 필요한 판단을 직접 마친 뒤 남은 실행 작업에서 독립적인 logical execution unit 또는 bounded batch를 식별하고 candidate별 routing에 진입한다. 이후 별개 candidate가 생겨도 같은 절차를 적용한다.

- **Active Configuration Resolution (hard precondition, not a new gate)**:
  - **직접 증거 우선**: Child를 선택하기 전에 현재 runtime/context에 직접 노출된 effective model과 effort를 확인한다. LLM 자기보고, task complexity, 이전 turn의 기억, default, repository context, `config.toml`, 지원 모델 목록 또는 model picker 후보로 추정하지 않는다.
  - **Codex runtime fallback**: model 또는 effort 중 필요한 값을 직접 확인할 수 없으면 현재 Parent routing 결정 시점에 [PowerShell resolver](scripts/resolve-active-configuration.ps1) 또는 [bash resolver](scripts/resolve-active-configuration.sh)를 실행한다. 두 resolver는 `$CODEX_THREAD_ID`와 `$HOME/.codex/sessions`를 사용하고, `rg --files`로 matching rollout 후보를 좁힌 뒤 최신 파일의 마지막 `turn_context`에서 `payload.model`과 `payload.effort`만 JSON으로 반환한다. 직접 확인된 값은 그대로 사용하고, resolver 값은 누락된 값만 보완하되 양쪽 model이 불일치하면 effort를 결합하지 않는다. 이는 현재 Codex runtime에서 이용 가능한 fallback일 뿐 영구적이거나 공식적인 API 계약이 아니며, turn 사이에 결과를 캐시하지 않는다. 다른 session 내용은 출력하거나 근거로 사용하지 않는다.

  - **판정**: model과 effort를 모두 확인하면 정상적으로 모든 후보를 평가한다. model만 확인하면 그 model보다 낮은 tier 후보는 계속 평가하되 same-model effort 후보만 제외한다. 직접 증거와 runtime fallback 모두에서 model을 확인하지 못하면 Parent Direct로 fail closed한다.
  - **엄격한 하향 확인**: 같은 모델 Child의 target effort가 Parent보다 낮지 않거나 비교할 수 없으면 Parent Direct로 fail closed한다.
  - **권한 경계**: 이 resolution과 routing은 현재 사용자-facing/root Parent authority를 가진 agent만 수행한다. Capsule 또는 worker context에서 Leaf Worker로 지정된 Child는 자신의 환경에서 이 fallback을 실행해 자신을 Parent로 재분류하거나 이 스킬을 재적용하지 않으며, 다른 agent를 spawn하지 않는다.
- [선행 조건] 현재 candidate의 상위 판단이 완료되었는가? 미완료라면 Parent가 해당 판단을 직접 해결한 뒤 remaining work의 Candidate Formation으로 돌아간다.
- [보조 신호] LOC·파일 수는 약한 secondary signal일 뿐이며 Parent Direct 또는 delegation을 독립적으로 결정하지 않는다. 작업 속성(사소한 literal/mechanical edit, fixed-rule bounded execution, bounded search, 예상 test/fix loop, implementation-local decision, high-consequence/irreversible work)을 관찰한다.
- ➔ Gate A(안전성) → Gate B(잔여 권한/후보 선택) → Economic Gate 순으로 평가한다.
- **Parent Direct**: Gate A, Gate B, 또는 Economic Gate가 Parent Direct를 선택하면 해당 candidate에 대한 Task Capsule을 작성하거나 Child를 spawn하지 않는다. Parent가 그 candidate를 직접 구현·검증하고, 별개로 남은 실행 candidate는 다시 형성·평가한다.
- **Child delegation**: 위임이 선택된 경우에만 다음 단계를 수행한다.

### 2. Capsule Emission

- [Task Capsule 표준 서식](references/task-capsule-template.md)에 따라 목표, 허용 범위, Acceptance Criteria, 검증 명령을 확정하여 프롬프트 작성.

### 3. Leaf Worker Spawn

- `spawn_agent`에 Gate에서 선택한 Child 모델과 effort를 그대로 전달한다 (`fork_turns = "none"`). 자동 target effort는 Light의 `low` 또는 Medium의 `medium`이다.
- *부모 세션 모델을 상속(`inherit`)하거나 모델 파라미터를 생략하는 것은 금지.*

### 4. Collect & Scope-Matched Verify

- 워커의 반환(`TASK_COMPLETED`) 수신 후 Parent가 실제 변경, Acceptance와 validation evidence를 대조한다. Parent-side validation 조건이 확인되면 그 조건을 해소하는 가장 좁은 검증을 실행한다.

---

## 🧭 2. 게이트 기반 결정적 라우팅 파이프라인 (Routing Pipeline)

| 단계 | 판단 | 통과하지 못하면 |
| --- | --- | --- |
| Parent Analysis / Candidate Formation | Parent-owned decision을 해결하고 남은 실행을 논리적으로 닫힌 candidate로 식별 | 판단 해결 후 remaining work로 재진입; 아직 gate 판정 아님 |
| Active Configuration Resolution | 실제 Parent model 확인; same-model 후보는 실제 effort도 확인 | 확인할 수 없는 후보 제외; model 미확인이면 Parent Direct |
| Gate A: Safety | Bounded, Verifiable, Limited Consequence; 보안·권한·DB migration·배포·파괴적 변경 배제 | Parent Direct |
| Gate B: Authority & Capability | 위임 권한을 정하고 그 권한에 충분한 엄격한 하위 구성을 비교 | 적격 후보가 없으면 Parent Direct |
| Economic Gate | 아래 준비 조건과 예상 전체 비용을 Parent Direct와 비교 | Parent Direct |

LOC·파일 수·단일 검증 명령은 독립적인 위임 근거가 아니다. bounded search, 반복 구현, test/fix 실행량과 검증 부담을 관찰한다.
구체적인 모델 추천은 [Model Selection Guide](references/model-selection.md)에 두며, 추천을 모델별 독점 권한으로 해석하지 않는다.

### 💰 Economic Gate and Delegation Preparation Test

경제성은 Delegation Preparation Test로 판단한다. 이를 통과해도 위임의 추가 재지시·재작업·검증 부담이 실행 절감분을 상쇄하면 Parent Direct다. 공식 요율과 Estimated Consumption Index의 수치·해석 범위는 [Model Economics](references/model-economics.md)를 따른다.

**Delegation Preparation Test**

다음 네 조건에 모두 해당할 때만 위임한다:

1. Parent가 goal, scope, fixed decisions, acceptance를 이미 알고 있는가;
2. Child task 준비에 direct execution과 비교 가능한 분석이 필요하지 않은가;
3. Child가 의미 있는 bounded search, 반복, 구현 또는 test/fix work를 대체하는가;
4. Parent preparation plus verification이 대체되는 execution보다 명확히 작은가.

**불충족 시**: 하나라도 아니면 Parent Direct다.

### 📚 On-demand references

Core rules로 결정되면 모든 reference를 preload하지 않는다.

| 참조 문서 | 읽는 조건 |
| --- | --- |
| `task-capsule-template.md` | 실제 Child delegation을 선택하고 Capsule을 작성할 때만 읽는다. |
| `model-economics.md` | Economic Gate에서 공식 요율·추정 지수·비용 모델이 필요할 때만 읽는다. |
| `benchmark-costs.md` | 동일 하네스의 공개 비용 재계산이나 실측 비교 방법이 필요할 때만 읽는다. |
| `model-benchmarks.md` | 모델·effort별 외부 성능 관측이나 그 한계를 비교할 때만 읽는다. |
| `model-selection.md` | Parent 설정 또는 기존 Child 후보의 effort 추천이 필요할 때만 읽는다. |
| `delegation-examples.md` | core rules로 routing 사례가 여전히 모호할 때만 읽는다. |
| `terminal-scenarios.md` | terminal state, recovery, exceptional effort 또는 Parent verification 사례가 필요할 때만 읽는다. |

### 👁️ Routing Notice

Active Configuration Resolution → Gate A → Gate B → Economic Gate routing 평가를 실제로 수행한 경우에만, 최종 routing 결정을 사용자에게 정확히 한 번 표시한다.

| 상황 | 출력 시점·횟수 | 표시 내용과 제한 |
| --- | --- | --- |
| Child delegation 선택 | 실제 spawn 직전 한 번 | 아래 Child 형식 사용. `<model>`은 현재 Parent가 아니라 실제 spawn할 Child model이다. |
| Parent Direct 선택 | 최종 결정 시 한 번; Child spawn 불필요 | 아래 Parent Direct 형식 사용. Gate A, Gate B 또는 Economic Gate 중 최종 결정을 만든 첫 번째 결정적 이유만 짧게 담는다. |
| 스킬이 적용되지 않아 routing 평가를 수행하지 않음 | 출력하지 않음 | routing notice 없음 |
| Child spawn 실패 | 추가 routing notice 없음 | Fail-Closed 규칙에 따라 Parent가 직접 수행한다. |

**Child 형식**

`[codex-downshift] → <model> (<effort>) | <task_name> | <brief reason>`

**Parent Direct 형식**

`[codex-downshift] → Parent Direct | <task_name> | <first decisive gate or brief reason>`

Parent Direct notice에 모든 gate 평가나 상세 추론을 나열하지 않는다. 전체 capsule은 출력하지 않는다.

### Micro-batching

**묶을 수 있는 조건**

다음 조건을 모두 충족하면 하나의 micro-batch 후보로 묶을 수 있다:

- 서로 독립적인 복수의 저위험·가역적·Implementation-Closed 항목이다.
- 같은 Child model/effort와 bounded scope를 공유한다.
- 의존성·아키텍처·제품·보안·Public API에 관한 미결 판단이 없다.
- 각 항목을 별도로 위임하는 것보다 하나의 Capsule로 묶는 준비·조율·결과 확인 부담이 작다.

실제 위임은 Gate A → Gate B → Economic Gate를 모두 통과할 때만 수행한다.
묶음 처리가 별도 위임보다 저렴하더라도 Parent Direct보다 경제적이라는 뜻은 아니다.

**결과·판단 필요 시 처리**

각 항목의 checkmark 결과를 반환하고 하나라도 판단이 필요하면 네 terminal state를 보존하며 worktree를 명확히 보고한다.

**구별할 작업**

이는 하나의 고정 규칙을 반복 적용하는 pattern batch와 구별한다.

### Profile semantics

권한은 4번 불변 규칙의 두 profile로 구분한다. Capsule에는 선택한 권한, 고정 외부 계약, 금지 변경, acceptance를 전달한다.
Predetermined execution에서는 고정 Rule을 만들거나 넓히지 않는다. Luna는 이 profile만 사용할 수 있다.
Implementation-local choice에서는 Terra 이상을 선택하고 기존 패턴·최소 구현·Public API 보존 등 선택 기준을 제공하며 절차를 과도하게 고정하지 않는다.
모든 profile의 Scope·Apply·검증·worker 제한·반환 필드는 [Task Capsule Template](references/task-capsule-template.md)을 따른다.

### 🔍 Parent Direct 조건

- high-consequence/irreversible work는 Gate A에서 Parent Direct로 처리한다.
- 저위험·가역적인 trivial literal/mechanical edit는 작업 종류만으로 직접 수행을 확정하지 않는다. Gate A를 통과하면 Gate B에서 후보를 선정하고, Economic Gate의 Delegation Preparation Test를 충족하지 못하면 Parent Direct로 처리한다.
- LOC·파일 수만으로 경로를 결정하지 않는다.
- 같은 모델의 더 낮은 effort가 확인되지 않거나 다른 적격 후보 및 Parent Direct 대비 예상 전체 비용 이점이 없으면 effort-only Child를 선택하지 않는다.

---

## 🚀 3. Spawn and Return Contract

자동 경로에서는 부모 속성을 상속하지 않도록 `model`, `fork_turns = "none"`, `reasoning_effort`, `task_name`, `message`를 모두 명시한다. `message`는 [Task Capsule Template](references/task-capsule-template.md)의 Minimum Sufficient Context로 작성한다.

| 모델 | `model` | 자동 `reasoning_effort` |
| --- | --- | --- |
| Luna | `gpt-5-6-luna` | `low` / `medium` |
| Terra | `gpt-5-6-terra` | `low` / `medium` |
| Sol | `gpt-5-6-sol` | `low` / `medium` |
| Astra | `gpt-6-astra` | `low` / `medium` |

이 표는 호출 인자 대응이다. 실제 적격성은 2번 불변 규칙의 엄격한 모델·effort 하향 조건을 따른다.

하위 모델 경로에는 Parent와 Child의 effort 비교를 적용하지 않는다. 같은 모델 경로는 실제 Parent effort를 확인하고 target보다 엄격히 높은 경우에만 허용한다.

`high`·`xhigh`·`max` exceptional override도 명시적 사용자 요청·승인과 모든 gate를 충족해야 하며, 위임 권한·Leaf Worker·복구 한도는 바뀌지 않는다.

### Terminal Return Protocol

모든 Child 작업은 반드시 다음 4가지 상태 중 하나로 종료해야 합니다. Child는 자의적인 rollback(`git reset --hard` 등)을 하지 않고 현재 상태를 보존하여 보고합니다.

| 반환 상태 | 반환 조건 | 필요한 보고·후속 동작 |
| --- | --- | --- |
| `TASK_COMPLETED` | Acceptance criteria 충족 및 검증 통과 | 완료 기준 대조와 검증 증거 보고 |
| `TASK_FAILED` | 허용 scope와 recovery budget 안에서 완료하지 못했고 요구할 구체적인 Parent action도 없음 | 작업트리 보존, 실패 원인·사용한 recovery budget·미시도 사유 상세 보고 |
| `NEEDS_PARENT_DECISION` | 위임 범위를 넘는 새로운 설계/동작 판단 필요 | 미결 판단과 위임 권한을 넘는 이유를 보고하고 Parent에게 제어권 반환 |
| `NEEDS_PARENT_ACTION` | `git push`, `deploy`, 비밀값 등 외부 권한 작업 필요 | 필요한 외부 작업과 그 전까지 완료한 작업을 보고하고 Parent에게 제어권 반환 |

상세 반환 필드는 [Task Capsule Template](references/task-capsule-template.md), 판단·실패·복구 사례는 [Terminal & Recovery Scenarios](references/terminal-scenarios.md)를 따른다.

---

## 🔍 4. Parent Evidence Before Completion & Scope Matching

Parent는 Child의 성공 보고를 Blind Trust하지 않고 다음 evidence review를 항상 수행합니다:

1. Child가 변경을 만들었다면 실제 변경 대상과 diff를 검토한다. 변경 없음이 기대되는 실행이면 예상하지 않은 worktree 변경이 없는지 확인한다.
2. Task Capsule의 Acceptance 충족 여부를 확인한다. Completion set을 사용했다면 대상별 처리 결과와 discovery evidence도 확인한다.
3. Child validation evidence에서 실행 명령 또는 관찰 절차, 성공·실패 상태와 핵심 결과, 검증 범위, 미검증 범위, recovery 뒤 최종 결과를 확인한다. 확인 가능한 실제 tool result는 Child의 요약보다 우선한다.
4. **`Verification scope MUST match the completion claim scope.`**에 따라 Child claim, evidence와 Parent의 Completion Claim 범위를 대조한다.

단순 성공 자기보고는 충분한 evidence가 아니다. 다음 중 하나가 확인되면 Parent는 그 조건을 해소하는 가장 좁은 validation을 수행한다:

- evidence 필수 항목이 없거나 실제 tool result를 확인할 수 없어 신뢰 범위가 불분명하다.
- Parent가 Child 완료 뒤 관련 작업 산출물을 수정했다.
- Parent의 Completion Claim 또는 public/shared contract 영향이 Child validation 범위보다 넓다.
- diff 검토에서 새로운 미해결 우려를 발견했다.
- Child validation이 실패했거나 실행되지 않았다.

위 조건이 없고 관련 변경도 없다면 이미 성공한 동일 validation command를 반복하지 않는다. Parent가 수정했다면 그 수정의 직접 영향 범위만 다시 검증한다. 필요한 검증을 수행할 수 없으면 해당 범위를 완료로 보고하지 않는다.

## 📚 5. 참조 문서

- [Model Economics & Estimated Consumption Index](references/model-economics.md)
- [Model Benchmarks](references/model-benchmarks.md)
- [Model Selection Guide](references/model-selection.md)
- [위임 라우팅 사례](references/delegation-examples.md)
- [Terminal & Recovery Scenarios](references/terminal-scenarios.md)
- [Task Capsule 및 4대 반환 프로토콜 표준 서식](references/task-capsule-template.md)
- [프로젝트 상세 기획 명세서 — 저장소 참고 자료](https://github.com/callorange/codex-downshift/blob/main/docs/codex-downshift-spec.md)
