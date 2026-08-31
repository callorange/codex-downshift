# Task Capsule Template (Standard Markdown Format)

부모 모델(Sol/Terra)이 하위 워커인 Luna(`gpt-5.6-luna`)에 실행 작업을 위임할 때 복사하여 작성하는 표준 프롬프트 서식입니다.

> [!TIP]
> **토큰 효율 작성 원칙**:
> - 부모 모델의 Chain-of-Thought나 전체 대화 맥락은 전달하지 않습니다.
> - `Exact change`는 구체적인 코드가 이미 확정되었을 때만 포함하며, `Acceptance criteria`와 규칙만으로 충분하다면 불필요하게 전체 코드를 프롬프트에 중복 작성하지 않습니다.
> - 목표는 **"Luna가 상위 판단을 다시 하지 않아도 되는 최소한의 완결된(Self-Contained) 지침"**입니다.

---

```text
Role:
You are a leaf execution worker.

Goal:
[작업을 통해 완성해야 하는 명확한 단일 목표]

Target:
- Code: [수정할 파일 경로 및 심볼/함수/클래스]
- Test: [수정 또는 추가할 테스트 파일 경로]

Decisions already made:
- [부모 모델이 이미 확정한 구체적 설계/로직/알고리즘 규칙 1]
- [부모 모델이 이미 확정한 세부 인터페이스 규칙 2]

Exact change:
[하위 워커가 즉시 반영할 수 있는 구체적인 코드 스니펫 또는 명확한 치환 지침 (필요 시)]

Preserve:
- [반드시 유지해야 하는 기존 동작 및 호환성]
- [유지해야 하는 타입 힌트, 주석, 네이밍 규칙]

Do not touch:
- [작업 범위 밖의 파일 및 모듈]

Acceptance criteria:
- [ ] [완료 조건 1]
- [ ] [완료 조건 2]

Validation:
[실행할 정량 검증 명령어 (예: pytest tests/test_foo.py && ruff check foo.py) - 필요한 최소한만 지정]

Recovery policy:
If validation fails due to your own minor implementation error, you may attempt at most ONE recovery. If it still fails, return failure details immediately.

Escalation condition:
- If new semantic/behavioral/architectural judgment is needed: return NEEDS_PARENT_DECISION.
- If external side-effects (git push, deploy, secrets, elevated actions) are needed: return NEEDS_PARENT_ACTION.

Worker constraints:
- Do not spawn or delegate to other agents.
- Do not invoke another model.
- Do not perform external side-effects or destructive operations.
- Stop when the acceptance criteria are satisfied.
```
