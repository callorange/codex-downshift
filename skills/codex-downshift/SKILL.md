---
name: codex-downshift
description: Offload fully specified execution tasks from Sol or Terra to cheaper leaf workers (e.g. Luna) while keeping the parent model in control to reduce usage.
---

# Codex Downshift (Execution Delegator Skill)

본 스킬은 OpenAI Codex 환경에서 상위 추론 모델(**Sol** 또는 **Terra**)이 설계와 판단을 완료한 후, 구체적으로 확정된 실행 작업만을 경량 모델(**Luna** 등)로 다운시프트(하향 위임)하여 Codex 크레딧과 사용량을 절감하는 실행 가이드입니다.

---

## 🎯 1. 핵심 철학: 하향 위임 & 부모 판단권 보장

> **"Keep the parent in control, downshift bounded execution to leaf workers."**

1. **부모 모델의 고유 권한**:
   - 요구사항 해석, 사용자 의도 파악, 아키텍처/API 설계, 모호성 해소, 작업 분해, 최종 결과 검증은 항상 부모 모델이 직접 수행합니다.
2. **단방향 하향 위임 (Downshift Only)**:
   - Sol ➔ Luna 또는 Terra ➔ Luna로만 하향 위임합니다.
   - 수평 전환(Sol ↔ Terra)이나 상향 위임(Luna ➔ Terra/Sol)은 절대 수행하지 않습니다.
3. **Luna는 항상 Leaf Worker**:
   - 하위 워커는 또 다른 서브에이전트를 생성(spawn_agent)하거나 다른 모델을 호출할 수 없습니다.

---

## 🧭 2. 부모 모델별 활성화 정책

| 현재 주력 모델 | 다운시프트 활성화 여부 | 동작 규칙 |
| :--- | :--- | :--- |
| **Sol** | ✅ **활성화** | 모든 핵심 판단은 Sol이 수행하고, 확정된 기계적 실행만 Luna에 위임 |
| **Terra** | ✅ **활성화** | 모든 핵심 판단은 Terra가 수행하고, 확정된 기계적 실행만 Luna에 위임 |
| **Luna** | ❌ **비활성화** | 사용자가 Luna를 부모로 직접 사용할 때는 자동 위임/에스컬레이션을 일체 하지 않음 |
| **기타 모델** | ❌ **비활성화** | 알 수 없거나 지원하지 않는 모델 환경에서는 위임하지 않고 직접 수행 |

---

## ⚖️ 3. 위임 적격성 판별 (Eligibility Checklist)

부모 모델은 하위 워커를 생성하기 전에 반드시 다음 **핵심 질문**을 스스로에게 던져야 합니다:

> **"하위 워커가 이 작업을 수행하기 위해, 내가 이미 완료한 중요한 추론을 다시 해야 하는가?"**

- **YES (다시 추론해야 함)** ➔ 부모가 판단을 끝내고 Task Capsule에 구체적 결정을 담거나, 부모가 직접 수행합니다.
- **NO (기계적 실행 가능)** ➔ 아래 체크리스트를 확인하고 다운시프트합니다.

### ✅ 위임 가능한 작업 (Good Candidates)
- 명확한 대체 텍스트가 정해진 Docstring, 주석, 문서 수정
- 부모가 이미 알고리즘과 로직을 결정한 구체적 코드 작성
- 구체적인 Acceptance Criteria 기반의 테스트 코드 작성 및 실행
- 결정된 API 명세에 따른 단순 import, rename, reference 수정
- 정량적으로 검증 가능한 Lint 및 Type 오류 수정
- 특정 테스트 스위트 또는 빌드 검증 명령 실행 및 결과 보고

### ⛔ 절대 위임하면 안 되는 작업 (Non-Delegable Tasks)
- 사용자의 모호한 요구사항을 해석해야 하는 작업
- 원인 규명이 되지 않은 버그를 처음부터 탐색해야 하는 디버깅
- 아키텍처, 데이터 모델, DB 마이그레이션 전략, 보안/권한 정책 결정
- API Contract 및 인터페이스의 Trade-off 판단
- 계획 수립(Planning-only), 설명(Explanation-only), 브레인스토밍 요청

---

## 📝 4. Task Capsule 프로토콜 (Self-Contained 지시서)

부모 모델은 하위 워커에게 목표만 던지지 않고, 상위 추론 결과를 완전히 포함한 **Self-Contained Task Capsule**을 제공해야 합니다.

### Task Capsule 기본 템플릿
```text
Role:
You are a leaf execution worker.

Goal:
<작업의 구체적 목표>

Target:
<수정할 파일 / 클래스 / 함수 / 심볼 경로>

Decisions already made:
<부모 모델이 이미 확정한 구체적 설계/로직 내용>

Exact change:
<실제 교체할 코드 스니펫 또는 명확한 치환 지침>

Preserve:
<반드시 유지해야 하는 기존 동작, 타입 힌트, 외부 인터페이스 등>

Do not touch:
<명시적인 수정 금지 영역>

Acceptance criteria:
<작업 완료를 판단하는 객관적 기준>

Validation:
<실행할 테스트 / 린트 / 타입체크 명령>

Escalation condition:
If the task requires a new semantic, behavioral, architectural,
or scope decision, stop immediately and return NEEDS_PARENT_DECISION.

Worker constraints:
- Do not spawn or delegate to other agents.
- Do not invoke a more capable model.
- Do not broaden the task.
- Stop when the acceptance criteria are satisfied.
```

---

## 🛑 5. Leaf Worker 제약 & 에스컬레이션 규약

하위 워커(Luna)가 실행 도중 예상치 못한 모호성이나 새로운 설계 결정을 마주하면 스스로 범위를 넓히지 않고 즉시 중단한 뒤 다음 형식으로 부모에게 반환합니다:

```text
NEEDS_PARENT_DECISION

Unresolved:
<결정되지 않은 사항 또는 마주친 모호성>

Why it blocks execution:
<현재 지침만으로는 안전하게 진행할 수 없는 이유>

Relevant:
<관련 파일 / 클래스 / 함수 / 심볼>
```

부모 모델은 이 보고를 받아 필요한 판단을 내린 후, 새로운 지침을 주거나 직접 마무리합니다.

---

## ⚙️ 6. Reasoning Effort 동적 조절 가이드

하위 워커 생성 시 작업의 난이도와 규모에 맞춰 Reasoning Effort를 동적으로 지정합니다:

1. **Low Reasoning**: 정확한 문자열/문서 치환, 단일 린트 오류 수정, 단순 테스트 명령 실행
2. **Medium Reasoning**: 명확한 로직의 단위 테스트 작성, 결정된 함수/클래스 구현, 여러 파일의 반복 패턴 수정
3. **High Reasoning**: 범위는 명확하나 여러 파일 간의 참조를 확인해야 하는 Bounded 작업

---

## 📦 7. 적정 작업 단위 (Task Granularity)

- **과도한 파편화 방지**: 한 줄 수정마다 에이전트를 매번 생성하지 않습니다 (Subagent 생성 오버헤드가 더 커짐).
- **논리적 Bounded Task 권장**: 예) 확정된 기능 코드 구현 + 대응 단위 테스트 작성 + 테스트 검증 실행을 하나의 Bounded Task Capsule로 묶어 위임합니다.

---

## 📚 참조 문서
- [위임 모범 사례 및 안티패턴](references/delegation-examples.md)
- [Task Capsule 표준 서식](references/task-capsule-template.md)
