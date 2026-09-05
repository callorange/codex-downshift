# Delegation Examples & Behavioral Scenarios

본 문서는 `codex-downshift` 스킬의 Gate A Safety ➔ Gate B Decision Authority ➔ Economic Gate 라우팅 사례와 전체 시나리오 인덱스를 제공한다. Child 반환·복구·예외 처리의 상세 사례는 별도 문서를 필요할 때만 읽는다.

**모든 위임 시나리오의 공통 전제**

모든 후보는 Delegation Preparation Test 네 조건을 모두 충족할 때만 위임합니다:

1. Parent의 goal/scope/fixed decisions/acceptance 선확정
2. direct execution에 준하는 준비 분석 불필요
3. 의미 있는 bounded execution 대체
4. preparation plus verification이 대체 실행보다 명확히 작음

네 조건은 필요조건이며, 모두 통과해도 추가 재지시·재작업·검증 부담이 실행 절감분을 상쇄하면 Parent Direct입니다.

---

## 🎯 핵심 시나리오 요약 매트릭스

| 번호 | 시나리오 상황 | 부모 모델 | 라우팅 / 동작 | 기대 결과 |
| :---: | :--- | :---: | :---: | :--- |
| **1** | DB Migration 등 High Consequence 작업 | **Sol/Terra** | 🛑 **Gate A 차단 ➔ Parent Direct** | 구현이 닫혀 있어도 파괴적/운영 변경이므로 부모 직접 수행 |
| **2** | 계약 확정 + 구현 로컬 판단 잔여 | **Sol** | 🟡 **Gate B 후보 ➔ Economic Gate** | 충분한 leverage일 때 `gpt-5.6-terra` medium |
| **3** | 다중 파일 확정 패턴 기계적 적용 | **Sol** | 🟢 **Gate B 후보 ➔ Economic Gate** | 충분한 leverage일 때 `gpt-5.6-luna` |
| **4** | 확정된 docstring / 린트 / 테스트 수정 | **Terra** | 🟢 **Gate B 후보 ➔ Economic Gate** | 충분한 leverage일 때 Luna Light |
| **5** | 구현 판단 잔여 작업 (Terra 부모) | **Terra** | 🛑 **Downshift Only ➔ Terra Direct** | Terra 부모는 Terra child를 부르지 않고 직접 수행 |
| **6** | Child 작업 중 새 설계 판단 직면 | **Child** | 🛑 **`NEEDS_PARENT_DECISION`** | 하위 워커 임의 판단 금지, 미결 사항 보고 후 부모 판단 |
| **7** | Child 외부 부수효과 필요 직면 | **Child** | 🛑 **`NEEDS_PARENT_ACTION`** | git push/deploy 등 외부 권한 작업 시 부모에게 제어권 반환 |
| **8** | 검증 실패 후 1회 복구 실패 또는 복구 부적절로 미시도 | **Child** | 🛑 **`TASK_FAILED`** | 무한 루프 금지. 복구 시도 여부·미시도 사유와 실패 원인을 보고하고 작업트리 보존 |
| **9** | `high`/`xhigh`/`max` reasoning 필요 | **Sol/Terra** | ⚙️ **User Approval Protocol** | 자동 spawn 금지, Parent Direct 우선 검토 후 사용자 승인 요청 |
| **10**| Child spawn 실패 / 런타임 오류 | **Sol/Terra** | 🛡️ **Fail-Closed Fallback** | 타 모델 우회/재시도 없이 부모 모델이 직접 수행 |
| **11**| 정상 완료 보고 수신 | **Sol/Terra** | 🔍 **Claim-Matched Fresh Verification** | `TASK_COMPLETED` 수신 후 Parent 최소 직접 검증 후 보고 |
| **12** | 로직·테스트가 없는 작은 오타 수정 | **Sol/Terra** | 🛑 **Economic Gate ➔ Parent Direct** | capsule/child 비용이 대체 실행량보다 큰 경우 직접 처리; 줄 수 자체가 결정 기준은 아님 |
| **13** | 독립적인 확정 변경의 micro-batch | **Sol/Terra** | 🟢 **Gate A/B ➔ Economic Gate** | 모든 gate 통과 시 Luna Light. 항목별 결과를 보고하고 하나라도 판단이 필요하면 전체 완료로 표시하지 않음 |
| **14** | 구현이 이미 확정되고 위임 경제성이 부족함 | **Sol** | 🛑 **Gate B: Luna 후보 ➔ Economic Gate 탈락** | Terra 후보가 아니며 Luna 경제성도 부족하면 Parent Direct. 다른 모델로 우회하지 않음 |
| **15** | 고정 외부 계약 안의 내부 구현·테스트 루프 | **Sol** | 🟡 **Gate A/B ➔ Economic Gate** | 모든 gate 통과 시 Terra Medium. Parent가 diff와 claim-matched fresh verification 수행 |
| **16** | 최종 routing 결정 표시 | **Sol/Terra** | 👁️ **Routing Notice** | 평가한 결정마다 한 번; Child는 spawn 직전, Parent Direct는 첫 결정적 이유 표시. 전체 capsule 비노출, spawn 실패 시 추가 notice 없음 |

---

> [!NOTE]
> Child terminal state, recovery, exceptional effort와 Parent verification의 상세 흐름은
> [Terminal & Recovery Scenarios](terminal-scenarios.md)를 필요할 때만 읽는다.

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
  Scope:
  - Search: src/services/discount.py, tests/test_discount.py
  - Modify: src/services/discount.py, tests/test_discount.py
  Decisions already made:
  - Fixed API: calculate_discount(order: Order) -> Decimal
  - Policy: VIP=20%, Regular=5%, Holiday Promo adds 5% max up to 25%. Raises InvalidOrderError if total <= 0.
  Delegated authority: Implementation-local architecture and algorithm structure inside discount.py.
  Must not decide: Do not alter the Public API signature, return types, or discount rate percentages.
  Apply: Exact
  Acceptance criteria:
  - [ ] All discount calculation rules pass unit tests.
  - [ ] InvalidOrderError raised on negative or zero total.
  Validation: pytest tests/test_discount.py && ruff check src/services/discount.py
  Recovery policy: At most ONE recovery attempt when appropriate. If recovery is not appropriate or validation still fails, return TASK_FAILED immediately.
  Worker constraints: Leaf worker only. Do not spawn or delegate to other agents or models. Do not perform external side-effects or destructive operations. Do not perform destructive git rollbacks. Stop at one of the four terminal return states.
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
  Scope:
  - Search: src/serializers/*.py, tests/test_serializers.py
  - Modify: src/serializers/*.py, tests/test_serializers.py
  Decisions already made: All 12 serializers must use 'account_id: UUID'.
  Delegated authority: Predetermined execution only. Apply exact renaming.
  Must not decide: Do not add or remove any other fields.
  Apply: All matches within scope
  Rule: Rename only the deprecated `user_id` field to `account_id`.
  Acceptance criteria:
  - [ ] All 12 serializers use account_id.
  - [ ] Search scope 전체를 검사하고 각 대상의 modified 또는 not modified 상태와 사유를 보고한다.
  - [ ] 탐색 완료 근거와 검증 결과를 제공한다. 미처리 대상이나 필요한 증거 누락이 있으면 TASK_COMPLETED로 보고하지 않는다.
  - [ ] pytest tests/test_serializers.py passes.
  Validation:
  - Search scope 전체에 고정 Rule을 적용해 대상·매치 목록을 확인한다. 가능하면 수정 후 재검색해 의도하지 않은 잔여 매치를 확인한다.
  - pytest tests/test_serializers.py && ruff check src/serializers/
  Recovery policy: At most ONE recovery attempt when appropriate. If recovery is not appropriate or validation still fails, return TASK_FAILED immediately.
  Worker constraints: Leaf worker only. Do not spawn or delegate to other agents or models. Do not perform external side-effects or destructive operations. Do not perform destructive git rollbacks. Stop at one of the four terminal return states.
  Completion evidence:
  - Coverage: 각 대상 -> modified 또는 not modified: 사유.
  - Discovery: Search 범위, Rule, 최초 검색 결과, 재검색 결과 또는 재검색하지 못한 이유.
  - Validation: 실행한 검사와 실제 결과. 부분 완료 시 대상별 상태와 Worktree를 보존해 적절한 terminal state로 반환.
  Return protocol: TASK_COMPLETED, TASK_FAILED, NEEDS_PARENT_DECISION, NEEDS_PARENT_ACTION"""
  )
  ```

**이 all-matches 작업의 완료 근거**

완료 보고에는 Search 범위 전체에 고정 Rule을 적용한 검색 결과와 대상별 처리 상태를 포함한다.
수정하지 않은 대상은 이미 규칙을 만족하는 등 사유를 남기고, 가능하면 재검색으로 의도하지 않은 잔여 매치를 확인한다.
테스트 통과만으로 검색 범위 전체의 확인을 대신하지 않는다.

---

## 🧪 Scenario 4: Terra Parent + 기계적 실행 (Luna Child)

- **상황**: Terra가 주력(Parent) 모델인 상태에서, 확정된 docstring 교체와 해당 파일의 lint 검증을 처리해야 함.
- **라우팅 판정**:
  - Gate A 통과, Implementation Closed ➔ **Luna Child**.
- **부모 모델의 동작**:
  - 아래 [완결된 docstring Capsule](#fixed-docstring-capsule)을 이 상황의 고정 변경으로 사용한다.
  - 실제 `message`에는 해당 Capsule의 목표·범위·고정 문자열·권한·검증·worker 제한·반환 계약 전체를 포함한다. 참조 링크만 전달하지 않는다.
  - 호출값은 `model="gpt-5.6-luna"`, `fork_turns="none"`, `reasoning_effort="low"`, `task_name="update_docstrings"`다.

---

### Fixed Docstring Capsule

다음은 Scenario 4에서 사용하는 독립 예시다. 실제 작업에서는 검증된 기존 계약과 고정 문자열로 구체화한다.

```text
TASK CAPSULE
Role: You are a leaf worker.
Goal: Update docstring for UserService.create_user.
Scope:
- Search: src/services/user_service.py :: UserService.create_user
- Modify: src/services/user_service.py :: UserService.create_user
Decisions already made:
- In this example, create_user(self, email: str) -> User validates email, saves a User, and raises ValueError for invalid email.
Delegated authority: Predetermined docstring replacement only.
Must not decide: Do not change behavior, signature, validation, or persistence.
Apply: Exact
Rule: Replace only the target function's docstring with the following text, preserving indentation.
Replacement docstring:
"""Create and persist a user after validating the email.

Args:
    email: Email address for the new user.

Returns:
    The persisted user.

Raises:
    ValueError: If the email is invalid.
"""
Preserve: Signature, implementation, and type hints.
Acceptance criteria: Target docstring matches Replacement docstring after indentation normalization; signature and implementation unchanged; ruff check passes.
Validation: Compare the target docstring with Replacement docstring after indentation normalization; inspect git diff to confirm no signature or implementation changes; run ruff check src/services/user_service.py.
Recovery policy: At most ONE recovery attempt when appropriate. If recovery is not appropriate or validation still fails, return TASK_FAILED immediately.
Worker constraints: Leaf worker only. Do not spawn or delegate to other agents or models. Do not perform external side-effects or destructive operations. Do not perform destructive git rollbacks. Stop at one of the four terminal return states.
Return protocol: TASK_COMPLETED, TASK_FAILED, NEEDS_PARENT_DECISION, NEEDS_PARENT_ACTION
```

---

## 🧪 Scenario 5: Terra Parent + 구현 판단 잔여 (Terra Direct)

- **상황**: Terra가 주력(Parent) 모델인 상태에서, 내부 알고리즘 분석 및 선택이 필요한 로컬 구현 작업 직면.
- **라우팅 판정**:
  - Downshift Only 불변 규칙: Terra Parent는 동일 티어인 Terra Child를 생성할 수 없음 (`Terra Parent ➔ Terra Child` 금지).
  - Luna에게 위임하기에는 구현 판단이 열려 있음.
- **올바른 동작**:
  - ✅ **Terra 부모 모델이 직접 분석하고 구현을 수행합니다.**

### Failure Case: Active Parent identity를 잘못 추정한 Terra Child spawn

- **Failure**: Terra Parent를 Sol이라고 잘못 가정해 Terra Medium Child를 spawn함.
- **Expected**:
  - Terra Parent + Implementation-local decision remains ➔ Parent Direct.
  - Terra Parent + Implementation Closed ➔ Luna candidate.
- **Rule**: Active Parent identity를 추정하지 않는다. Terra Child는 Active Parent가 Sol임을 current runtime/session model 정보로 positive confirmation한 경우에만 허용한다.

---

## 🧪 Scenario 12: 작은 Parent Direct 작업

- **상황**: 단일 파일의 3줄 오타 수정이며 로직·테스트 변경은 없다. 이 예시에서는 capsule 준비·자식 실행·부모 검증 부담이 직접 수정·확인하는 부담보다 크다.
- **판정**: Economic Gate에서 위임 이점이 없으므로 Parent Direct로 처리한다. 파일 수와 줄 수는 예시이며 결정 조건이 아니다.

---

## 🧪 Scenario 13: Luna Micro-batch

- **대상**: 서로 다른 4개 독립 변경(문서 오타, 고정 import 정리, 테스트 fixture 상수 교체, 명시된 docstring 추가)을 Luna Light micro-batch로 묶을 수 있다.
- **판정 기준**: 4개는 이 예시의 구성이지 개수 제한이 아니다. [Micro-batching](../SKILL.md#micro-batching)의 후보 조건을 충족해야 한다.
- **실제 위임 조건**: 묶음 처리의 이점만으로 위임하지 않으며, Gate A → Gate B → Economic Gate를 모두 통과해야 한다.
- **결과 보고**: 결과는 항목별 checkmark로 보고한다.
- **판단 필요 시**: 하나라도 판단이 필요하면 전체를 TASK_COMPLETED로 표시하지 않는다.
- **구별할 작업**: 12개 serializer의 `user_id → account_id`처럼 하나의 고정 규칙을 반복하는 작업은 micro-batch가 아니라 repeated fixed-rule batch다.

---

## 🧪 Scenario 14: Terra 위임이 경제적으로 나쁜 경우

- **상황**: Sol이 이미 내부 알고리즘을 결정했고 한 함수와 결정적 테스트만 남았다면 Terra 준비·검증 오버헤드가 실행량과 비슷하다.
- **Gate B — 후보 선택**: 구현 방법이 이미 확정되었으므로 Terra 후보가 아니다. Gate A 통과 후 Luna 후보로 경제성을 평가한다.
- **Economic Gate — 위임 여부**: Luna 준비·검증 부담도 대체 실행량보다 명확히 작지 않으면 Parent Direct다. 이 예시는 그 조건을 충족하지 못하는 경우이며, gate 실패 후 다른 모델로 우회하지 않는다.
- **Parent Direct 선택 후**: Parent Direct가 선택되면 delegation 목적의 Capsule은 emit하지 않고 Child도 spawn하지 않으며, Sol Parent가 직접 구현·검증한다.

---

## 🧪 Scenario 15: Terra 위임이 경제적인 경우

- **상황·후보 판단**: 외부 API 계약과 acceptance는 고정됐지만 여러 모듈의 내부 자료구조 선택·구현·테스트 루프가 남은 Sol 작업은 Gate A/B를 통과할 수 있다.
- **위임·검증**: 짧은 공개 표시 후 Terra Medium Child로 위임하고 Parent가 diff와 claim-matched fresh verification을 수행한다.

---

## 🧪 Scenario 16: Routing notice

**적용 조건·횟수**

Gate A → Gate B → Economic Gate routing 평가를 수행했으면, 부모는 최종 결정을 정확히 한 번 짧게 표시한다.

**Child delegation**

Child delegation은 실제 spawn 직전에 `[codex-downshift] → Luna (low) | normalize_headers | fixed mechanical rule`처럼 표시한다.

**Parent Direct**

Parent Direct는 `[codex-downshift] → Parent Direct | update_auth_policy | Gate A: high-consequence 작업`처럼 첫 결정적 gate 또는 이유만 표시한다.

**노출 제한·spawn 실패**

전체 capsule은 노출하지 않으며, spawn 실패 시에도 추가 routing notice를 출력하지 않고 Parent가 직접 수행한다.

---

## 🧪 A–F: Compact routing examples

- **A Luna**: non-exhaustive Examples가 있어도 Search scope 전체의 문서 규칙을 all matches로 적용한다. 첫 예시에서 멈추지 않는다.
- **B Parent Direct**: 작은 함수 1개와 pytest 한 번이 남은 작업에서 capsule 준비·검증 부담이 대체 실행량보다 명확히 작지 않으면 Parent Direct다. 함수 수나 검증 횟수만으로 결정하지 않는다.
- **C Luna micro-batch**: 위 Scenario 13의 서로 다른 4개 독립 변경을 같은 Luna Light로 itemize한다. 개수는 예시이며 후보 조건과 모든 gate를 충족해야 한다.
- **D Poor Terra**: Sol이 구현 방법을 이미 상세히 고정했다면 남은 구현 선택이 없어 Gate B에서 Terra 후보가 아니다. Gate A를 통과한 Luna 후보의 실제 위임 여부는 Economic Gate에서 별도로 판단한다.
- **E Good Terra**: 외부 API contract는 고정됐지만 자료구조 선택·구현·테스트 루프가 남으면 Terra가 local criteria로 판단한다.
- **F Routing notice**: `[codex-downshift] → Luna (low) | normalize_headers | fixed mechanical rule` 또는 `[codex-downshift] → Parent Direct | single_literal | Economic Gate: delegation overhead`를 최종 routing 결정마다 한 번 표시한다.
