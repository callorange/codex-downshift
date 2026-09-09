# Terminal & Recovery Scenarios

이 문서는 Child가 실행 중 판단·외부 작업·검증 실패에 직면했을 때의 네 terminal state,
복구 한도, exceptional effort와 Parent verification 사례를 모은다. 라우팅 후보 판정 사례는
[Delegation Examples](delegation-examples.md)를 따른다.

모든 사례에는 [SKILL.md](../SKILL.md)의 Gate A → Gate B → Economic Gate, Leaf Worker, Fail Closed,
bounded recovery와 Parent evidence review 규칙이 그대로 적용된다.

---

## 🧪 Scenario 6: Child 작업 중 새 설계 판단 직면 (`NEEDS_PARENT_DECISION`)

하위 워커(Luna, Terra, Sol 또는 Astra)가 구현 중 기존 레거시 코드와의 심각한 호환성 충돌이나 모호한 요구사항을 마주했을 때:

```text
NEEDS_PARENT_DECISION

Unresolved:
Target function `validate_company_email` is imported by 8 legacy authentication views that expect a boolean (`False`) return on failure, whereas the Task Capsule specifies raising `ValueError("Invalid corporate email")`.

Why it blocks execution:
Raising ValueError will break backwards compatibility for existing legacy authentication endpoints. Choosing between maintaining boolean return or refactoring legacy callers exceeds the delegated authority.

Relevant:
- src/validators/email.py:L15-L25
- src/legacy/auth_views.py:L40-L90

Worktree:
- Local edits in src/validators/email.py are currently kept in working tree without commit.
```

---

## 🧪 Scenario 7: Child 외부 부수효과 직면 (`NEEDS_PARENT_ACTION`)

하위 워커가 로컬 구현과 검증을 마쳤으나, 원격 저장소 푸시, 배포, 또는 외부 서비스 통신이 필요한 경우:

```text
NEEDS_PARENT_ACTION

Action required:
Git push to remote branch `origin/feature-auth` and trigger CI workflow.

Why needed:
Leaf workers are constrained from executing network-side effects or publishing repository changes.

Task completed so far:
- Implemented `validate_company_email` in src/validators/email.py.
- Verified all unit tests passing (3/3 PASSED) via pytest tests/test_email_validator.py.

Worktree:
- All changes are clean, formatted, and validated in local workspace.
```

---

## 🧪 Scenario 8: Bounded recovery 종료 (`TASK_FAILED`)

- **상황 A (기본 budget 소진)**: Capsule의 `Corrective attempts: 1`에 따라 validation 실패 원인을 수정하고 영향받는 검사를 재실행했지만, 같은 진단 원인의 실패가 유지되고 다른 수정 근거가 없음.
- **상황 B (환경 실패, 구체적인 action 없음)**: Child가 허용된 scope에서 해결할 수 없는 테스트 환경 불일치가 확인됐지만 Parent나 사용자가 수행할 구체적인 조치도 없음.
- **올바른 동작**:
  - 상황 A: 사용한 budget과 남은 실패 증거를 기록하고 `TASK_FAILED` 반환.
  - 상황 B: 작업 산출물을 억지로 수정하지 않고 `Used: 0`과 recovery 미시도 사유를 기록해 `TASK_FAILED` 반환.
  - credential 제공, 서비스 시작, 승인처럼 구체적인 상위 조치가 있다면 대신 `NEEDS_PARENT_ACTION`을 사용.
  - `git reset --hard` 등으로 작업트리를 자의적으로 파괴하지 않고 상태를 보존하여 부모에게 인계.

Parent가 서로 독립적인 두 test/fix cycle을 예상하고 Capsule에 `Corrective attempts: 2`를 명시했다면 Child는 두 cycle까지 사용할 수 있다. 모델 tier나 첫 실패만으로 budget을 자동 확장하지 않으며, hard stop 조건은 남은 횟수보다 우선한다.

```text
TASK_FAILED

Modified files:
- src/services/payment.py
- tests/test_payment.py

Validation:
- pytest tests/test_payment.py -> FAILED
  E   TypeError: unsupported operand type(s) for +: 'Decimal' and 'float'

Recovery:
- Budget: 1
- Used: 1
- Updated the allowed conversion path, then reran the affected test. The same diagnosed fixture contract mismatch remains and no further correction is supported within the delegated scope.

Remaining blocker:
Third-party gateway client fixture in tests/conftest.py returns mock data as float, conflicting with strict Decimal typing in payment service.

Worktree:
- Current changes preserved for Parent review. No automatic reset/revert/clean performed.
```

---

## 🧪 Scenario 9: High Reasoning Effort 필요 상황 (예외적 사용자 승인 프로토콜)

- **원칙**: `high` / `xhigh` / `max`는 normal downshift optimization path가 아니며, 자동 라우팅에서 절대 선택되지 않습니다. 오직 사용자가 명시적으로 요청하거나 승인한 **exceptional override**로만 동작합니다.
- **상황**: Sol이 외부 동작·API·호환성 요구를 고정한 로컬 알고리즘 작업에서, Medium 실행 결과의 구체적인 누락을 확인했다. 남은 선택은 고정 계약 안의 내부 구현이며, 영향이 국소적이고 결정적 검증이 가능하다.
- **올바른 동작 흐름**:
  1. **권한·안전성 확인**: Gate A와 Gate B를 적용한다. 상위 판단이 남거나 영향 범위가 불명확하면 Parent Direct다.
  2. **경제성 확인**: 반복 구현·검증의 대체 실행량과 준비·검증·재작업 부담을 비교한다. Economic Gate를 통과하지 못하면 Parent Direct다. 작업 크기 자체는 실익의 근거가 아니다.
  3. **예외 승인 확인**: High가 필요한 구체적 이유와 고정 계약·검증 방법을 설명하고, 해당 effort 사용이 아직 승인되지 않았다면 사용자에게 요청한다. 이미 명시적으로 요청·승인된 범위는 다시 묻지 않는다.
  4. **실행**: 승인 및 모든 Gate 통과 시 `model="gpt-5-6-terra"`, `reasoning_effort="high"`로 위임한다. 미승인 시 Parent Direct다.
- effort 승인은 상위 판단 권한, 동일 모델 위임 금지, Leaf Worker, bounded recovery 또는 Gate 조건을 바꾸지 않는다.

---

## 🧪 Scenario 10: Child Spawn 실패 (Fail-Closed Fallback)

- **상황**: 런타임 제약 또는 일시적 API 오류로 `spawn_agent(model="gpt-5-6-terra")` 호출이 실패함.
- **올바른 동작 (Fail-Closed)**:
  - ❌ `gpt-5-6-luna`로 우회 spawn하지 않음.
  - ❌ `model`을 생략한 child를 재시도하지 않음.
  - ✅ **부모 모델(Sol)이 해당 작업을 직접 이어서 수행하여 마무리합니다.**

---

## 🧪 Scenario 11: Parent Evidence Review와 조건부 validation

### 충분한 Child evidence

- **상황**: Luna가 실행 명령, exit status, 검증 범위, 핵심 결과와 미검증 범위를 포함한 `TASK_COMPLETED`를 반환했고 실제 tool result도 확인 가능하다. Parent의 diff 검토에서 새 우려가 없고 이후 변경도 없다.
- **부모 모델의 올바른 동작**:
  1. 실제 변경과 Acceptance를 대조한다.
  2. Child claim과 evidence scope가 완료 주장에 충분한지 확인한다.
  3. 이미 성공한 동일 테스트를 이유 없이 반복하지 않고, 확인한 evidence 범위 안에서 완료를 보고한다.

### 추가 Parent-side validation 필요

- **상황**: Child가 `pytest tests/test_email_validator.py -> PASSED`라고만 보고해 exit status, 검증 범위와 실제 tool result를 확인할 수 없다.
- **부모 모델의 올바른 동작**:
  1. 단순 성공 자기보고를 충분한 evidence로 취급하지 않는다.
  2. 완료 주장에 필요한 가장 좁은 회귀 테스트를 Parent가 실행한다.
  3. 실제 결과와 미검증 범위를 구분해 보고한다.
