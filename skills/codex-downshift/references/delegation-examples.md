# Delegation Examples & Verification Scenarios

본 문서는 `codex-downshift` 스킬의 핵심 동작 및 검증 시나리오를 정의한 참조 가이드입니다.

---

## 🎯 핵심 시나리오 요약 매트릭스

| 번호 | 시나리오 상황 | 부모 모델 | 다운시프트 동작 | 기대 결과 |
| :--- | :--- | :--- | :--- | :--- |
| **1** | 명확한 구현 / TDD 작업 | **Sol** | ✅ **위임 (Downshift)** | `gpt-5.6-luna` child 생성 (`fork_turns="none"`, `reasoning_effort="medium"`) |
| **2** | 명확한 문서 / 린트 수정 | **Terra** | ✅ **위임 (Downshift)** | `gpt-5.6-luna` child 생성 (`reasoning_effort="low"`) |
| **3** | 단일 1줄/리터럴 수정 단독 | **Sol/Terra** | ❌ **부모 직접 수행** | Task Capsule 오버헤드 방지를 위해 부모가 직접 수정 |
| **4** | 여러 기계적 수정 + 테스트 묶음 | **Sol/Terra** | ✅ **배치 위임** | 여러 작은 작업을 하나의 Bounded Task Capsule로 묶어 Luna에 위임 |
| **5** | 주력 모델로 단독 실행 중 | **Luna** | ❌ **비활성화 (No-op)** | child 생성 없이 Luna가 직접 처리 |
| **6** | 계획 / 브레인스토밍 요청 | **Sol/Terra** | ❌ **비활성화 (No-op)** | child 생성 없이 부모가 직접 설계·답변 |
| **7** | 원인 불명의 복잡한 디버깅 | **Sol/Terra** | ❌ **비활성화 (No-op)** | child 생성 없이 부모가 원인 규명 및 해결 |
| **8** | 새 설계 판단 직면 | **Luna Worker**| 🛑 **에스컬레이션** | `NEEDS_PARENT_DECISION` 반환 후 부모가 판단 |
| **9** | Luna spawn 실패 / 미지원 | **Sol/Terra** | 🛡️ **Fail-Closed Fallback** | 상위 모델 child 생성/재시도 없이 부모가 직접 수행 |
| **10**| Luna 작업 완료 후 | **Sol/Terra** | 🔄 **최소 Acceptance** | 전체 재작업/동일테스트 반복 없이 결과만 확인 |

---

## 🧪 Scenario 1: Sol + 명확한 TDD 구현 (정상 위임)

### 상황
부모 모델(Sol)이 사용자 요구사항을 분석하고, 이메일 검증 로직의 규격과 테스트 케이스를 모두 확정한 상태.

### 부모 모델의 동작
```text
spawn_agent(
    model = "gpt-5.6-luna",
    fork_turns = "none",
    reasoning_effort = "medium",
    task_name = "implement_email_domain_validator",
    message = """Role: You are a leaf execution worker.
Goal: Add email domain validation for '@company.com' only, and verify with tests.
Target:
- Code: src/validators/email.py :: validate_company_email
- Test: tests/test_email_validator.py

Decisions already made:
- Function: def validate_company_email(email: str) -> bool
- Behavior: Returns True if email ends with '@company.com' (case-insensitive), otherwise raises ValueError("Invalid corporate email").
- Implementation: Use string.lower().endswith("@company.com").

Exact change:
1. In tests/test_email_validator.py, add tests for valid domain, invalid domain (raises ValueError), and case insensitivity.
2. In src/validators/email.py, implement validate_company_email.

Preserve: Existing validator functions in src/validators/email.py.
Validation: pytest tests/test_email_validator.py
Escalation condition: If existing callers rely on validate_company_email returning False instead of raising ValueError, return NEEDS_PARENT_DECISION.
Worker constraints: Leaf worker only. Do not spawn agents or invoke other models."""
)
```

---

## 🧪 Scenario 2: Terra + Docstring / 문서 수정 (Low Reasoning 위임)

### 상황
부모 모델(Terra)이 특정 함수의 Docstring을 Google Python Style에 맞추어 작성하기로 결정함.

### 부모 모델의 동작
```text
spawn_agent(
    model = "gpt-5.6-luna",
    fork_turns = "none",
    reasoning_effort = "low",
    task_name = "update_user_service_docstring",
    message = """Role: You are a leaf execution worker.
Goal: Update docstring for UserService.create_user.
Target: src/services/user_service.py :: UserService.create_user

Exact change:
Replace the existing docstring with:
\"\"\"Creates a new active user in the system.

Args:
    username: Unique username for login.
    email: Verified email address.

Returns:
    User: The newly created User model instance.

Raises:
    UserAlreadyExistsError: If a user with the same email already exists.
\"\"\"

Preserve: Function signature, implementation, and type hints.
Validation: ruff check src/services/user_service.py
Escalation condition: If signature differs from above, return NEEDS_PARENT_DECISION.
Worker constraints: Leaf worker only. Do not spawn agents."""
)
```

---

## 🧪 Scenario 3: 단일 1줄/리터럴 수정 단독 (부모 직접 수행 예외)

- **상황**: `config.py`의 `TIMEOUT = 30`을 `TIMEOUT = 60`으로 1줄만 수정하는 독립적이고 사소한 단독 요청.
- **부모 모델의 동작**:
  - Task Capsule 작성 및 `spawn_agent` 호출 오버헤드가 코드 수정 자체보다 명백히 크므로, **부모 모델(Sol/Terra)이 직접 수술적 편집(Surgical Edit)을 수행**하여 완료합니다.

---

## 🧪 Scenario 4: 여러 기계적 수정 + 테스트 묶음 (Bounded Batching 위임)

- **상황**: 5개 파일의 deprecated import 경로 수정 및 관련 2개 테스트 실행이 필요한 작업.
- **올바른 동작 (Good - Batching)**:
  - 5개 수정을 각각 Luna 1~5로 파편화하여 생성하지 않고, **하나의 Bounded Task Capsule로 묶어서 단일 Luna 워커에게 위임**합니다.
- **부모 모델의 동작**:
  - `spawn_agent(model="gpt-5.6-luna", fork_turns="none", reasoning_effort="low", task_name="batch_update_deprecated_imports", message="...")`

---

## 🧪 Scenario 5: Luna Parent 사용 시 (자동 위임 비활성화)

- **상황**: 사용자가 Codex의 주 모델을 `Luna`로 선택하여 대화 중.
- **동작**: `codex-downshift` 스킬은 완전히 비활성화되며, Luna가 다른 에이전트(Terra/Sol)를 호출하지 않고 모든 작업을 직접 수행합니다.

---

## 🧪 Scenario 6: Planning / Brainstorming 요청 (위임 제외)

- **사용자 요청**: "이 서비스의 인증 아키텍처 개선 계획을 세워줘."
- **부모 모델의 동작**:
  - 서브에이전트를 생성하지 않습니다.
  - 부모 모델(Sol/Terra)이 코드베이스를 직접 조사하고 계획 문서를 작성합니다.

---

## 🧪 Scenario 7: 원인 불명의 복잡한 디버깅 (위임 제외)

- **사용자 요청**: "간헐적으로 세션 토큰 만료 에러가 발생하는데 원인을 찾아서 고쳐줘."
- **부모 모델의 동작**:
  - 원인이 규명되지 않은 모호한 상태이므로 Luna에 위임하지 않습니다.
  - 부모 모델이 직접 가설 수립 및 로그 추적을 진행하여 근본 원인을 파악한 후에만 필요 시 구체적 코드 수정을 위임합니다.

---

## 🧪 Scenario 8: Luna 작업 중 새 설계 판단 필요 시 (`NEEDS_PARENT_DECISION`)

하위 워커(Luna)가 실행 도중 지침에 없는 모호한 상황이나 호환성 문제를 발견했을 때의 반환 예시입니다:

```text
NEEDS_PARENT_DECISION

Unresolved:
Target function `validate_company_email` is already imported and used by 12 legacy endpoints expecting a boolean return (`False`), not a raised `ValueError`.

Why it blocks execution:
Raising ValueError as specified will break backwards compatibility for 12 existing test suites in `tests/legacy/`.

Relevant:
- src/validators/email.py:L15
- tests/legacy/test_auth_endpoints.py:L45-L80
```

---

## 🧪 Scenario 9: Luna Spawn 실패 시 Fail-Closed Fallback (불변 규칙)

- **상황**: 계정 권한 또는 런타임 제약으로 `spawn_agent(model="gpt-5.6-luna")` 호출이 실패함.
- **동작**:
  - ❌ Terra child나 Sol child를 대안으로 생성하지 않습니다.
  - ❌ `model`을 생략한 채 child 생성을 재시도하지 않습니다.
  - ❌ 다른 모델로 escalation 재시도를 하지 않습니다.
  - ✅ **현재 부모 모델(Sol/Terra)이 직접 해당 작업을 수행하여 완료합니다.**
  - "Luna spawn unavailable; continuing directly with parent model." 간결한 로그만 남깁니다.

---

## 🧪 Scenario 10: Parent의 효율적인 결과 확인 (중복 작업 방지)

- **상황**: Luna가 테스트를 성공적으로 통과시키고 코드 수정을 마쳤다고 보고함.
- **부모 모델의 올바른 동작 (Good)**:
  - `git diff` 또는 Luna가 반환한 변경 파일 목록과 테스트 결과 요약을 확인합니다.
  - 지정한 Acceptance Criteria가 충족되었음을 확인하고 즉시 사용자에게 보고합니다.
- **피해야 할 안티패턴 (Bad)**:
  - Luna가 이미 통과한 단위 테스트를 부모가 똑같이 다시 실행함.
  - 변경된 로직을 부모가 처음부터 다시 코딩하여 덮어씀.


