# Task Capsule Template & Terminal Return Protocols

부모 모델(Astra/Sol/Terra)이 더 낮은 모델 tier 또는 같은 모델의 더 낮은 reasoning effort를 사용하는 Leaf Child에 실행 작업을 위임할 때 복사하여 작성하는 표준 프롬프트 서식 및 자식 워커의 표준 반환 프로토콜입니다.

> [!IMPORTANT]
> **Pre-spawn check (parent only; child message에 포함하지 않음)**:
> - Gate A (Safety): Bounded, Verifiable, Limited Consequence(저위험/가역적)인가?
> - Gate B (Authority): 결과의 의미·외부 계약이 확정되었는가?
> - Active Configuration: 실제 Parent model을 확인했는가? 같은 모델 경로라면 실제 Parent effort도 확인했으며 Child effort가 엄격히 낮은가?
> - 위임 권한을 Predetermined execution 또는 Implementation-local choice로 명시했으며, 선택한 모델·effort가 해당 작업과 검증에 충분한가?
> - Luna Child라면 `Implementation Closed`인 Predetermined execution만 남았는가?
> - `Apply`가 지정 target만 처리할지(`Exact`), Search 범위의 모든 매치를 처리할지(`All matches within scope`) 명확히 하는가?
> - 고정된 결과가 계약이라면 적용 범위와 별개로 필요한 고정 `Rule`/결과 형식이 제공되었는가?
> - Economic Gate: 네 준비 조건을 모두 충족하고, 추가 재지시·재작업·검증 부담이 실행 절감분을 상쇄하지 않는가? 아니면 Parent Direct다.

---

## 📋 1. Standard Task Capsule Template

### Compactness

**작성 범위**

이 template은 상세하지만 실제 emitted Capsule은 **Minimum Sufficient Context**만 사용한다.

**필드 선택과 중단 조건**

작업에 불필요한 필드는 생략하되, 목표·허용 범위·위임 권한·완료 기준·검증 방법·worker 제한과 반환 상태가 전달 문맥에서 명확해야 한다.
검증 명령이 없는 경우에도 관찰 가능한 확인 절차와 통과 기준은 제공한다.
capsule 준비에 direct execution과 비교 가능한 분석·상세 설계가 필요하거나, 준비·검증 부담이 대체 실행량보다 명확히 작지 않으면 Economic Gate에서 Parent Direct를 선택한다. 추가 확인이나 분석이 있다는 사실만으로 위임을 배제하지 않는다.

```text
TASK CAPSULE

Worker profile: [Luna | Terra | Sol | Astra]
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
[Predetermined execution: apply fixed rules only]
or
[Implementation-local choice: choose internal implementation within fixed external contracts]

Must not decide:
- [부모 모델 고유의 판단 영역: Architecture, Public API, Product Policy, Security, Scope 확장 등]

Apply: [Exact | All matches within scope]
Rule: [optional parent-fixed rule]
Examples: [optional; explicitly exhaustive or non-exhaustive]

Completion set (optional; 여러 산출물·all-matches 작업에서 대상별 확인이 필요한 경우):
- Known targets: [이미 알려진 필수 대상]
- Discovery: [필요한 경우 Scope.Search와 Rule로 추가 대상 탐색; 결과를 미리 추측하지 않음]

Items (micro-batch only; omit for a general single task):
- [item]: Target [path/symbol]; Fixed change [rule]; Acceptance [check]

Preserve / Do not touch:
- [반드시 유지해야 하는 기존 동작, 호환성, 타입 힌트]
- [유지해야 하는 네이밍 및 인터페이스 규칙]


Acceptance criteria:
- [ ] [유지해야 할 의미·동작·호환성 불변조건 1]
- [ ] [유지해야 할 의미·동작·호환성 불변조건 2]
- [ ] [테스트·lint·typecheck 등 기계적 검증 결과]

Validation: [검증 명령 또는 관찰 가능한 확인 절차와 통과 기준]

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

### 적용 범위와 구현 재량

| 필드 | 결정하는 내용 |
| --- | --- |
| `Apply: Exact` | 지정한 target만 처리한다. 결과 문자열의 일치 여부를 뜻하지 않는다. |
| `Apply: All matches within scope` | 정해진 Search 범위에서 고정 Rule에 해당하는 모든 매치를 검사하고 처리한다. |
| `Delegated authority` | 해당 범위 안에서 구현 방법을 선택할 수 있는지를 결정한다. |

Implementation-local Child도 `Apply: Exact`와 implementation-local choice를 함께 사용할 수 있다.
출력이나 치환 결과를 고정해야 한다면 `Rule`과 acceptance에 별도로 명시한다.

### 완료 대상과 검증 근거

여러 산출물·all-matches 작업에서 대상별 완료 확인이 필요하면 선택적 `Completion set`을 사용한다.
단순 단일 대상 작업에는 이를 기계적으로 추가하지 않는다.

| 확인 항목 | 적용 조건 | 보고할 근거·완료 경계 |
| --- | --- | --- |
| 탐색 범위 | Completion set 사용 시 | Known targets를 포함하고 추가 대상은 지정된 Search와 Rule로 발견한다. `Exact`이면 지정 target이 경계다. |
| 대상별 처리 결과 | Completion set 사용 시 | 각 대상을 `modified` 또는 근거가 있는 `not modified`로 보고한다. 미처리 대상은 완료로 표시하지 않는다. |
| 탐색 증거 | all-matches 작업 | 검색 범위·적용 규칙·확인 결과를 보고한다. 가능하면 수정 후 같은 범위를 재검색해 의도하지 않은 잔여 매치를 확인한다. |
| 검증 근거 | 완료 판단에 필요한 검증 | `Validation`에 실행한 명령 또는 관찰 가능한 확인 절차와 실제 결과를 기록한다. 명령어가 없다는 이유로 검증을 생략하지 않는다. |
| 완료 판정 | 작업 완료 보고 시 | 발견한 대상의 처리 완료와 검색 범위 전체의 확인을 구분한다. 필요한 탐색·처리·검증 증거가 없으면 `TASK_COMPLETED`로 보고하지 않는다. |

필요한 검증을 수행할 수 없으면 blocker와 작업트리를 보존해 기존 반환 상태에 맞게 보고한다.

### Profile guidance

권한은 모델과 독립적으로 선택한다. [SKILL.md](../SKILL.md)의 작업별 위임 권한이 원본이며, 모델 추천은 [Model Selection Guide](model-selection.md)를 필요할 때 읽는다.

| 위임 권한 | 적격 Child | 허용 재량 |
| --- | --- | --- |
| Predetermined execution | 모든 적격 Child; Luna는 이 권한만 허용 | 고정 Rule 안의 적용·탐색·검증·허용된 복구; 새 구현 선택 금지 |
| Implementation-local choice | Terra 이상 적격 Child | 고정 계약 안의 내부 구현 선택; 상위 의미·제품·아키텍처·보안·호환성 판단 금지 |

모든 모델에서 `Apply: Exact`는 지정 target만, `All matches within scope`는 Search 전체의 모든 매치를 처리한다.
non-exhaustive examples는 전체 목록이 아니다. 권한 밖의 판단이 필요하면 `NEEDS_PARENT_DECISION`으로 반환한다.

### Micro-batch completion format

```text
TASK_COMPLETED
Items:
- [x] item-1 — modified: path/to/file
- [x] item-2 — not modified: path/to/file — already satisfies the fixed rule
Modified files: [modified paths only]
Validation: <command or observable check> -> PASSED; <evidence>
```
**미완료·판단 필요 시**

미완료 항목은 전체를 `TASK_COMPLETED`로 표시하지 않는다.
판단이 필요하면 기존 네 상태 중 하나를 사용하고 item statuses와 Worktree를 함께 보고한다.

---

## 🛑 2. 4대 Terminal Return Protocols

모든 Child 작업은 반드시 다음 4가지 상태 중 하나로 종료해야 합니다.

### 1) 정상 완료 (`TASK_COMPLETED`)
Task Capsule의 Acceptance Criteria를 대조하여 반환 (다중 검증 명령 또는 관찰 가능한 확인 절차 지원):
```text
TASK_COMPLETED

Modified files:
- <path1>
- <path2>

Validation:
- <command or observable check 1> -> PASSED
  <short evidence>
- <command or observable check 2> -> PASSED
  <short evidence>

Coverage (optional; Completion set을 사용한 경우):
- <target> -> modified | not modified: <reason>
Discovery (optional; all-matches 작업):
- <Search / Rule / 검색 결과 및 가능한 경우 재검색 결과>

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
