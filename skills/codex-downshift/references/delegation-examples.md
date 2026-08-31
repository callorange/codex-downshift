# Delegation Examples (Good vs. Bad Scenarios)

본 문서는 `codex-downshift` 스킬을 활용할 때 상위 부모 모델(Sol/Terra)이 하위 워커(Luna)에 위임하는 모범 사례(Good)와 피해야 할 안티패턴(Bad)을 비교 정리한 가이드입니다.

---

## 📖 Scenario 1: Docstring & 문서 수정

### ❌ Bad Example (모호하고 판단을 전가함)
```text
Improve the readability of UserService.create_user docstring in user/services.py.
```
**문제점:**
- 무엇이 읽기 어려운지, 어떤 스타일 표준을 따라야 하는지 하위 워커가 다시 판단해야 합니다.
- 불필요한 추론 토큰이 낭비되고 부모의 기대와 다른 형식으로 변경될 위험이 큽니다.

### ✅ Good Example (결정이 완료된 Self-Contained Task)
```text
Role: You are a leaf execution worker.
Goal: Update the docstring of UserService.create_user.
Target: src/services/user_service.py :: UserService.create_user

Decisions already made:
- Follow Google Python Style Guide docstring format.
- Document Args (username: str, email: str), Returns (User instance), and Raises (UserAlreadyExistsError).

Exact change:
Replace the existing docstring with:
"""Creates a new active user in the system.

Args:
    username: Unique username for login.
    email: Verified email address.

Returns:
    User: The newly created User model instance.

Raises:
    UserAlreadyExistsError: If a user with the same email already exists.
"""

Preserve: Function signature, type hints, implementation logic, and existing decorators.
Validation: ruff check src/services/user_service.py
Escalation condition: If signature or error handling differs from above, return NEEDS_PARENT_DECISION.
Worker constraints: Leaf worker only. Do not spawn agents.
```

---

## 🧪 Scenario 2: TDD 기반 신규 유효성 검사 추가

### ❌ Bad Example (요구사항 설계 미흡)
```text
Write tests and add email validation to the registration flow.
```
**문제점:**
- 어떤 이메일 규칙(RFC 표준, 도메인 차단 등)을 적용할지 부모가 결정하지 않았습니다.

### ✅ Good Example (명확한 Acceptance Criteria와 테스트 케이스 명시)
```text
Role: You are a leaf execution worker.
Goal: Add email domain validation for '@company.com' only, and verify with tests.
Target:
- Code: src/validators/email.py :: validate_company_email
- Test: tests/test_email_validator.py

Decisions already made:
- Function: def validate_company_email(email: str) -> bool
- Behavior: Returns True if email ends with '@company.com' (case-insensitive), otherwise raises ValueError("Invalid corporate email").
- Implementation details: Use string.lower().endswith("@company.com").

Exact change:
1. In tests/test_email_validator.py, add:
   - test_valid_company_email(): assert validate_company_email("user@company.com") is True
   - test_invalid_domain_raises(): with pytest.raises(ValueError): validate_company_email("user@other.com")
   - test_case_insensitivity(): assert validate_company_email("User@COMPANY.COM") is True
2. In src/validators/email.py, implement validate_company_email accordingly.

Preserve: Existing validator functions in src/validators/email.py.
Validation: pytest tests/test_email_validator.py
Escalation condition: If existing callers rely on validate_company_email returning False instead of raising ValueError, return NEEDS_PARENT_DECISION.
Worker constraints: Leaf worker only.
```

---

## 🔧 Scenario 3: Deterministic Lint / Type Error Fix

### ❌ Bad Example
```text
Fix all type errors in the repository.
```
**문제점:**
- 범위가 너무 광범위하고 아키텍처적 타입 재정의가 필요할 수 있습니다.

### ✅ Good Example
```text
Role: You are a leaf execution worker.
Goal: Fix strict Optional type error in OrderSummary.total_price.
Target: src/models/order.py :: OrderSummary

Decisions already made:
- items field can be None, but total_price property should return Decimal("0.00") when items is None or empty.
- Import Decimal from decimal.

Exact change:
Modify total_price getter in OrderSummary to:
@property
def total_price(self) -> Decimal:
    if not self.items:
        return Decimal("0.00")
    return sum(item.price for item in self.items)

Validation: mypy src/models/order.py && pytest tests/test_order.py
Escalation condition: If items type definition in OrderSummary is not Optional[List[OrderItem]], return NEEDS_PARENT_DECISION.
```

---

## 🛑 Scenario 4: 하위 워커의 올바른 `NEEDS_PARENT_DECISION` 반환 사례

하위 워커가 작업을 수행하다가 지침 외의 예외 상황을 만났을 때의 올바른 반환 예시입니다:

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
