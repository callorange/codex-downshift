# codex-downshift — Project Specification

> Status: MVP planning  
> Target: OpenAI Codex  
> Artifact purpose: Antigravity 등 코딩 에이전트가 이 문서를 기반으로 프로젝트를 생성·구현할 수 있도록 하는 구현 명세

---

## 1. 프로젝트 이름

### Repository name

`codex-downshift`

### GitHub description

**English**

> A lightweight Codex skill that keeps Sol or Terra as the parent and offloads (downshifts) fully specified execution tasks to leaf workers (e.g. Luna) to reduce usage.

**한국어 설명**

> Sol 또는 Terra를 부모 모델로 유지하면서, 명확하게 정의된 실행 작업만 Luna 등 경량 모델로 다운시프트(위임)해 Codex 사용량을 절감하는 경량 Skill.

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
이미 판단이 끝나고 범위가 명확해진 실행 작업을 Luna 등의 경량 서브에이전트에 넘겨
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
    reasoning_effort = "low"|"medium"|"high", # [필수] 작업 난이도에 따른 지정
    task_name = "<task_name>",       # [권장] 명확한 작업 식별자
    message = "<Self-Contained Task Capsule>"
)
```

### 7.1 Fallback Invariant (불변 규칙)

`gpt-5.6-luna` child 생성이 지원되지 않거나 호출 실패 시:
- Terra 또는 Sol child로 fallback하지 않는다.
- 다른 subagent로 자동 escalation하지 않는다.
- 현재 부모 모델(Sol/Terra)이 해당 작업을 직접 계속 수행한다.

### 7.2 Parent 중복 작업 방지

Luna가 작업을 성공적으로 완료하면 부모 모델은 위험도에 비례한 최소 Acceptance 확인만 수행하며, 동일 테스트 반복이나 코드 재작성을 하지 않는다.

### Reasoning effort

사용자 설정으로 고정하지 않는다.

부모 모델이 작업의 규모와 난이도에 맞게 선택한다.

예시:

```text
완전히 기계적이고 매우 짧은 실행
→ Luna의 비교적 낮은 reasoning

명확하지만 여러 단계의 코드 수정/테스트가 필요
→ Luna의 중간 reasoning

범위는 확정되어 있지만 상당한 코드 탐색이 필요한 bounded 작업
→ 필요하다면 더 높은 Luna reasoning
```

reasoning effort 선택은 최적화 대상이지만 MVP에서 복잡한 별도 정책 엔진을 만들 필요는 없다.

---

## 8. Delegation 가능 조건

Luna에 위임하려면 다음 조건을 대부분 만족해야 한다.

- 수정 목적이 명확하다.
- 대상 파일 또는 심볼을 충분히 특정할 수 있다.
- 기대 동작이 이미 결정되어 있다.
- 중요한 구현 결정이 부모에서 끝났다.
- 다른 합리적인 구현 선택지 중 하나를 Luna가 선택할 필요가 없다.
- acceptance criteria가 명확하다.
- 결과를 검증할 방법이 있다.
- 실패해도 범위가 제한적이고 부모가 결과를 검토할 수 있다.

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

## 12. Task Capsule 형식

Luna에게 넘기는 prompt는 가능한 경우 다음 구조를 사용한다.

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
<가능하면 실제 수정 내용 또는 매우 구체적인 지시>

Preserve:
<유지해야 하는 기존 동작/내용>

Do not touch:
<명시적인 범위 제한>

Acceptance criteria:
<완료 조건>

Validation:
<실행할 테스트 / lint / typecheck / 명령>

Escalation condition:
If the task requires a new semantic, behavioral, architectural,
or scope decision, stop and return NEEDS_PARENT_DECISION.

Worker constraints:
- Do not spawn or delegate to other agents.
- Do not invoke a more capable model.
- Do not broaden the task.
- Stop when the acceptance criteria are satisfied.
```

모든 항목을 매번 억지로 채울 필요는 없다.

중요한 것은 **Luna가 부모의 reasoning을 다시 재구성하지 않아도 되는 self-contained prompt**를 만드는 것이다.

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

## 14. Task Granularity

너무 작은 atomic action마다 Luna를 생성하지 않는다.

나쁜 예:

```text
한 줄 수정 → Luna
다음 한 줄 수정 → Luna
테스트 하나 실행 → Luna
```

가능하면 서로 관련된 명확한 실행 작업을 하나의 bounded task로 묶는다.

좋은 예:

```text
이미 결정된 serializer 변경
+ 대응 테스트 추가
+ 해당 테스트 실행
```

단, task를 크게 묶는 과정에서 새로운 판단이 필요해진다면 범위를 줄인다.

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
- [x] task capsule 작성 규칙 구현
- [x] Luna reasoning effort 동적 선택 규칙 작성
- [x] Luna를 leaf worker로 강제하는 prompt 작성
- [x] `NEEDS_PARENT_DECISION` 반환 규칙 작성
- [x] good/bad delegation examples 작성
- [x] 설치/사용 README 작성
- [ ] 실제 Codex에서 Sol → Luna 동작 검증
- [ ] 실제 Codex에서 Terra → Luna 동작 검증
- [ ] Luna parent에서 escalation이 발생하지 않는지 검증

### MVP 이후

실사용 결과가 있을 때만 검토한다.

- [ ] task capsule 규칙 개선
- [ ] Luna reasoning effort 선택 정책 개선
- [ ] 위임 granularity 개선
- [ ] Superpowers 상호작용 개선
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

## 22. 설치 방향 및 경로 격리 정책

MVP에서는 복잡한 설치 스크립트를 만들지 않으며, 표준 Agent Skills CLI 및 수동 설치 경로를 지원한다.

### 표준 CLI 설치

```bash
# 글로벌 Codex 스킬로 설치
npx skills@latest add callorange/codex-downshift --skill codex-downshift --agent codex --global

# 또는 프로젝트 로컬 스킬로 설치
npx skills@latest add callorange/codex-downshift --skill codex-downshift --agent codex
```

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

## 24. 한 문장 정의

> **Keep the user's Sol or Terra parent in control, and offload only fully specified execution work to Luna.**

한국어:

> **사용자가 선택한 Sol 또는 Terra의 판단권은 유지하고, 이미 명확하게 정의된 실행 작업만 Luna에 넘긴다.**
