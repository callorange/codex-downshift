# codex-downshift — Project Specification

> Status: v0.1.3 released / Unreleased semantic-decision hardening implemented / Runtime verification in progress
> Target: OpenAI Codex  
> Artifact purpose: Antigravity 등 코딩 에이전트가 이 문서를 기반으로 프로젝트를 생성·구현할 수 있도록 하는 구현 명세

---

## 1. 프로젝트 이름

### Repository name

`codex-downshift`

### GitHub description

**English**

> A lightweight Codex skill that keeps Sol or Terra as the parent and offloads (downshifts) fully specified execution tasks to Luna (`gpt-5.6-luna`) to reduce usage.

**한국어 설명**

> Sol 또는 Terra를 부모 모델로 유지하면서, 명확하게 정의된 실행 작업만 Luna (`gpt-5.6-luna`)로 다운시프트(위임)해 Codex 사용량을 절감하는 경량 Skill.

### 이름 선정 이유

이 프로젝트는 단순한 `model router`나 특정 모델에만 종속된 도구가 아니다.

- 사용자가 선택한 Sol/Terra를 다른 모델로 교체하지 않는다.
- 작업마다 "최적 모델"을 찾는 복잡한 라우팅이 목적이 아니다.
- 상위 모델의 판단이 끝난 실행 작업만 하위 경량 워커로 안전하게 다운시프트(하향 위임)한다.
- 하위 워커에서 Terra/Sol로 자동 escalation하지 않는다.

따라서 `downshift`가 상위 모델의 판단 통제 하에 실행 비용을 낮추는 실제 역할을 가장 정확하게 표현한다.

---

## 2. 프로젝트 목표

`codex-downshift`는 사용자가 Codex에서 Sol 또는 Terra를 주력 모델로 사용할 때,
이미 판단이 끝나고 범위가 명확해진 실행 작업을 Luna (`gpt-5.6-luna`) 서브에이전트에 넘겨
상위 모델의 사용량을 줄이는 경량 Codex Skill이다.

핵심 질문은 하나다.

> **현재 부모 모델이 처리하려는 하위 작업 중, 추가적인 중요한 판단 없이 Luna가 안전하게 실행할 수 있는 작업이 있는가?**

있다면 Luna에 위임한다.

없다면 현재 부모 모델이 그대로 처리한다.

---

## 3. 해결하려는 문제

Sol은 높은 품질의 추론과 구현 능력을 제공하지만 Codex 사용량 제한을 빠르게 소비할 수 있다.

특히 다음과 같은 개발 과정에서는 실제 코드 변경량보다 반복 추론과 실행 과정의 비용이 커질 수 있다.

- TDD의 RED → GREEN → REFACTOR 반복
- 명확한 테스트 코드 작성
- 이미 결정된 구현의 실제 코드 작성
- 반복적인 코드 수정
- docstring/문서 수정
- lint/type 오류 수정
- 특정 테스트 및 검증 명령 반복 실행

많은 경우 상위 모델은 이미 다음 작업을 완료한 상태다.

1. 사용자의 의도 이해
2. 관련 코드 조사
3. 구현 방향 결정
4. 수정할 파일/심볼 결정
5. 동작과 acceptance criteria 결정
6. 검증 방법 결정

이 상태에서 실제 수정까지 계속 Sol이 수행하면 비싼 모델의 사용량을 기계적인 실행에 소비하게 된다.

이 프로젝트는 그 마지막 실행 단계를 Luna에 안전하게 offload하는 것을 목표로 한다.

---

## 4. 핵심 설계 원칙

### 4.1 사용자가 선택한 부모 모델을 존중한다

부모 모델은 다음 사항의 최종 책임자다.

- 요구사항 해석
- 사용자 의도 파악
- 설계
- 아키텍처 판단
- 동작 결정
- 모호성 해소
- 작업 분해
- Luna에 전달할 구체적인 작업 정의
- 최종 결과 판단

Skill은 사용자가 선택한 부모 모델을 자동으로 교체하지 않는다.

---

### 4.2 하향 위임만 허용한다

MVP의 자동 위임 관계는 다음과 같다.

```text
Sol parent
 ├─ 명확한 실행 작업 → Luna
 └─ 나머지           → Sol

Terra parent
 ├─ 명확한 실행 작업 → Luna
 └─ 나머지           → Terra

Luna parent
 └─ 자동 위임 없음
```

자동으로 다음 동작을 해서는 안 된다.

```text
Sol   → Terra
Terra → Sol
Luna  → Terra
Luna  → Sol
```

Sol과 Terra 중 어느 모델을 주력으로 사용하는지는 작업 난이도뿐 아니라 사용자의 선호와 목적에 따라 달라질 수 있다.

이 Skill은 그 선택에 개입하지 않는다.

---

### 4.3 Luna는 항상 Leaf Worker다

Luna worker는 다른 agent를 생성하거나 호출해서는 안 된다.

금지:

- `spawn_agent`
- 다른 worker로 delegation
- Terra 호출
- Sol 호출
- 자동 escalation
- 작업 범위 확장

Luna가 작업 도중 새로운 판단이 필요하다고 발견하면 스스로 해결 범위를 넓히지 않는다.

다음 형태로 부모에게 반환한다.

```text
NEEDS_PARENT_DECISION

Unresolved:
<결정되지 않은 사항>

Why it blocks execution:
<현재 작업을 그대로 진행할 수 없는 이유>

Relevant:
<관련 파일 / 클래스 / 함수 / 심볼>
```

그 뒤 원래 부모 모델이 판단한다.

---

### 4.4 Delegation은 기본 워크플로가 아니라 실행 최적화다

서브에이전트를 사용할 수 있다는 이유만으로 호출해서는 안 된다.

다음 요청에는 기본적으로 Luna를 호출하지 않는다.

- 계획만 작성하는 요청
- 설명 요청
- 아이디어 논의
- brainstorming
- architecture 설계
- 코드 리뷰만 요청한 경우
- 요구사항이 아직 불명확한 경우
- root cause를 찾아야 하는 디버깅
- 새로운 API/비즈니스 동작을 결정해야 하는 작업

예:

```text
"이 기능의 구현 계획을 세워라."
```

동작:

```text
Sol/Terra
  ↓
직접 조사 및 계획 작성
  ↓
종료
```

Luna를 호출하지 않는다.

---

## 5. 지원 부모 모델

### Sol

Sol을 사용 중이면:

- 모든 핵심 판단은 Sol이 담당한다.
- 안전하고 명확하게 정의된 실행 작업만 Luna에 위임한다.
- 그 외 작업은 Sol이 직접 수행한다.

### Terra

Terra를 사용 중이면:

- 모든 핵심 판단은 Terra가 담당한다.
- 안전하고 명확하게 정의된 실행 작업만 Luna에 위임한다.
- 그 외 작업은 Terra가 직접 수행한다.

### Luna

Luna를 직접 사용 중이면:

- Skill은 자동 delegation을 하지 않는다.
- Terra 또는 Sol을 자동으로 호출하지 않는다.
- 사용자가 Luna를 선택한 의도를 그대로 존중한다.

### 기타 모델

알 수 없거나 명시적으로 지원하지 않는 부모 모델에서는 기본적으로 delegation을 수행하지 않는다.

---

## 6. MVP 파일 구조

MVP는 최대한 작게 유지한다.

```text
skills/
└─ codex-downshift/
   ├─ SKILL.md
   └─ references/
      ├─ delegation-examples.md
      └─ task-capsule-template.md
```

### 필요하지 않은 것

MVP에는 다음이 필요하지 않다.

- `config.toml`
- 별도 worker agent TOML
- Python runtime
- daemon
- UI
- telemetry
- quota tracker
- 모델별 고정 reasoning 설정
- 설치용 복잡한 wrapper

Codex의 기본 Multi-Agent 기능으로 Luna를 동적으로 생성한다.

---

## 7. Luna 동적 생성 및 Downshift Spawn Contract

별도의 custom worker agent를 미리 정의하지 않는다.

부모 모델이 위임 시점에 Codex의 native subagent 기능을 사용하며, 모델 상속을 방지하기 위해 다음 매개변수를 반드시 명시한다.

```text
spawn_agent(
    model = "gpt-5.6-luna",          # [필수] 부모 모델 상속 방지
    fork_turns = "none",             # [필수] 부모 대화 기록 제외, fresh child 생성
    reasoning_effort = "medium",     # [필수] 기본값은 medium, 작업에 따라 low/medium/high 명시
    task_name = "<task_name>",       # [권장] 명확한 작업 식별자
    message = "<Minimal Self-Contained Task Capsule>"
)
```

### 7.1 Fail-Closed Fallback Invariant (불변 규칙)

`gpt-5.6-luna` child 생성이 지원되지 않거나 호출 실패 시:
- Terra 또는 Sol child로 fallback하지 않는다.
- `model`을 생략한 채 child 생성을 재시도하지 않는다.
- 다른 subagent로 자동 escalation하지 않는다.
- **현재 부모 모델(Sol/Terra)이 해당 작업을 직접 계속 수행한다.**

### 7.2 Parent 중복 작업 방지

Luna가 작업을 성공적으로 완료하면 부모 모델은 위험도에 비례한 최소 Acceptance 확인만 수행하며, 동일 테스트 반복이나 코드 재작성을 하지 않는다.

### 7.3 Luna Reasoning Effort 선택 정책

- **기본값**: `medium`
- **Low**: 정확한 문자열/코드 교체, 매우 기계적인 반복 수정, 판단이 전혀 필요 없는 작은 bounded task
- **Medium (기본값)**: 일반적인 명확한 구현 작업, 명확히 정의된 테스트 작성 + 구현, 제한된 범위의 코드 탐색
- **High**: 범위와 동작은 확정되어 있고 여러 파일 수정 또는 로컬 코드 탐색이 필요하지만 새로운 의미적/아키텍처 판단은 불필요한 작업
- **상한 규칙**: `xhigh` 또는 `max`를 자동 사용하지 않으며, High보다 더 강한 reasoning이 필요해 보이면 reasoning effort를 무한정 올리지 말고 부모 모델이 직접 수행한다. (부모 모델의 reasoning effort를 암묵적으로 상속하지 않고 반드시 명시)
- **권한 불변 규칙**: `low`, `medium`, `high`는 확정된 작업의 탐색·구현 복잡도만 나타내며, 새로운 요구사항 해석, 제품·아키텍처·공개 API·호환성 정책 결정, 문서 범주 변경 또는 Task Capsule에 없는 동작 선택 권한을 추가하지 않는다. `high`에서도 새로운 의미적 판단이 필요하면 `NEEDS_PARENT_DECISION`을 반환한다.

---

## 8. Delegation 가능 조건 및 3대 안전성 신호 (Safety Signals)

Luna에 위임하려면 다음 **기본 필수 요건**을 만족해야 하며, 보조적으로 **3대 안전성 신호 체크리스트**를 확인한다. (숫자 기반 score engine은 사용하지 않음)

### 8.1 핵심 판별 질문 및 필수 전제조건 (Baseline Requirements)

> **"Luna가 이 작업을 수행하려면 내가 이미 완료한 중요한 reasoning을 다시 해야 하는가?"**

위임 후보가 되려면 다음 조건을 대부분 만족해야 한다:

- 수정 목적이 명확하다.
- 대상 파일 또는 심볼을 충분히 특정할 수 있다.
- 기대 동작이 이미 결정되어 있다.
- 중요한 구현 결정이 부모에서 끝났다.
- 다른 합리적인 구현 선택지 중 하나를 Luna가 선택할 필요가 없다.
- acceptance criteria가 명확하다.
- 결과를 검증할 방법이 있다.
- 실패해도 범위가 제한적이고 부모가 결과를 검토할 수 있다.

### 8.2 Semantic Decision Closure

Downshift는 미완성된 의미적 판단을 Luna에 넘기는 수단이 아니다. 부모는 spawn 전에 결과의 의미, 동작, 범주 및 외부 계약을 확정하고, Luna에는 그 결정을 적용하고 검증하는 실행 판단만 남긴다.

제품 의미·정책·범주·공개 계약 선택, 여러 합리적인 결과 중 하나의 선택, PRD·ADR·대화 기록의 새로운 요구사항 해석, 구분된 범주의 병합·분할 판단 또는 `자연스럽게`, `적절하게`, `알아서` 같은 주관적 완료 기준이 필요하면 Task Capsule은 준비되지 않은 상태다. 부모가 결정을 완료해 Capsule을 구체화하거나 작업을 직접 수행한다.

파일 탐색, patch 적용, 코드 조립 및 확정된 동작 안에서의 테스트 실패 분석 같은 bounded execution reasoning은 선택한 `low`, `medium`, `high` 범위에서 허용된다.

### 8.3 3대 안전성 보조 신호 (Safety Signals Checklist)

1. **Coupling (결합도)**:
   - **Luna 적합**: 수정 범위가 국소적이고, 영향 범위를 명확하게 특정할 수 있으며, 타 컴포넌트까지 판단할 필요가 없음.
   - **Parent 직접**: 여러 서브시스템에 강하게 결합되어 있거나 변경 영향 범위를 확신하기 어려워 추가 판단이 필요한 경우.
2. **Verification (검증 가능성)**:
   - **Luna 적합**: 특정 테스트, lint, typecheck, deterministic command 등으로 결과를 결정적으로 검증 가능.
   - **Parent 직접**: 검증 방법이 모호하거나 결과 판단이 주관적인 경우.
3. **Consequence (실패 영향도 / Blast Radius)**:
   - **Luna 적합**: 실패 영향이 제한적이고, 변경을 쉽게 되돌릴 수 있으며(가역적), 부모가 결과를 즉시 검토 가능.
   - **Parent 직접**: 보안, 권한, 데이터 손실, 호환성 파괴, 마이그레이션, 외부 공개 API, 운영 환경 등 실패 비용이 큰 작업.

---

## 9. 좋은 Luna 작업 예시

- 정확한 문자열/문서/docstring 교체
- 이미 결정된 구현을 코드로 작성
- 구체적인 acceptance criteria 기반 테스트 작성
- 동일 패턴의 반복 수정
- 명확한 범위의 rename
- 결정된 API 변경에 따른 import/reference 수정
- deterministic lint/type 오류 수정
- 특정 테스트 명령 실행 및 결과 보고
- 이미 결정된 코드 패턴을 여러 파일에 동일하게 적용
- 부모가 정확한 코드 또는 pseudocode까지 결정한 구현

---

## 10. Luna에 넘기면 안 되는 작업

- 사용자가 원하는 동작 자체를 해석해야 하는 작업
- 버그 원인을 처음부터 찾아야 하는 작업
- architecture 선택
- API contract 결정
- 데이터 모델 결정
- 호환성 정책 결정
- migration 전략 판단
- 보안/권한 정책 결정
- 여러 구현 대안의 trade-off 판단
- 광범위한 refactoring 범위 결정
- 문제 해결을 위해 예상하지 못한 추가 영역까지 수정해야 하는 작업

---

## 11. 가장 중요한 위임 원칙

부모 모델은 Luna에게 **목표만 넘기지 않는다.**

부모가 이미 판단한 내용은 Luna가 다시 추론하게 하지 말고 task capsule에 포함한다.

### 나쁜 예

```text
Improve the readability of FooService.create_user's docstring.
```

문제:

Luna가 다시 다음을 판단해야 한다.

- 무엇이 읽기 어려운가?
- 어떤 형식이 적절한가?
- 내용을 어떻게 바꿀 것인가?
- 어느 정도 범위까지 고칠 것인가?

---

### 좋은 예

```text
Target:
foo/services.py::FooService.create_user

Change:
현재 docstring을 아래 내용으로 정확히 교체한다.

<replacement text>

Preserve:
- 함수 구현
- type hint
- 다른 docstring
- 외부 동작

Validation:
ruff check foo/services.py

Do not:
- 관련 없는 표현 수정
- 다른 파일 수정
- 추가적인 설계 판단

If a new semantic or behavioral decision is required:
return NEEDS_PARENT_DECISION.
```

---

## 12. Task Capsule 형식 및 Validation Budget / Recovery Limit

Luna에게 넘기는 prompt는 가능한 경우 다음 구조를 사용한다.

부모는 prompt 작성 전에 다음을 확인한다. 이 체크는 child message에 포함하지 않는다.

- 결과의 의미와 동작이 부모에서 확정되었는가?
- Luna가 선택해야 할 제품·정책·범주 결정이 남아 있지 않은가?
- 서로 다른 두 결과가 모두 정답일 수 있다면 허용 범위가 명시되었는가?
- 정확한 표현이나 분류가 계약이라면 `Exact change`가 제공되었는가?
- acceptance criteria가 형식뿐 아니라 의미적 불변조건도 검증하는가?

```text
Role:
You are a leaf execution worker.

Goal:
<이 작업으로 달성해야 하는 결과>

Target:
<파일 / 클래스 / 함수 / 테스트 / 심볼>

Decisions already made:
<부모 모델이 이미 결정한 내용>

Exact change:
<정확한 결과 형태가 계약이면 필수: final text, before/after 또는 결정적인 변환 규칙>

Preserve:
<유지해야 하는 기존 동작/내용>

Do not touch:
<명시적인 범위 제한>

Acceptance criteria:
<의미·범주·동작·호환성 불변조건과 기계적 검증 결과>

Validation:
<실행할 테스트 / lint / typecheck / 명령 (필요한 최소한만)>

Recovery policy:
If validation fails due to your own minor implementation error, you may attempt at most ONE recovery. If it still fails, return failure details immediately.

Escalation condition:
- If new semantic/behavioral/architectural judgment is needed: return NEEDS_PARENT_DECISION.
- If external side-effects (git push, deploy, secrets, elevated actions) are needed: return NEEDS_PARENT_ACTION.

Worker constraints:
- Do not spawn or delegate to other agents.
- Do not invoke a more capable model.
- Do not perform external side-effects or destructive operations.
- Stop when the acceptance criteria are satisfied.
```

정확한 문구, 범주 구분, literal, 설정값, import 또는 고정 코드 블록처럼 결과 형태가 계약이면 `Exact change`를 반드시 채운다. 구현 코드를 Luna가 작성해도 되는 작업은 전체 코드를 중복하지 않아도 되지만 signature, algorithm, error behavior, side effect, edge case 및 test case를 확정한다.

Acceptance criteria에는 테스트·lint 같은 형식 검증뿐 아니라 유지해야 할 의미, 범주, 동작 및 호환성 불변조건을 포함한다. 의미적 계약과 무관한 선택 필드는 억지로 채우지 않는다.

중요한 것은 **부모의 전체 CoT나 긴 대화를 넘기는 것이 아니라, Luna가 부모의 reasoning을 다시 재구성하지 않아도 되는 최소한의 완결된(Minimal Self-Contained) 지침**을 만드는 것이다.

### 12.1 Validation Budget & 최대 1회 Recovery 규칙
- Acceptance criteria를 입증하는 데 필요한 최소한의 validation만 수행한다.
- Validation 실패가 Luna 자신의 bounded 구현 실수이고 수정 방법이 명확한 경우에 한해 **최대 1회의 recovery attempt만 허용**한다.
- 1회 복구 후에도 실패하면 계속 반복하지 않고 현재 상태와 실패 원인을 부모에게 반환한다.
- 새로운 의미적/아키텍처 판단이 필요한 경우에는 recovery를 시도하지 않고 즉시 `NEEDS_PARENT_DECISION`을 반환한다.

### 12.2 External Side Effect 및 Permission Boundary
Luna worker는 `git push`, remote branch 변경, merge, deploy, publish, release, 외부 메시지 전송, production 변경, secret 작업 등 외부 부수효과 작업을 직접 수행할 수 없다. 이러한 작업이 필요하면 직접 수행하지 않고 `NEEDS_PARENT_ACTION`으로 부모에게 반환한다.

---

## 13. Delegation 판단 질문

부모는 Luna를 생성하기 전에 다음을 확인한다.

### 핵심 질문

> Luna가 이 작업을 수행하려면 내가 이미 완료한 중요한 reasoning을 다시 해야 하는가?

### YES

다음 중 하나를 수행한다.

1. 부모가 필요한 판단을 끝낸 후 그 결과를 task capsule에 넣는다.
2. 위임하지 않고 부모가 직접 수행한다.

### NO

Luna 위임 후보가 된다.

---

## 14. Trivial Task Delegation & 작업 단위 정책 (Task Granularity)

Sol/Terra의 사용량 절감이 본 스킬의 핵심 목적이므로, 명확하고 판단이 끝난 **non-trivial execution task는 적극적으로 Luna에 위임**한다.

단, 위임 자체가 불필요한 오버헤드를 발생시키는 극단적 상황은 다음과 같이 방지한다:

1. **배치 위임 원칙 (Batching)**:
   - 서로 관련된 여러 개의 작고 명확한 작업(예: 여러 파일의 import 수정, 대응 테스트 작성 등)은 가능한 한 **하나의 bounded task로 묶어서 Luna에 위임**한다.
   - 작은 작업 여러 개를 각각 별도의 Luna child로 연속 spawn하는 과도한 파편화를 금지한다.
2. **단일 Trivial Atomic Action 예외**:
   - 한 줄 수정, 단일 literal 교체 등 독립적인 trivial atomic action 하나만 존재하고, Task Capsule 작성 + spawn + 결과 확인 비용이 직접 수행보다 명백히 큰 경우에는 부모가 직접 수행할 수 있다.
3. **우선순위 불변 원칙**:
   - 단순히 "부모가 더 빠르다(Latency)"는 이유만으로 명확한 non-trivial 작업을 부모가 계속 수행해서는 안 된다. **Latency보다 Parent Usage 절감이 우선**이다.

### ❌ 나쁜 예 (과도한 파편화)

```text
한 줄 수정 → Luna child 1
다음 한 줄 수정 → Luna child 2
테스트 하나 실행 → Luna child 3
```

### ✅ 좋은 예 (Bounded Task 묶음 위임)

```text
이미 결정된 serializer 변경
+ 대응 테스트 추가
+ 해당 테스트 실행
→ 하나의 bounded Luna task
```

---

## 15. Parent/Worker 책임 분리

### Parent

```text
사용자 의도
설계
분석
판단
작업 분해
구체적인 실행 결정
Luna prompt 작성
결과 평가
```

### Luna Worker

```text
주어진 범위 읽기
명시된 수정 수행
명시된 검증 수행
결과 보고
```

Luna는 작은 독립 개발자라기보다 **결정된 작업을 수행하는 bounded executor**에 가깝게 사용한다.

---

## 16. TDD와의 관계

이 Skill은 TDD 자체를 대체하거나 강제하지 않는다.

부모가 TDD를 수행하고 있다면 일부 명확한 단계가 Luna 위임 후보가 될 수 있다.

예:

```text
Parent:
테스트해야 할 동작과 테스트 케이스 결정

Luna:
정확히 정의된 실패 테스트 작성 및 실행

Parent:
결과 검토 / 다음 동작 판단

Luna:
이미 결정된 최소 구현 수행 및 테스트 실행
```

다만 RED/GREEN 단계를 지나치게 잘게 쪼개 매번 subagent를 생성하면 overhead가 커질 수 있으므로,
가능하면 하나의 명확한 bounded TDD 실행 단위로 묶는다.

---

## 17. Superpowers와의 관계

이 Skill은 Superpowers와 독립적으로 동작해야 한다.

Superpowers가:

- brainstorming
- TDD
- systematic debugging
- implementation planning
- subagent-driven development

등의 workflow를 결정하더라도 이 Skill의 목적은 변하지 않는다.

> **현재 부모가 이미 구체적으로 결정한 실행 작업을 Luna로 안전하게 내릴 수 있을 때만 위임한다.**

Superpowers가 이미 특정 모델의 subagent를 명시적으로 요청한 경우에는
불필요하게 다시 routing하지 않는 방향을 우선한다.

이 부분은 MVP 사용 후 실제 충돌 여부를 관찰해 필요할 때 강화한다.

---

## 18. Non-Goals

MVP에서 구현하지 않는다.

- 범용 AI model router
- Sol ↔ Terra 자동 전환
- Luna → Terra/Sol escalation
- quota 기반 routing
- API token 가격 기반 routing
- benchmark 기반 복잡한 score engine
- 사용자별 adaptive learning
- telemetry
- 웹 UI
- usage dashboard
- worker preset 관리 시스템
- 자체 multi-agent framework
- Codex 외 Claude/Gemini 등 다른 agent 지원

---

## 19. 성공 기준

MVP 성공 여부는 기능 수가 아니라 실제 Codex 사용량 절감으로 판단한다.

### 기능적 성공 기준

- Sol에서 명확한 실행 작업이 Luna로 실제 위임된다.
- Terra에서도 동일하게 작동한다.
- Luna parent에서는 상위 모델을 자동 호출하지 않는다.
- 계획/설명-only 요청에서는 불필요한 subagent를 생성하지 않는다.
- Luna prompt가 충분히 구체적이다.
- Luna가 새로운 중요한 판단을 해야 할 때 부모에게 반환한다.
- Luna가 다른 agent를 다시 생성하지 않는다.
- 부모가 최종 판단권을 유지한다.

### 실사용 성공 기준

비슷한 규모의 개발 작업에서:

- Sol/Terra 사용량이 유의미하게 감소한다.
- Luna 위임 때문에 재작업이 과도하게 늘어나지 않는다.
- 전체 완료 시간 증가가 허용 가능한 수준이다.
- 품질 저하가 체감되지 않는다.

가장 중요한 지표는:

> **상위 모델의 사용량을 줄이면서 결과 품질을 실질적으로 유지하는가?**

이다.

---

## 20. 구현 우선순위

### MVP

- [x] Agent Skills 형식의 `SKILL.md` 작성
- [x] 현재 부모가 Sol/Terra/Luna인지 구분하는 지침 작성
- [x] Sol/Terra에서만 Luna delegation 활성화
- [x] Luna parent에서 자동 delegation 비활성화
- [x] 실행 작업 eligibility 규칙 작성
- [x] planning-only / explanation-only 제외 규칙 작성
- [x] Minimal Self-Contained Task Capsule 작성 규칙 구현
- [x] Luna reasoning effort 동적 선택 정책 작성 (기본값 medium, low/medium/high, xhigh/max 금지)
- [x] Luna를 leaf worker로 강제하는 prompt 작성 (Policy Constraint)
- [x] `NEEDS_PARENT_DECISION` 반환 규칙 작성
- [x] 12대 핵심 실전 시나리오 및 검증 매트릭스 작성 (`delegation-examples.md`)
- [x] superpowers 표준 8대 합리화 방지 테이블 및 10대 Red Flags 목록 내장
- [x] Fail-Closed Fallback Invariant 작성 (부모 직접 수행)
- [x] 설치/사용/업데이트 README 작성 (글로벌 `~/.codex/skills/` 격리 정책 포함)
- [x] superpowers TDD for Skills 기반 검증 완료 (ALL PASS)
- [ ] 실제 Codex 환경에서 Sol → Luna 동작 실사용 검증
- [ ] 실제 Codex 환경에서 Terra → Luna 동작 실사용 검증
- [ ] Luna parent에서 escalation이 발생하지 않는지 실사용 검증

### MVP 이후

실사용 결과가 있을 때만 검토한다.

- [x] Task Capsule 규칙 개선 (Minimal Self-Contained Context)
- [x] Luna reasoning effort 선택 정책 개선 (Medium 기본값 및 상한 설정)
- [x] 위임 Granularity 개선 (Trivial Action 예외 및 Bounded Batching)
- [x] 8대 기본 필수 요건 및 3대 안전성 보조 신호(Coupling, Verification, Consequence) 체계 구축
- [x] Validation Budget & 최대 1회 Recovery Limit 및 NEEDS_PARENT_ACTION 프로토콜 구현
- [x] Acknowledgements 섹션 수록 (`codex-auto-model-router` 독립 영감 출처 명시)
- [x] Semantic Decision Closure, 조건부 Exact change 및 의미적 Acceptance Criteria 규칙 구현
- [ ] Superpowers 상호작용 심화 개선
- [ ] Codex 버전별 compatibility 안내
- [ ] 표준 Skill installer 배포 개선

---

## 21. 배포 방향

### 권장

독립 GitHub repository로 관리한다.

```text
codex-downshift/
├─ README.md
├─ CHANGELOG.md
├─ CONTRIBUTING.md
├─ LICENSE
├─ AGENTS.md
├─ docs/
│  ├─ README.md
│  └─ codex-downshift-spec.md
└─ skills/
   └─ codex-downshift/
      ├─ SKILL.md
      └─ references/
         ├─ delegation-examples.md
         └─ task-capsule-template.md
```

기본 사용 대상은 **Codex 사용자 전역 Skill**이다.

프로젝트 자체의 규칙이 아니라 사용자가 Codex에서 Sol/Terra 사용량을 관리하는 개인 실행 정책에 가깝기 때문이다.

### agent-rules-template

`callorange/agent-rules-template`의 기본 배포 Skill로 직접 포함하지 않는다.

필요하면 외부 추천 Skill 목록에서 독립 프로젝트를 소개하는 방식을 고려한다.

이유:

- Codex 전용 기능에 강하게 의존한다.
- 다른 coding agent에는 의미가 없거나 동작이 다르다.
- 독립 release cycle이 더 적절하다.

---

## 22. 설치 및 업데이트 방향과 경로 격리 정책

MVP에서는 복잡한 설치/업데이트 스크립트를 만들지 않으며, 표준 Agent Skills CLI 및 수동 설치 경로를 지원한다.

### 표준 CLI 설치 및 업데이트

```bash
# 글로벌 Codex 스킬로 설치
npx skills@latest add callorange/codex-downshift --skill codex-downshift --agent codex --global

# 글로벌 codex-downshift 업데이트
npx skills@latest update codex-downshift -g -y

# 설치된 글로벌 스킬 전체 업데이트
npx skills@latest update -g -y
```

### Windows Fallback 안내
Windows 환경이나 upstream CLI 이슈 발생 시 `skills add ... -y` 명령을 다시 실행하여 최신 소스로 안전하게 재설치/갱신할 수 있음을 안내한다.

### 수동 설치 경로 정책

- **글로벌 스킬 경로**: `~/.codex/skills/codex-downshift/` (또는 `$HOME/.codex/skills/codex-downshift/`)
  > 타 에이전트(Claude Code, Antigravity 등)가 전역 `$HOME/.agents/skills/`를 탐색하여 Codex 전용 스킬을 오인식하는 문제를 방지하기 위해 Codex 전용 디렉터리로 격리한다.
- **프로젝트 로컬 경로**: `<project-root>/.agents/skills/codex-downshift/`
  > 프로젝트 내 설치는 해당 저장소 작업이 Codex로 진행됨을 전제하므로 표준 경로를 유지한다.

---

## 23. 구현 시 중요한 금지사항

Antigravity 또는 다른 코딩 에이전트가 구현할 때 다음 범위를 임의로 확장하지 않는다.

- config 시스템을 추가하지 않는다.
- custom worker TOML을 추가하지 않는다.
- 별도의 router daemon을 만들지 않는다.
- Sol/Terra 자동 상호 라우팅을 추가하지 않는다.
- Luna escalation을 추가하지 않는다.
- telemetry를 추가하지 않는다.
- 불필요한 Python/Node runtime을 추가하지 않는다.
- UI를 만들지 않는다.
- 필요성 검증 전 복잡한 추상화를 만들지 않는다.

가능하면 **Skill 문서만으로 Codex의 기존 native multi-agent 기능을 활용**한다.

---

## 24. Acknowledgements (Inspiration)

Parts of the delegation safety design and execution constraints were inspired by [codex-auto-model-router](https://github.com/orange-the-weak/codex-auto-model-router), particularly its bounded task delegation, task capsule structure, validation budget, and fail-safe execution concepts. `codex-downshift` was independently redesigned and implemented to serve as a lightweight, instruction-only skill focusing strictly on Parent-controlled downshifting.

---

## 25. 한 문장 정의

> **Keep the user's Sol or Terra parent in control, and offload only fully specified execution work to Luna.**

한국어:

> **사용자가 선택한 Sol 또는 Terra의 판단권은 유지하고, 이미 명확하게 정의된 실행 작업만 Luna에 넘긴다.**
