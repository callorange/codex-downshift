# Task Capsule Template (Standard Markdown Format)

부모 모델(Sol/Terra)이 하위 워커인 Luna(`gpt-5.6-luna`)에 실행 작업을 위임할 때 복사하여 작성하는 표준 프롬프트 서식입니다.

> [!IMPORTANT]
> **Pre-spawn check (parent only; child message에 포함하지 않음)**:
> - 결과의 의미와 동작이 부모에서 확정되었는가?
> - Luna가 선택해야 할 제품·정책·범주 결정이 남아 있지 않은가?
> - 서로 다른 두 결과가 모두 정답일 수 있다면 허용 범위가 명시되었는가?
> - 정확한 표현이나 분류가 계약이라면 `Exact change`가 제공되었는가?
> - `Acceptance criteria`가 형식뿐 아니라 의미적 불변조건도 검증하는가?

> [!TIP]
> **토큰 효율 작성 원칙**:
> - 부모 모델의 Chain-of-Thought나 전체 대화 맥락은 전달하지 않습니다.
> - 정확한 문구, 범주 구분, literal, 설정값, import 또는 고정 코드 블록처럼 결과 형태가 계약이면 `Exact change`를 반드시 포함하고, final text나 결정적인 변환 규칙을 제공합니다.
> - 구현 코드를 Luna가 작성해도 되는 작업은 전체 코드를 중복하지 않아도 됩니다. 대신 signature, algorithm, error behavior, side effect, edge case 및 test case를 확정합니다.
> - `Acceptance criteria`에는 테스트·lint 같은 형식 검증과 함께 유지할 의미, 범주, 동작 및 호환성 불변조건을 적습니다.
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
[정확한 결과 형태가 계약이면 필수: final text, before/after 또는 결정적인 변환 규칙]

Preserve:
- [반드시 유지해야 하는 기존 동작 및 호환성]
- [유지해야 하는 타입 힌트, 주석, 네이밍 규칙]

Do not touch:
- [작업 범위 밖의 파일 및 모듈]

Acceptance criteria:
- [ ] [유지해야 할 의미·범주·동작·호환성 불변조건]
- [ ] [허용하지 않는 의미·동작 변경]
- [ ] [테스트·lint·diff 등 기계적 검증 결과]

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
