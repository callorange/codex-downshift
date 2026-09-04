# Task Capsule Template & Terminal Return Protocols

부모 모델(Sol/Terra)이 하위 워커인 Luna(`gpt-5.6-luna`) 또는 Terra(`gpt-5.6-terra`)에 실행 작업을 위임할 때 복사하여 작성하는 표준 프롬프트 서식 및 자식 워커의 표준 반환 프로토콜입니다.

> [!IMPORTANT]
> **Pre-spawn check (parent only; child message에 포함하지 않음)**:
> - Gate A (Safety): Bounded, Verifiable, Limited Consequence(저위험/가역적)인가?
> - Gate B (Authority): 결과의 의미·외부 계약이 확정되었는가?
> - Terra Child 위임 시: 남은 작업이 Implementation-local 분석 및 선택에 한정되는가?
> - Luna Child 위임 시: 구현 방법 및 패턴까지 확정되어 기계적 적용만 남았는가?
> - 정확한 결과가 계약이라면 `Apply: Exact`와 필요한 고정 `Rule`/결과 형식이 제공되었는가?
> - Economic Gate (Delegation Preparation Test): 네 조건을 모두 충족하는가? 아니면 Parent Direct인가.

---

## 📋 1. Standard Task Capsule Template

### Compactness

**작성 범위**

이 template은 상세하지만 실제 emitted Capsule은 **Minimum Sufficient Context**만 사용한다.

**필드 선택과 중단 조건**

모든 필드는 작업에 필요한 경우에만 작성하며, capsule 작성에 새 분석·상세 설계가 필요해지면 Economic Gate에서 Parent Direct를 선택한다.

```text
TASK CAPSULE

Worker profile: [Luna | Terra]
Role: You are a leaf worker.

Goal:
[작업을 통해 완성해야 하는 명확한 단일 목표]

Scope:
- Search: [검색 대상 경로/심볼; optional]
- Modify: [수정 허용 파일·심볼; optional]

Intent / Why: [선택; 목적을 이해하는 데 필요할 때만]

Decisions already made:
- [부모 모델이 이미 확정한 요구사항, API, 동작, 호환성 결정 1]
- [부모 모델이 이미 확정한 세부 로직 및 인터페이스 규칙 2]

Delegated authority:
[Luna Child: Predetermined execution only - apply fixed patterns, assemble code, or mechanical edits]
or
[Terra Child: Implementation-local analysis and choice allowed within fixed external contracts]

Must not decide:
- [부모 모델 고유의 판단 영역: Architecture, Public API, Product Policy, Security, Scope 확장 등]

Apply: [Exact | All matches within scope | Implementation-local choice]
Rule: [optional parent-fixed rule]
Examples: [optional; explicitly exhaustive or non-exhaustive]

Items (micro-batch only; omit for a general single task):
- [item]: Target [path/symbol]; Fixed change [rule]; Acceptance [check]

Preserve / Do not touch:
- [반드시 유지해야 하는 기존 동작, 호환성, 타입 힌트]
- [유지해야 하는 네이밍 및 인터페이스 규칙]


Acceptance criteria:
- [ ] [유지해야 할 의미·동작·호환성 불변조건 1]
- [ ] [유지해야 할 의미·동작·호환성 불변조건 2]
- [ ] [테스트·lint·typecheck 등 기계적 검증 결과]

Validation: [선택; 검증 명령 1, 2...]

Recovery policy:
At most ONE recovery attempt when appropriate. If recovery is not appropriate (e.g. env/dependency issue) or validation still fails, return TASK_FAILED immediately. Do not enter recursive retry loops.

Worker constraints:
- Do not spawn or delegate to other agents or models.
- Do not perform external side-effects (git push, deploy, release) or destructive operations.
- Do not perform destructive git rollbacks (git reset --hard, git checkout -- .) on failure.
- Stop immediately at one of the 4 terminal return states.

Return protocol:
- TASK_COMPLETED
- TASK_FAILED
- NEEDS_PARENT_DECISION
- NEEDS_PARENT_ACTION
```

### Profile guidance

#### Luna — profile 선택

Luna Low는 target locations closed, Luna Medium은 closed Match Rule + bounded Search다.

#### Luna — 검색과 판단의 경계

Luna는 rule을 발명/확장하지 않고 non-exhaustive examples에서도 Search 경계의 모든 매치를 검사하며 semantic·architecture·product·compatibility·policy 판단은 `NEEDS_PARENT_DECISION`이다.

#### Terra — 전달할 계약

Terra에는 다음만 주고 절차를 과도하게 고정하지 않는다:

- goal
- fixed external contract
- forbidden changes
- acceptance
- 기존 패턴 선호·최소 구현·Public API 보존의 local criteria

### Micro-batch completion format

```text
TASK_COMPLETED
Items:
- [x] item-1 — modified: path/to/file
- [x] item-2 — modified: path/to/file
Modified files: [all paths]
Validation: <command> -> PASSED
```
**미완료·판단 필요 시**

미완료 항목은 전체를 `TASK_COMPLETED`로 표시하지 않는다.
판단이 필요하면 기존 네 상태 중 하나를 사용하고 item statuses와 Worktree를 함께 보고한다.

---

## 🛑 2. 4대 Terminal Return Protocols

모든 Child 작업은 반드시 다음 4가지 상태 중 하나로 종료해야 합니다.

### 1) 정상 완료 (`TASK_COMPLETED`)
Task Capsule의 Acceptance Criteria를 대조하여 반환 (다중 검증 명령 지원):
```text
TASK_COMPLETED

Modified files:
- <path1>
- <path2>

Validation:
- <command 1> -> PASSED
  <short evidence>
- <command 2> -> PASSED
  <short evidence>

Acceptance:
- [x] <Task Capsule acceptance criterion 1>
- [x] <Task Capsule acceptance criterion 2>

Notes:
- None (or optional bounded implementation note)
```

### 2) 복구 한도 초과 또는 미시도 실패 (`TASK_FAILED`)
```text
TASK_FAILED

Modified files:
- <path1>
- <path2>

Validation:
- <failed command> -> FAILED
  <short error evidence>

Recovery:
- Attempted: YES | NO
- <recovery summary or reason recovery was not appropriate>

Remaining blocker:
<why the task remains incomplete>

Worktree:
- Current changes preserved for Parent review.
- No automatic reset/revert/clean performed.
```

### 3) 설계 판단 필요 시 (`NEEDS_PARENT_DECISION`)
```text
NEEDS_PARENT_DECISION

Unresolved:
<새로운 모호성, 호환성 충돌 또는 상위 설계 판단 요구사항>

Why it blocks execution:
<위임된 권한 범위를 초과하여 하위 워커가 자의적으로 결정할 수 없는 이유>

Relevant:
<관련 파일 / 심볼 경로>

Worktree:
<현재 로컬 수정 상태>
```

### 4) 외부 부수효과 / 승인 필요 시 (`NEEDS_PARENT_ACTION`)
```text
NEEDS_PARENT_ACTION

Action required:
<git push, deploy, secret 설정, 승인 필요 외부 작업>

Why needed:
<외부 권한이 필요한 이유>

Task completed so far:
<완료된 로컬 작업 및 검증 결과 요약>

Worktree:
<현재 로컬 수정 상태>
```
