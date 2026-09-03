# Delegation Examples & Behavioral Scenarios

본 문서는 `codex-downshift` 스킬의 2단계 라우팅 파이프라인(Gate A Safety ➔ Gate B Decision Authority), 4대 반환 규격 및 예외 처리 정책을 검증하기 위한 11대 핵심 실전 시나리오 가이드입니다.

---

## 🎯 핵심 시나리오 요약 매트릭스

| 번호 | 시나리오 상황 | 부모 모델 | 라우팅 / 동작 | 기대 결과 |
| :---: | :--- | :---: | :---: | :--- |
| **1** | DB Migration 등 High Consequence 작업 | **Sol/Terra** | 🛑 **Gate A 차단 ➔ Parent Direct** | 구현이 닫혀 있어도 파괴적/운영 변경이므로 부모 직접 수행 |
| **2** | 계약 확정 + 구현 로컬 판단 잔여 | **Sol** | 🟡 **Gate B ➔ Terra Child 위임** | `gpt-5.6-terra` child 생성 (`reasoning_effort="medium"`) |
| **3** | 다중 파일 확정 패턴 기계적 적용 | **Sol** | 🟢 **Gate B ➔ Luna Child 위임** | `gpt-5.6-luna` child 생성 (파일 수와 무관하게 Luna) |
| **4** | 확정된 docstring / 린트 / 테스트 수정 | **Terra** | 🟢 **Gate B ➔ Luna Child 위임** | `gpt-5.6-luna` child 생성 (`reasoning_effort="low"` [1.00×]) |
| **5** | 구현 판단 잔여 작업 (Terra 부모) | **Terra** | 🛑 **Downshift Only ➔ Terra Direct** | Terra 부모는 Terra child를 부르지 않고 직접 수행 |
| **6** | Child 작업 중 새 설계 판단 직면 | **Child** | 🛑 **`NEEDS_PARENT_DECISION`** | 하위 워커 임의 판단 금지, 미결 사항 보고 후 부모 판단 |
| **7** | Child 외부 부수효과 필요 직면 | **Child** | 🛑 **`NEEDS_PARENT_ACTION`** | git push/deploy 등 외부 권한 작업 시 부모에게 제어권 반환 |
| **8** | 1회 복구 시도 후에도 검증 실패 | **Child** | 🛑 **`TASK_FAILED`** | 무한 루프 금지, 작업트리 보존 후 실패 상세 보고 |
| **9** | `high`/`xhigh`/`max` reasoning 필요 | **Sol/Terra** | ⚙️ **User Approval Protocol** | 자동 spawn 금지, Parent Direct 우선 검토 후 사용자 승인 요청 |
| **10**| Child spawn 실패 / 런타임 오류 | **Sol/Terra** | 🛡️ **Fail-Closed Fallback** | 타 모델 우회/재시도 없이 부모 모델이 직접 수행 |
| **11**| 정상 완료 보고 수신 | **Sol/Terra** | 🔍 **Claim-Matched Fresh Verification** | `TASK_COMPLETED` 수신 후 Parent 최소 직접 검증 후 보고 |

---

## 🧪 Scenario 1: High Consequence 작업 (Gate A 차단)

- **상황**: DB 테이블 컬럼에 `NOT NULL` 제약조건을 추가하고 기본값을 채우는 migration SQL과 스크립트 작성이 완전히 확정됨.
- **라우팅 판정**:
  - Semantic Closed + Implementation Closed이지만, 데이터 손실 위험 및 락(Lock) 유발 가능성이 있는 **High Consequence/Blast Radius** 작업임.
  - **Gate A (Delegation Safety Gate)**에서 탈락.
- **올바른 동작**:
  - ❌ Luna 또는 Terra로 위임하지 않음.
  - ✅ **부모 모델(Sol/Terra)이 직접 마이그레이션 코드를 작성하고 검증합니다.**

---

## 🧪 Scenario 2: Sol Parent + Implementation-Local 판단 잔여 (Terra Child)

- **상황**: Sol 부모 모델이 주문 할인 계산기 API 명세(입출력 타입, 에러 조건, 할인율 정책)를 확정했으나, 내부 알고리즘(Strategy 패턴 vs 함수형 파이프라인)의 선택은 하위 워커에게 맡기고자 함.
- **라우팅 판정**:
  - Gate A 통과 (Bounded, Verifiable, 저위험 로컬 코드)
  - Gate B: Semantic/API Closed + **Implementation-Local Decision Remains** ➔ **Terra Child**.
- **부모 모델의 동작**:
  ```text
  spawn_agent(
      model = "gpt-5.6-terra",
      fork_turns = "none",
      reasoning_effort = "medium",
      task_name = "implement_discount_calculator",
      message = """TASK CAPSULE
  Role: You are a leaf worker.
  Goal: Implement OrderDiscountCalculator satisfying the fixed API contract.
  Target / Scope: src/services/discount.py, tests/test_discount.py
  Decisions already made:
  - Fixed API: calculate_discount(order: Order) -> Decimal
  - Policy: VIP=20%, Regular=5%, Holiday Promo adds 5% max up to 25%. Raises InvalidOrderError if total <= 0.
  Delegated authority: Implementation-local architecture and algorithm structure inside discount.py.
  Must not decide: Do not alter the Public API signature, return types, or discount rate percentages.
  Acceptance criteria:
  - [ ] All discount calculation rules pass unit tests.
  - [ ] InvalidOrderError raised on negative or zero total.
  Validation: pytest tests/test_discount.py && ruff check src/services/discount.py
  Recovery policy: At most ONE recovery attempt when appropriate. If recovery is not appropriate or validation still fails, return TASK_FAILED immediately.
  Worker constraints: Leaf worker only. Do not spawn other agents.
  Return protocol: TASK_COMPLETED, TASK_FAILED, NEEDS_PARENT_DECISION, NEEDS_PARENT_ACTION"""
  )
  ```

---

## 🧪 Scenario 3: Sol Parent + 확정된 다중 파일 기계적 수정 (Luna Child)

- **상황**: 12개 직렬화 모듈의 deprecated 필드명을 신규 명세에 맞춰 교체하고, 기존 테스트 4개를 업데이트해야 함.
- **라우팅 판정**:
  - 파일 수가 12개로 많지만, 변환 패턴과 대상이 완벽히 정형화됨 (Implementation Closed).
  - *파일 수가 많다는 이유로 Terra로 올리지 않음.* ➔ **Luna Child**.
- **부모 모델의 동작**:
  ```text
  spawn_agent(
      model = "gpt-5.6-luna",
      fork_turns = "none",
      reasoning_effort = "low",
      task_name = "batch_update_serializer_fields",
      message = """TASK CAPSULE
  Role: You are a leaf worker.
  Goal: Rename deprecated field 'user_id' to 'account_id' across 12 serializers and update tests.
  Target / Scope: src/serializers/*.py, tests/test_serializers.py
  Decisions already made: All 12 serializers must use 'account_id: UUID'.
  Delegated authority: Predetermined execution only. Apply exact renaming.
  Must not decide: Do not add or remove any other fields.
  Acceptance criteria:
  - [ ] All 12 serializers use account_id.
  - [ ] pytest tests/test_serializers.py passes.
  Validation: pytest tests/test_serializers.py && ruff check src/serializers/
  Recovery policy: At most ONE recovery attempt when appropriate. If recovery is not appropriate or validation still fails, return TASK_FAILED immediately.
  Return protocol: TASK_COMPLETED, TASK_FAILED, NEEDS_PARENT_DECISION, NEEDS_PARENT_ACTION"""
  )
  ```

---

## 🧪 Scenario 4: Terra Parent + 기계적 실행 (Luna Child)

- **상황**: Terra가 주력(Parent) 모델인 상태에서, 확정된 Docstring 작성 및 단위 테스트 린트 수정을 처리해야 함.
- **라우팅 판정**:
  - Gate A 통과, Implementation Closed ➔ **Luna Child**.
- **부모 모델의 동작**:
  ```text
  spawn_agent(
      model = "gpt-5.6-luna",
      fork_turns = "none",
      reasoning_effort = "low",
      task_name = "update_docstrings",
      message = "..."
  )
  ```

---

## 🧪 Scenario 5: Terra Parent + 구현 판단 잔여 (Terra Direct)

- **상황**: Terra가 주력(Parent) 모델인 상태에서, 내부 알고리즘 분석 및 선택이 필요한 로컬 구현 작업 직면.
- **라우팅 판정**:
  - Downshift Only 불변 규칙: Terra Parent는 동일 티어인 Terra Child를 생성할 수 없음 (`Terra Parent ➔ Terra Child` 금지).
  - Luna에게 위임하기에는 구현 판단이 열려 있음.
- **올바른 동작**:
  - ✅ **Terra 부모 모델이 직접 분석하고 구현을 수행합니다.**

---

## 🧪 Scenario 6: Child 작업 중 새 설계 판단 직면 (`NEEDS_PARENT_DECISION`)

하위 워커(Luna 또는 Terra)가 구현 중 기존 레거시 코드와의 심각한 호환성 충돌이나 모호한 요구사항을 마주했을 때:

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

## 🧪 Scenario 8: Validation 복구 한도 초과 또는 미시도 실패 (`TASK_FAILED`)

- **상황 A (1회 복구 후 실패)**: Child가 코드를 수정한 후 테스트를 실행했으나 실패 ➔ 1회 복구를 시도하여 수정했으나 의존성 충돌로 재실행 역시 실패함.
- **상황 B (복구 부적절 실패)**: 외부 테스트 인프라 다운, DB 서버 연결 불가 등 Child가 자체 구현으로 해결할 수 없는 환경 실패 발생.
- **올바른 동작**:
  - 상황 A: 1회 recovery 실패 후 즉시 `TASK_FAILED` 반환 (`Attempted: YES`).
  - 상황 B: 억지로 recovery를 수행하지 않고 즉시 `TASK_FAILED` 반환 (`Attempted: NO`, 사유 기재).
  - `git reset --hard` 등으로 작업트리를 자의적으로 파괴하지 않고 상태를 보존하여 부모에게 인계.
```text
TASK_FAILED

Modified files:
- src/services/payment.py
- tests/test_payment.py

Validation:
- pytest tests/test_payment.py -> FAILED
  E   TypeError: unsupported operand type(s) for +: 'Decimal' and 'float'

Recovery:
- Attempted: YES
- 1 recovery attempt executed to cast float to Decimal in calculate_tax, but mock fixture returned unexpected float format.

Remaining blocker:
Third-party gateway client fixture in tests/conftest.py returns mock data as float, conflicting with strict Decimal typing in payment service.

Worktree:
- Current changes preserved for Parent review. No automatic reset/revert/clean performed.
```

---

## 🧪 Scenario 9: High Reasoning Effort 필요 상황 (승인 프로토콜)

- **상황**: Sol 부모 모델이 로컬 코드베이스의 복잡한 비선형 의존성을 분석해야 하는 구현 작업을 마주하여 `medium`으로는 부족하고 `high` reasoning이 필요하다고 판단함.
- **올바른 동작 흐름**:
  1. **Parent Direct 우선 평가**: Sol이 직접 수행하는 것이 더 빠른지 검토.
  2. **실익 확인**: 작업 범위가 방대하여 Terra Child (`high`)로 위임하는 실익이 명백함을 확인.
  3. **사용자 승인 요청 (In-Chat)**:
     > *"본 작업은 4개 모듈의 비동기 락 의존성을 깊이 있게 분석해야 하므로 `gpt-5.6-terra` (high reasoning effort) 위임이 필요합니다. high reasoning effort 사용을 승인하시겠습니까?"*
  4. 사용자가 승인하면 `reasoning_effort="high"`로 spawn. 미승인 시 Sol이 직접 수행.

---

## 🧪 Scenario 10: Child Spawn 실패 (Fail-Closed Fallback)

- **상황**: 런타임 제약 또는 일시적 API 오류로 `spawn_agent(model="gpt-5.6-terra")` 호출이 실패함.
- **올바른 동작 (Fail-Closed)**:
  - ❌ `gpt-5.6-luna`로 우회 spawn하지 않음.
  - ❌ `model`을 생략한 child를 재시도하지 않음.
  - ✅ **부모 모델(Sol)이 해당 작업을 직접 이어서 수행하여 마무리합니다.**

---

## 🧪 Scenario 11: Parent의 Claim-Matched Fresh Verification

- **상황**: Luna가 단위 테스트 및 린트를 통과하고 `TASK_COMPLETED`를 반환함.
- **부모 모델의 올바른 동작**:
  1. `git diff`를 열어 실제 변경된 코드가 Acceptance에 부합하는지 확인.
  2. **Fresh Verification 직접 실행**: 회귀 테스트 `pytest tests/test_email_validator.py`를 직접 실행하여 `PASSED` 증거 확보.
  3. **정직하고 정확한 완료 보고**:
     > *"이메일 유효성 검증 로직이 성공적으로 구현되었습니다. 변경된 회귀 테스트를 부모 모델이 직접 재검증하여 통과를 확인했습니다 (Child는 전체 린트 통과를 보고함)."*

