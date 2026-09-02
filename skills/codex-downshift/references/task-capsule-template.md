# Task Capsule Template & Terminal Return Protocols

부모 모델(Sol/Terra)이 하위 워커인 Luna(`gpt-5.6-luna`) 또는 Terra(`gpt-5.6-terra`)에 실행 작업을 위임할 때 복사하여 작성하는 표준 프롬프트 서식 및 자식 워커의 표준 반환 프로토콜입니다.

> [!IMPORTANT]
> **Pre-spawn check (parent only; child message에 포함하지 않음)**:
> - Gate A (Safety): Bounded, Verifiable, Limited Consequence(저위험/가역적)인가?
> - Gate B (Authority): 결과의 의미·외부 계약이 확정되었는가?
> - Terra Child 위임 시: 남은 작업이 Implementation-local 분석 및 선택에 한정되는가?
> - Luna Child 위임 시: 구현 방법 및 패턴까지 확정되어 기계적 적용만 남았는가?
> - 정확한 표현/분류가 계약이라면 `Exact change`가 제공되었는가?

---

## 📋 1. Standard Task Capsule Template

```text
TASK CAPSULE

Role:
You are a leaf worker.

Goal:
[작업을 통해 완성해야 하는 명확한 단일 목표]

Target / Scope:
- Code: [수정할 파일 경로 및 심볼/함수/클래스]
- Test: [수정 또는 추가할 테스트 파일 경로]

Decisions already made:
- [부모 모델이 이미 확정한 요구사항, API, 동작, 호환성 결정 1]
- [부모 모델이 이미 확정한 세부 로직 및 인터페이스 규칙 2]

Delegated authority:
[Luna Child: Predetermined execution only - apply fixed patterns, assemble code, or mechanical edits]
or
[Terra Child: Implementation-local analysis and choice allowed within fixed external contracts]

Must not decide:
- [부모 모델 고유의 판단 영역: Architecture, Public API, Product Policy, Security, Scope 확장 등]

Exact change:
[정확한 결과 형태가 계약이면 필수: final text, before/after 또는 고정 변환 규칙]

Preserve:
- [반드시 유지해야 하는 기존 동작, 호환성, 타입 힌트]
- [유지해야 하는 네이밍 및 인터페이스 규칙]

Do not touch:
- [작업 범위 밖의 파일 및 모듈]

Acceptance criteria:
- [ ] [유지해야 할 의미·동작·호환성 불변조건 1]
- [ ] [유지해야 할 의미·동작·호환성 불변조건 2]
- [ ] [테스트·lint·typecheck 등 기계적 검증 결과]

Validation:
- [검증 명령 1 (예: pytest tests/test_foo.py)]
- [검증 명령 2 (예: ruff check src/foo.py)]

Recovery policy:
At most ONE recovery attempt. If validation still fails, return TASK_FAILED immediately. Do not enter recursive retry loops.

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

### 2) 복구 한도 초과 실패 (`TASK_FAILED`)
```text
TASK_FAILED

Modified files:
- <path1>
- <path2>

Validation:
- <failed command> -> FAILED
  <short error evidence>

Recovery:
- Attempted: YES (1 recovery attempt executed)
- <1회 시도했던 수정 내용 요약>

Remaining blocker:
<수정 후에도 검증을 통과하지 못한 원인 및 현 상태>

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
