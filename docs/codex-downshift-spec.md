# codex-downshift — Project Specification

> Status: v0.1.4 release baseline + Unreleased design updates (2026-09-05)
> Target: OpenAI Codex  
> Document role: 프로젝트의 설계 의도·정책 근거·성공 기준을 보존하는 기획 명세.
> 실제 실행 규칙은 `SKILL.md`, 비용 수치는 `model-economics.md`, 외부 관측은 `model-benchmarks.md`, 설정 추천은 `model-selection.md`, 설치 절차는 `README.md`를 기준으로 한다.

---

## 1. 프로젝트 이름 및 설명

### Repository name
`codex-downshift`

### GitHub description

**English**
> A lightweight Codex skill that keeps Astra, Sol, or Terra as the parent and offloads bounded execution to a lower model tier or the same model at a lower reasoning effort.

**한국어**
> Astra, Sol 또는 Terra를 부모 모델로 유지하면서 Gate A → Gate B → Economic Gate를 통과한 실행 작업만을 더 낮은 모델 tier 또는 같은 모델의 더 낮은 reasoning effort로 하향 위임하는 경량 Skill.

### 이름 선정 이유

이 프로젝트는 단순한 `model router`나 특정 모델에만 종속된 도구가 아니다.

- 사용자가 선택한 Astra/Sol/Terra를 다른 모델로 교체하지 않는다.
- 작업마다 "최적 모델"을 찾는 복잡한 라우팅이 목적이 아니다.
- 상위 모델의 판단이 끝난 실행 작업만 더 낮은 모델 구성으로 안전하게 다운시프트(하향 위임)한다.
- 하위 워커에서 Terra/Sol로 자동 escalation하지 않는다.

따라서 `downshift`가 상위 모델의 판단 통제 하에 실행 비용을 낮추는 실제 역할을 가장 정확하게 표현한다.

---

## 2. 프로젝트 목표

`codex-downshift`는 사용자가 Codex에서 Astra, Sol 또는 Terra를 주력(부모) 모델로 사용할 때,
이미 판단이 끝나고 범위가 명확해진 실행 작업을 더 낮은 모델 tier 또는 같은 모델의 더 낮은 reasoning effort를 사용하는 서브에이전트에 넘겨
상위 모델의 사용량과 비용을 줄이는 경량 Codex Skill이다.

핵심 질문은 하나다.

> **현재 부모 모델이 처리하려는 하위 작업 중, 상위 판단을 다시 하지 않고 하위 워커가 안전하게 실행할 수 있는 작업이 있는가?**

- 있다면: Gate A Safety ➔ Gate B Decision Authority ➔ Economic Gate를 거쳐 적합한 엄격한 하위 모델 구성에 위임하거나, 경제성이 비슷하면 Parent Direct로 처리한다.
- 없다면: 현재 부모 모델이 직접 처리한다.

---

## 3. 해결하려는 문제

Astra, Sol과 Terra는 높은 품질의 추론과 구현 능력을 제공하지만 Codex 사용량 제한을 빠르게 소비할 수 있다.

특히 다음과 같은 개발 과정에서는 실제 코드 변경량보다 반복 추론과 실행 과정의 비용이 커질 수 있다:

- TDD의 RED → GREEN → REFACTOR 반복
- 명확한 테스트 코드 작성
- 이미 결정된 구현의 실제 코드 작성
- 반복적인 코드 및 직렬화 필드 수정
- docstring/문서 수정
- deterministic lint/type 오류 수정
- 특정 테스트 및 검증 명령 반복 실행

많은 경우 상위 모델은 이미 다음 작업을 완료한 상태다:

1. 사용자의 의도 이해
2. 관련 코드 조사
3. 아키텍처 및 구현 방향 결정
4. 수정할 파일/심볼 결정
5. 동작과 acceptance criteria 결정
6. 검증 방법 결정

이 상태에서도 직접 수행과 위임의 비용을 비교해야 한다. Gate A/B를 통과한 작업에서 부모의 준비·검증 부담이 대체 실행량보다 명확히 작다면, 확정된 실행을 더 낮은 모델 구성에 맡겨 사용량을 줄일 수 있다.
`codex-downshift`는 상위 판단 권한을 온전히 보존하면서 그 마지막 실행 단계를 하위 워커에 안전하게 offload하는 것을 목표로 한다.

---

## 4. 10대 핵심 불변 규칙 (10 Core Invariants)

실행 불변 규칙의 원본은 [SKILL.md](../skills/codex-downshift/SKILL.md)다.
Parent의 상위 판단 소유, 엄격한 하향, 안전 게이트, 작업별 위임 권한, Leaf Worker,
Fail Closed, effort 정책, 최대 1회 복구, 네 반환 상태, Parent의 fresh verification을 유지한다.

위임 권한을 모델 이름에 묶으면 저렴한 모델이 충분한 작업도 배제하고 같은 모델 effort 하향을 불필요하게 제한한다.
따라서 Predetermined execution과 Implementation-local choice를 먼저 구분하고, 해당 권한에 충분한 모델·effort를 별도로 선택한다.
높은 모델이나 effort는 권한을 확장하지 않는다.

## 5. 지원 부모 모델 및 계층형 매트릭스

Active Parent는 Astra·Sol·Terra이며 `Astra > Sol > Terra > Luna` 순서상 낮은 모델 또는
같은 모델의 엄격히 낮은 effort에 실행을 맡긴다. 실제 Parent 구성을 추정하지 않는다.
자동 target은 Light/Medium이며 High 이상은 사용자 승인 예외다. 상세 호출 인자는 SKILL의 Spawn Contract를 따른다.

## 6. 결정적 라우팅 파이프라인 (Gate A → Gate B → Economic Gate)

독립 작업 후보마다 실제 구성 확인 → 안전성 → 위임 권한·능력 적합성 → 경제성을 평가한다.
개별 편집 호출마다 게이트를 반복하지 않고 범위·권한·위험 또는 실패로 판단 근거가 바뀔 때 재평가한다.
이는 준비 오버헤드를 줄이면서 의사결정이 필요한 경계를 유지하기 위한 것이다.

경제성은 Parent 준비·Child 실행·Parent 검증·추가 재작업을 Parent Direct와 비교한다.
LOC·파일 수·단일 검증은 보조 신호이며, 시키는 데 드는 일이 직접 실행과 비슷하면 Parent Direct다.
네 준비 조건과 notice 계약은 SKILL에, 추천은 [Model Selection Guide](../skills/codex-downshift/references/model-selection.md)에 둔다.

## 7. 프로젝트 파일 구조

`codex-downshift`는 외부 런타임 의존성 없이 순수 Agent Skills 표준에 따라 간결하게 구성된다.

```text
codex-downshift/
├── .gitignore
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
├── AGENTS.md
├── docs/
│   ├── README.md
│   └── codex-downshift-spec.md
└── skills/
    └── codex-downshift/
        ├── SKILL.md
        └── references/
            ├── benchmark-costs.md
            ├── delegation-examples.md
            ├── model-benchmarks.md
            ├── model-economics.md
            ├── model-selection.md
            ├── terminal-scenarios.md
            └── task-capsule-template.md
```

### 필요하지 않은 것 (Non-Essentials)
- 별도 daemon, background server, wrapper script
- 복잡한 config TOML 또는 custom agent TOML
- 별도 Python/Node 런타임 엔진
- Codex의 기본 Multi-Agent 기능(`spawn_agent`)을 프롬프트 지침 수준에서 제어한다.

---

## 8. 동적 생성 및 Downshift Spawn Contract

부모 모델이 위임 시점에 Codex의 native subagent 기능을 사용하며, 모델 상속을 방지하기 위해 다음 매개변수를 반드시 명시한다. 경로별 canonical 값과 조건은 [SKILL.md의 Spawn and Return Contract](../skills/codex-downshift/SKILL.md#-3-spawn-and-return-contract)를 따른다.

```text
spawn_agent(
    model = "<selected exact child model>",
    fork_turns = "none",
    reasoning_effort = "<low or medium>",
    task_name = "<task_name>",
    message = "<Task Capsule>"
)
```

같은 모델 경로는 실제 Parent effort보다 낮은 값을 선택한다. model 하향 경로에서는 Parent와 Child effort를 비교하지 않고 작업 profile에 맞는 Light 또는 Medium을 선택한다.

### 8.1 Fail-Closed Fallback Invariant (불변 규칙)
- Child 생성이 실패하거나 미지원 환경인 경우:
  - 타 모델로 우회하거나 `model`을 생략한 child를 재시도하지 않는다.
  - **현재 부모 모델(Astra/Sol/Terra)이 해당 작업을 직접 계속 수행한다.**

### 8.2 Estimated Codex Consumption Index 및 Reasoning Effort 정책

공식 Token-Credit Rate, Estimated Consumption Index와 캐시 계산은
[Model Economics](../skills/codex-downshift/references/model-economics.md)를 기준으로 한다.
외부 평가 원시 관측은 [Model Benchmarks](../skills/codex-downshift/references/model-benchmarks.md),
비용·성능·실제 작업 부담을 종합한 설정 조언은
[Model Selection Guide](../skills/codex-downshift/references/model-selection.md)를 따른다.

현재 비용 비교는 [Benchmark Costs](../skills/codex-downshift/references/benchmark-costs.md)의 동일 하네스 관측과 재현 가능한 산식을 우선한다.
기존 ECI는 보존하며 그 값만으로 routing을 확정하지 않는다. API 비용과 Codex 크레딧은 요율·토큰 구성을 확인 없이 환산하지 않는다.
추천 모델은 능력·비용의 출발점이며, 같은 모델 effort 하향은 특정 작업 종류에 제한하지 않는다.

---

## 9. 역할별 Decision Authority 및 위임 가능 조건

### 9.1 핵심 판별 질문 (Baseline Requirement)
> **"하위 워커가 이 작업을 수행하려면 내가 이미 완료한 중요한 추론을 다시 해야 하는가?"**

### 9.2 Semantic Decision Closure
Downshift는 미완성된 의미적 판단을 하위 워커에 넘기는 수단이 아니다. 부모는 spawn 전에 결과의 의미, 동작, 범주 및 외부 계약을 확정하고, 하위 워커에는 그 결정을 적용하고 검증하는 실행 판단만 남긴다.

### 9.3 3대 안전성 보조 신호 (Safety Signals)
1. **Coupling (결합도)**: 수정 범위가 국소적이고 영향 범위를 명확히 특정 가능한 작업.
2. **Verification (검증 가능성)**: 테스트, 린트, 타입체크 등 결정적 검증이 가능한 작업.
3. **Consequence (실패 영향도 / Blast Radius)**: 실패 영향이 가역적이고 제한적인 작업 (보안, DB migration, 배포 등은 무조건 부모 직접 수행).

---

## 10. 좋은 위임 작업 예시 (Good Candidates)

| 작업 상태 | 위임할 수 있는 내용 | 후보 선택 |
| --- | --- | --- |
| Predetermined execution | 확정 docstring·정형 치환·명시된 테스트·고정 Rule 탐색과 복구 | Luna Light/Medium부터 적합성·전체 비용 비교 |
| Implementation-local choice | 고정 API 안의 내부 자료구조·알고리즘·구현 선택 | 좁고 검증 가능하면 Terra Light, 일반 구현은 Terra Medium부터 비교; Luna 제외 |
| 관계·정합성 또는 장기 실행 | 고정된 결정과 계약 안의 여러 산출물 조정 | Sol의 능력 이점과 전체 비용 비교; Astra Light/Medium은 근거 제한적 실험 후보 |

같은 모델의 낮은 effort도 공통 게이트를 통과하면 위 작업 전반의 후보가 된다.
구체적인 Capsule과 반례는 [Delegation Examples](../skills/codex-downshift/references/delegation-examples.md)를 따른다.

---

## 11. 절대 위임하면 안 되는 작업 (Non-Delegable Tasks)

- Gate A 탈락 작업: DB 마이그레이션, 보안/인증 정책, 권한 체계, 배포 작업
- 사용자의 모호한 요구사항을 해석해야 하는 작업
- 원인 규명이 되지 않은 버그를 처음부터 탐색해야 하는 디버깅
- Architecture 및 Public API Contract Trade-off 판단
- 계획 수립(Planning-only), 설명(Explanation-only), 브레인스토밍 요청

---

## 12. 가장 중요한 위임 원칙 (나쁜 예 vs 좋은 예)

부모 모델은 하위 워커에게 **목표만 넘기지 않는다.** 부모가 이미 판단한 내용은 하위 워커가 다시 추론하게 하지 말고 Task Capsule에 명확한 결정 사항으로 담는다.

### 나쁜 예 (Bad)
```text
Improve the readability of UserService.create_user docstring.
```
*문제: 무엇이 읽기 어려운지, 어떤 형식이 맞는지 하위 워커가 다시 판단해야 함.*

### 좋은 예 (Good)

[패키지 내부의 완결된 docstring Capsule](../skills/codex-downshift/references/delegation-examples.md#fixed-docstring-capsule)을 따른다.
고정 대체 문자열·허용 권한·검증·worker 제한을 실제 메시지에 포함하는 예시이며, 스킬 폴더만 설치해도 사용할 수 있다.

---

## 13. Task Capsule 표준 서식 & 4대 Terminal Return Protocols

### 13.1 Task Capsule 핵심 서식

원본은 [Task Capsule Template](../skills/codex-downshift/references/task-capsule-template.md)이다.
`Apply`는 처리 대상 범위를, `Delegated authority`는 그 안의 구현 재량을 정한다.
모델과 권한을 별도 필드로 명시하고, 필요한 경우 completion set으로 알려진 대상과 발견한 대상을 추적한다.

### 13.2 4대 Terminal Return Protocols

완료는 `TASK_COMPLETED`, 실패는 `TASK_FAILED`, 권한 밖 판단은 `NEEDS_PARENT_DECISION`,
외부 권한 작업은 `NEEDS_PARENT_ACTION`으로 반환한다. 필수 증거·작업트리 보존·복구 조건은 Capsule 원본을 따른다.

---

## 14. Trivial Task Delegation & 작업 단위 정책 (Task Granularity)

1. **배치 위임 원칙 (Batching)**: 서로 관련된 여러 개의 작고 명확한 작업은 하나의 bounded batch 후보로 묶을 수 있다. Gate A를 통과하고 Gate B에서 확정 실행 권한과 적합한 Child 후보를 정한 뒤, Economic Gate까지 통과할 때만 Bounded Task Capsule을 작성하여 일괄 위임한다. 조건을 충족하지 못하면 Parent Direct로 처리한다.
2. **Routing signals and Economic Gate**: LOC·파일 수·단일 deterministic validation은 secondary signal이다. 예상 test/fix loop는 leverage 증거지만 자동 위임 명령이 아니다. Gate A → Gate B → Economic Gate를 순서대로 평가하고 Delegation Preparation Test 네 조건을 모두 충족할 때만 위임하며, 아니면 Parent Direct다.
3. **Parent Direct 조건**:
   - trivial literal/mechanical edit는 Delegation Preparation Test가 위임을 정당화하지 않을 때 Parent Direct로 처리할 수 있다. LOC·파일 수 자체가 경로를 독립적으로 결정하지 않는다.
   - 그 밖의 후보도 Delegation Preparation Test를 충족할 때만 위임하고, 아니면 Parent Direct로 처리한다.
4. **경제성 판단의 우선순위**: 안전성·권한·검증 요건을 먼저 충족한다. Parent Usage 절감과 함께 사용자 재지시·재작업·검증을 포함한 [실제 작업 비용](../skills/codex-downshift/references/model-selection.md#실제-작업-비용)을 고려한다. 준비 테스트를 통과해도 위임의 추가 부담이 실행 절감분을 상쇄하면 Parent Direct다.

---

## 15. Parent / Child 책임 분리

| 구분 | 주요 역할 | 책임 범위 | 제약 조건 |
| :--- | :--- | :--- | :--- |
| Active Parent (Astra/Sol/Terra) | 총괄 지휘 및 상위 의사결정 | 요구사항 해석, 아키텍처, 보안, 최종 검증 | Child 결과 Blind Trust 금지 |
| Child: Predetermined execution | 고정 Rule 실행 | 정형 조립·탐색·테스트·허용된 복구 | 새 구현 선택 금지, No Chaining |
| Child: Implementation-local choice | 내부 구현 분석 및 선택 | 고정 외부 계약 안의 구현·관계 유지 | 상위 판단 금지, No Chaining |

모델은 이 권한에 충분한 적격 구성을 별도로 선택한다. Luna는 Implementation Closed인 Predetermined execution에만 적격이다.
Astra Light/Medium은 동일 Codex 하네스 근거가 없는 실험 후보이며 Astra Max 관측을 일반화하지 않는다.

---

## 16. TDD 및 개발 워크플로와의 관계

이 Skill은 TDD 자체를 대체하거나 강제하지 않는다. 부모 모델이 TDD를 수행할 때 명확한 단계를 하위 워커에 위임할 수 있다:
- **Parent**: 테스트해야 할 동작과 테스트 케이스 결정
- **Luna**: 정확히 정의된 실패 테스트 작성 및 실행
- **Parent**: 결과 검토 및 다음 구현 방향 확정
- **Luna/Terra**: 결정된 구현 수행 및 테스트 실행

---

## 17. Superpowers 생태계와의 관계

이 Skill은 Superpowers(`writing-skills`, `verification-before-completion`, `subagent-driven-development`)와 독립적이면서도 실용적으로 정합되어 동작한다.
- Superpowers가 planning, TDD, debugging 워크플로를 주도하더라도, 부모가 구체적으로 결정한 실행 작업을 안전하게 하향 위임하는 목적은 동일하게 유지된다.

---

## 18. Evidence Before Completion & Scope Matching

Parent는 Child의 성공 보고를 무조건 신뢰(Blind Trust)하지 않으며 다음 원칙을 준수한다:
- **`Verification scope MUST match the completion claim scope.`**
- Parent가 사용자에게 보고하려는 claim 범위에 정확히 비례하는 **Minimum Sufficient Fresh Verification을 직접 수행**한다.

---

## 19. Non-Goals

- 범용 AI model router나 임의 switching을 구현하지 않는다.
- 상위 모델 호출이나 같은 모델의 동일·상위 effort 위임을 구현하지 않는다.
- 별도의 daemon, config 시스템, runtime wrapper를 추가하지 않는다.
- `high`/`xhigh`/`max` reasoning effort를 자동 spawn에 사용하지 않는다.

---

## 20. 성공 기준 (Success Criteria)

### 기능적 성공 기준
- Astra/Sol/Terra에서 명확한 실행 작업이 엄격히 낮은 모델 구성의 워커로 안전하게 위임된다.
- 같은 모델 경로는 실제 Parent effort가 확인되고 target effort가 엄격히 낮을 때만 선택된다.
- Gate A에서 High Consequence 작업이 완벽히 차단된다.
- 하위 워커가 다른 에이전트를 생성하지 않는다 (No Chaining).
- 부모 모델이 최종 판단권을 온전히 유지한다.

### 실사용 성공 기준

아래는 목표이며 실측 완료 주장이 아니다. 비교 조건과 기록 항목은 [실측 프로토콜](../skills/codex-downshift/references/benchmark-costs.md#프로젝트-실측으로-보완할-항목)을 따른다.

- Astra/Sol/Terra 사용량이 유의미하게 감소한다.
- 위임으로 인한 불필요한 재작업이 최소화된다.
- 품질 저하 없이 결과물의 완성도가 유지된다.

---

## 21. 배포 및 설치 경로 정책

수동 설치와 skills CLI 설치의 경로를 구분한다. [README 설치 안내](../README.md#설치)를 설치 정보의 기준으로 사용한다.
공식 사용자 탐색 경로와 CLI의 agent별 전역 경로가 다를 수 있으며, 경로 이름만으로 에이전트 간 격리를 보장하지 않는다.

- **표준 CLI 설치**:
  ```bash
  npx skills@latest add callorange/codex-downshift --skill codex-downshift --agent codex --global
  ```

---

## 22. Acknowledgements & References

Parts of the delegation safety design and execution constraints were inspired by [codex-auto-model-router](https://github.com/orange-the-weak/codex-auto-model-router), particularly its bounded task delegation, task capsule structure, validation budget, and fail-safe execution concepts. `codex-downshift` was independently redesigned and implemented to serve as a lightweight, instruction-only skill focusing strictly on Parent-controlled downshifting with Tiered Downshift and Gate A → Gate B → Economic Gate.

---

## 23. 한 문장 정의

> **Keep the user's Astra, Sol, or Terra parent in control, and offload bounded execution work to a strictly lower model configuration.**

한국어:
> **사용자가 선택한 Astra, Sol 또는 Terra의 판단권은 유지하고, Gate A → Gate B → Economic Gate를 통과한 실행 작업만 더 낮은 모델 tier 또는 같은 모델의 더 낮은 effort에 안전하게 하향 위임한다.**
