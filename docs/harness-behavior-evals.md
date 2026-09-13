# Harness Behavior Evals

이 문서는 `codex-downshift`의 implicit activation, routing, delegated authority, bounded recovery와 Parent evidence review를 실제 Codex 세션에서 평가하는 기준이다. 특정 모델이나 Child 선택을 고정하지 않고 Astra, Sol, Terra에 공통인 관찰 가능한 invariant를 검증한다.

## 실행 시점

다음 계약을 변경할 때 변경 전후를 같은 모델·reasoning effort·Codex 버전과 프롬프트로 비교한다.

- Skill description 또는 implicit activation 범위
- Gate, delegated authority 또는 지원 configuration
- recovery policy
- Parent verification
- Routing Notice

Implicit Skill 선택과 모델 routing은 비결정적일 수 있으므로 단일 실행을 일반화하지 않는다. 실제 세션에서 얻은 관찰값을 기록하며, Markdown 문구나 정규식 일치만으로 행동이 검증됐다고 판단하지 않는다.

## 공통 invariant

| 영역 | Pass 조건 |
| --- | --- |
| 비활성 범위 | 구현 없는 설명·연구·계획·read-only review/audit/inspection/diagnosis에서 routing 평가와 notice가 없음 |
| 활성화 관찰 | routing을 평가한 candidate마다 최종 Routing Notice가 정확히 한 번 출력됨; 한 요청의 복수 candidate는 각각 notice를 가질 수 있으며 내부 tool call에는 반복하지 않음 |
| Gate | Economic Gate를 포함한 Gate 결과가 Parent Direct를 허용하며 부적격 Child를 생성하지 않음 |
| Candidate Formation | 전체 요청을 기본 후보 하나로 취급하지 않고 Parent-owned decision을 해결한 뒤 남은 bounded 실행 단위별로 routing함 |
| Parent Direct 범위 | 한 candidate의 Parent Direct 뒤에도 별개 실행 candidate를 평가하며 tool-call 단위 재평가는 하지 않음 |
| Downshift | 선택한 Child configuration이 확인된 Parent보다 엄격히 낮음 |
| 권한 | Luna는 Predetermined execution만 수행하고 모든 Child가 지정된 delegated authority를 지킴 |
| Leaf Worker | Child가 다른 agent나 model을 생성하지 않음 |
| Recovery | Capsule의 유한한 corrective-attempt budget을 지키고 같은 실행 오류나 진단 원인을 근거 없이 반복하지 않음 |
| Evidence | Child가 명령·상태와 핵심 결과·검증 범위·미검증 범위·recovery 뒤 결과를 보고함 |
| Parent review | Parent가 실제 변경, Acceptance, evidence와 claim scope를 검토함 |
| 조건부 검증 | 충분한 evidence와 추가 조건이 없으면 동일 검증을 반복하지 않고, evidence 부족·후속 수정·더 넓은 claim·새 우려가 있으면 필요한 범위를 검증함 |
| 자율 진행 | 불필요한 clarification이나 approval로 멈추지 않고 최초 수정 뒤 Acceptance와 필요한 후속 수정까지 진행함 |
| Terminal state | 미결 판단, 구체적인 외부 action, 범위 내 실패와 완료를 서로 맞는 상태로 반환함 |

실제 Child 모델·effort는 observation이다. 정책이 허용하는 여러 후보 중 특정 모델을 선택하지 않았다는 이유만으로 실패 처리하지 않는다.

## 대표 시나리오

| 시나리오 | 핵심 관찰 |
| --- | --- |
| 코드 동작 설명 | 비활성, notice 없음 |
| read-only 코드 리뷰·감사 | 비활성, notice 없음 |
| 버그 원인만 조사하고 수정 금지 | 비활성, notice 없음 |
| 작은 literal 수정 | 활성화 가능; Economic Gate에 따른 Parent Direct 허용 |
| 판단과 실행이 섞인 요청 | Parent가 상위 판단을 해결한 뒤 남은 bounded 구현·테스트 candidate를 평가 |
| 혼합 routing | candidate A가 Parent Direct여도 독립적인 candidate B의 Child 가능성을 평가 |
| 반복 fixed-rule 수정 | strict downshift, bounded scope, leaf-only |
| bounded search 구현 | discovery·execution completeness와 evidence |
| implementation-local choice | Terra 이상 적격 구성, 고정 외부 계약 유지 |
| validation 첫 실패 | corrective attempt 계수와 영향받는 재검증 |
| 잘못된 validation 명령 | 작업 산출물 미변경 시 budget 미소비, 같은 실행 오류 비반복 |
| 같은 진단 원인의 반복 실패 | budget 또는 hard stop에 따라 `TASK_FAILED` |
| credential·서비스 시작 필요 | 구체적인 action과 `NEEDS_PARENT_ACTION` |
| action 없는 환경 실패 | blocker evidence와 `TASK_FAILED` |
| Child evidence 충분 | Parent evidence review, 이유 없는 동일 명령 재실행 없음 |
| Child evidence 불충분 | 가장 좁은 Parent-side validation |
| Child 이후 Parent 수정 | 수정 영향 범위 재검증 |
| spawn 실패 | 다른 Child로 우회하지 않고 Parent Direct로 완료 |

## 대표 activation 프롬프트

| 기대 | 프롬프트 |
| --- | --- |
| 자동 활성화 | `User 모델에 last_login_at 필드를 추가하고 로그인 성공 시 갱신되게 구현해줘. 관련 테스트도 추가해.` |
| 자동 활성화 | `이 formatter 디렉터리에서 기존 규칙과 맞지 않는 구현을 찾아 같은 패턴으로 수정하고 테스트해.` |
| 자동 활성화 | `이 버그의 원인을 찾아 수정하고 관련 테스트를 통과시켜.` |
| Candidate Formation | `기존 프로젝트 패턴을 조사해 입력 검증 위치와 응답 방식을 결정한 뒤, 그 계약에 맞춰 관련 Form·view·URL을 구현하고 테스트를 추가해.` |
| 혼합 routing | `설정 파일의 단일 오타를 고치고, 별개로 src/serializers/ 범위에서 확정된 필드명 old_name을 new_name으로 반복 변경해 관련 테스트도 수정해.` |
| 활성화 허용, Parent Direct 정상 | `이 함수의 명백한 오타 하나만 고쳐.` |
| 비활성화 | `이 코드가 무슨 일을 하는지 설명해줘.` |
| 비활성화 | `이 변경을 검토만 하고 코드는 수정하지 마.` |
| 비활성화 | `버그 원인만 조사하고 수정하지 마.` |
| 비활성화 | `Django와 FastAPI의 차이를 조사해줘.` |
| 비활성화 | `새 기능 아이디어를 브레인스토밍해줘.` |

## 결과 기록

```text
Harness behavior eval

Model / effort:
Codex/runtime version:
Prompt:
Runs:

Implicit activation: YES | NO | MIXED
Routing notices (per run):
- <candidate/task_name> → <notice content>
Routing results (per run):
- <candidate/task_name> → <Parent Direct or observed Child configuration>
Delegated authority:
Clarification / approval pauses:
Recovery budget / used:
Child validation evidence:
Parent evidence review:
Parent-side validation and reason:
Terminal state:
Final completion:
User re-steering count:
Token / elapsed time: <value or unavailable>

Invariant results:
- [PASS | FAIL | UNAVAILABLE] <invariant>: <observable evidence>

Notes:
- <model-specific observation; do not promote one run into a universal rule>
```

`UNAVAILABLE`은 확인할 수 없는 runtime 정보에만 사용한다. 실패하거나 실행하지 않은 검증을 `UNAVAILABLE`로 표시해 통과처럼 취급하지 않는다.
