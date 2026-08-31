# codex-downshift

> **Keep the parent model in control, downshift bounded execution to Luna.**

`codex-downshift`는 OpenAI Codex에서 **Sol** 또는 **Terra**를 주력(부모) 모델로 사용할 때, 이미 판단이 완료되고 범위가 명확해진 기계적 실행 작업만을 **Luna** (`gpt-5.6-luna`) 서브에이전트로 다운시프트(위임)하여 Codex 사용량과 비용 절감을 목표로 하는 경량 Agent Skill입니다.

---

## 💡 왜 Router가 아니라 "Downshift(Delegator)"인가?

본 프로젝트는 모델 간에 사용자를 임의로 스위칭하거나 복잡한 라우팅 규칙을 적용하는 일반적인 Model Router가 아닙니다.

1. **부모 모델의 판단권 유지**: 요구사항 해석, 아키텍처 설계, 비즈니스 결정 등 고난도 추론은 사용자가 선택한 상위 모델(Sol/Terra)이 끝까지 책임집니다.
2. **단방향 하향 위임 (Downshift Only)**: 상위 모델의 판단이 끝난 명확한 실행 단계(TDD 반복, 확정된 코드 작성, docstring/문서 수정, 린트/타입 오류 수정 등)만 Luna (`gpt-5.6-luna`)로 내려보냅니다.
3. **Leaf Worker 원칙 (지침 기반 제약)**: 본 스킬은 instruction-only 스킬로, 하위 워커가 다른 에이전트를 생성하거나 상위 모델을 호출하지 않도록 Task Capsule 지침으로 엄격히 제한합니다. 추가 판단이 필요하면 부모에게 `NEEDS_PARENT_DECISION`으로 작업을 즉시 반환합니다.
4. **Fail-Closed Fallback 불변 규칙**: Luna 생성이 실패하거나 미지원 환경인 경우, Terra/Sol child로 우회하거나 escalation하지 않고 **부모 모델이 직접 수행**하여 불필요한 고비용 모델 추가 호출을 원천 차단합니다.

---

## 📊 지원 모델 매트릭스

| 부모 모델 (Active Parent) | 위임 동작 | 설명 |
| :--- | :--- | :--- |
| **Sol** | ✅ `Sol ➔ Luna` 활성화 | 모든 핵심 판단은 Sol이 수행하고, 확정된 실행 작업만 Luna에 위임 |
| **Terra** | ✅ `Terra ➔ Luna` 활성화 | 모든 핵심 판단은 Terra가 수행하고, 확정된 실행 작업만 Luna에 위임 |
| **Luna** | ❌ 위임 비활성화 | 사용자가 Luna를 주 모델로 선택한 경우 상위 모델을 자동 호출하지 않음 |
| **기타 모델** | ❌ 위임 비활성화 | 지원하지 않는 모델 환경에서는 자동 위임을 비활성화하고 부모가 직접 수행 |

> [!NOTE]
> 수평 전환(`Sol ↔ Terra`)이나 상향 에스컬레이션(`Luna ➔ Sol/Terra`)은 절대 자동으로 발생하지 않습니다. (향후 다른 저비용 모델 지원 가능성은 Future Extension으로만 검토될 수 있습니다.)

---

## 🚀 Native Subagent Spawn Contract

다운시프트 실행 시 부모 모델은 Codex Native Subagent 생성을 통해 모델 상속을 방지하고 독립 컨텍스트로 자식 워커를 실행합니다:

```text
spawn_agent(
    model = "gpt-5.6-luna",          # [필수] 부모 모델 상속 방지
    fork_turns = "none",             # [필수] 부모 대화 제외, fresh context
    reasoning_effort = "medium",     # [필수] 기본값은 medium, 작업 난이도에 따라 low/medium/high 명시
    task_name = "<task_name>",
    message = "<Minimal Self-Contained Task Capsule>"
)
```

---

## 📦 프로젝트 구조

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
            ├── delegation-examples.md
            └── task-capsule-template.md
```

---

## 💻 설치 및 사용법

### 1. Agent Skills 표준 CLI로 설치 (권장)

```bash
# 글로벌 Codex 스킬로 설치
npx skills@latest add callorange/codex-downshift --skill codex-downshift --agent codex --global

# 또는 현재 프로젝트에 로컬 스킬로 설치
npx skills@latest add callorange/codex-downshift --skill codex-downshift --agent codex
```

### 2. 수동 설치 및 경로 정책

- **글로벌 스킬 설치 (전역 격리)**: `~/.codex/skills/codex-downshift/`
  > 타 에이전트(Claude Code, Antigravity 등)가 전역 `$HOME/.agents/skills/`를 조회하여 Codex 전용 스킬을 오인식하는 문제를 방지하기 위해 Codex 전용 디렉터리에 격리 설치합니다.
- **프로젝트 로컬 설치**: `<project-root>/.agents/skills/codex-downshift/`
  > 프로젝트 내 설치는 해당 저장소 작업이 Codex 기반으로 진행됨을 의미하므로 Agent Skills 표준 경로를 사용합니다.

---

## 📋 Task Capsule 형식 (Self-Contained Prompt)

부모 모델은 불필요하게 긴 Chain-of-Thought나 전체 대화를 넘기지 않고, 하위 워커가 상위 추론을 다시 수행하지 않아도 되는 **최소한의 완결된(Self-Contained) 지침**을 전달합니다.

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
<실제 교체할 코드 스니펫 또는 구체적 지시 (필요 시)>

Preserve:
<유지해야 하는 기존 동작/불변조건>

Do not touch:
<명시적인 수정 금지 범위>

Acceptance criteria:
<완료 조건>

Validation:
<실행할 테스트 / lint / typecheck 명령>

Escalation condition:
If the task requires a new semantic, behavioral, architectural,
or scope decision, stop and return NEEDS_PARENT_DECISION.

Worker constraints:
- Do not spawn or delegate to other agents.
- Do not invoke another model.
- Do not broaden the task.
- Stop when the acceptance criteria are satisfied.
```

---

## 📖 문서 및 참조 자료

- [Project Specification (기획 명세)](docs/codex-downshift-spec.md)
- [Delegation Examples & Scenarios (10대 실전 시나리오)](skills/codex-downshift/references/delegation-examples.md)
- [Task Capsule Template (프롬프트 서식)](skills/codex-downshift/references/task-capsule-template.md)
- [Changelog (변경 이력)](CHANGELOG.md)
- [Contributing Guide (기여 가이드)](CONTRIBUTING.md)

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

