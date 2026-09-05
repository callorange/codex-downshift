# Model Selection Guide

이 문서는 공식 요율과 추정 소모 지수, 외부 benchmark, 실제 작업 비용을 함께 고려해
Parent 설정과 기존 downshift 후보의 reasoning effort를 선택하는 운영 지침이다.
공식·추정 비용 수치는 [Model Economics](model-economics.md), 원시 관측과 한계는
[Model Benchmarks](model-benchmarks.md)를 기준으로 한다.

이 추천은 모델 전환 기능이나 새로운 위임 권한을 정의하지 않는다.

## Recommendation Heuristics

### 설정별 비용·역할 비교

이 절은 사용자를 위한 참고 자료이며 스킬의 Parent 선택·전환 기능을 정의하지 않는다.
아래 수치는 기존 Estimated Consumption Index를 그대로 사용하며 품질 순위를 뜻하지 않는다.

| 설정 | 추정 소모 지수 | 경제적 가치와 적합한 역할 | 한계·판단 경계 |
| --- | ---: | --- | --- |
| **Luna Light** | **1.00×** | 구현 방법과 대상 위치가 확정된 기계적 실행의 우선 Child 후보. 반복 실행량을 낮은 모델 비용으로 대체할 수 있다. | 요구사항·계약·구현 판단을 새로 맡기는 근거가 아니다. 준비·검증 비용이 실행 절감분을 상쇄하면 Parent Direct다. |
| **Luna Medium** | **2.61×** | 구현은 닫혀 있고 고정 Match Rule 안의 bounded search 또는 검증 실패를 해석해 Parent가 고정한 Rule로 대응하는 1회 복구가 실행의 실질적 부분인 Child 후보. | Light보다 실행 추론을 늘리는 설정이며 구현 판단 권한을 넓히지 않는다. 문서 간 의미·계약 판단이 남은 일을 단순 검색이나 복구로 간주하지 않는다. |
| **Luna High** | **6.00×** | Artificial Analysis Coding Agent Index와 CursorBench에서 Terra Medium보다 높은 점수를 보였다. 비용·token·step·과업 적합성을 함께 비교한다. | 점수 우위가 implementation-local 권한을 만들지 않는다. Medium보다 task당 token이 많으며 자동 선택하지 않는다. |
| **Terra Light** | **4.46×** | Terra Medium보다 낮은 추정 소모 지수의 비교 후보. | 외부 Coding Agent Index는 Medium보다 9점 낮다. 프로젝트별 품질·재작업 차이는 측정되지 않았으며 일반 구현의 Medium 기본 추천을 바꾸지 않는다. |
| **Terra Medium** | **5.35×** | 일반 구현의 비용/품질 균형 기본 추천. Sol Parent 아래에서는 외부 계약이 고정된 implementation-local 작업의 Child 후보. | 상위 규칙·계약 판단은 Parent 책임이다. Terra Parent가 Terra Child를 생성할 수는 없다. |
| **Sol Light** | **9.40×** | Sol Medium의 토큰 사용량이 부담될 때 고려하는 Parent 설정의 절충안. | Medium과 같은 결과 품질을 전제하지 않는다. 재지시·재작업·검증을 포함해 비교하며, 일반 구현의 Terra Medium 기본 추천을 대체하지 않는다. |
| **Sol Medium** | **18.04×** | 아래 조건처럼 상위 판단·정합성 유지 및 사용자 재지시 부담을 중시할 때 우선 고려하는 Parent 설정. | 일반 구현의 기본값은 아니다. 높은 사용량을 감수하는 경험 기반 선택이며 지시 준수를 보장하지 않는다. |

Luna의 가치는 단순히 가장 저렴하다는 데 있지 않다.
Parent가 닫아 둔 결정 안에서 확인 가능한 실행량을 대체할 때 downshift의 이점이 생긴다.
반대로 누락된 문맥을 사용자가 보충하거나 Parent가 결과를 다시 구현해야 한다면 낮은 지수가 실제 절감으로 이어지지 않을 수 있다.
이는 Luna의 일반 능력 한계에 대한 단정이 아니라 이 스킬이 부여하는 권한과 경제성의 경계다.
Luna를 Active Parent로 사용하는 방식은 현재 스킬의 지원 범위가 아니다.

모델·추론 레벨별 외부 관측 비교는 [Model Benchmarks](model-benchmarks.md)를 참조한다.
해당 결과는 이 프로젝트의 정합성 작업이나 Child 위임 결과를 직접 측정한 것은 아니다.

### 성능·사용량 종합 해석

[Artificial Analysis 관측](model-benchmarks.md#artificial-analysis-추론-레벨별-성능)을 기존 공식 요율과
Estimated Consumption Index에 함께 적용하면 다음 기준을 얻을 수 있다.

| 비교 | 관측과 추천에 미치는 영향 |
| --- | --- |
| Light → Medium | Coding Agent Index가 Luna +17, Terra +9, Sol +7 상승했다. 위치·변환 규칙이 완전히 고정된 작업에는 Light를 유지하되, bounded search나 test/fix 반복이 있으면 Medium의 추가 추론이 재작업을 줄일 여지가 있다. |
| Medium → High | Luna +10, Terra +7, Sol +2다. Luna·Terra에서는 성능 상승이 크지만 effort가 권한을 확대하지 않는다. Sol은 Medium의 점수 효율이 높아 High를 일반 기본값으로 올릴 근거가 약하다. |
| High → XHigh → Max | Intelligence Index는 대체로 상승하지만 Coding Agent Index는 증가 폭이 작거나 Sol High 64 → XHigh 63처럼 역전도 있다. 높은 effort는 난도가 관측됐거나 실패 비용이 추가 사용량보다 클 때만 고려한다. |
| Luna High vs Terra Medium | Intelligence는 둘 다 47, Coding Agent Index는 52 vs 48이다. Codex task당 token은 9.6M vs 3.2M이고 Estimated Consumption Index는 6.00× vs 5.35×다. Luna의 공식 token-credit rate는 낮지만 Terra는 implementation-local 권한에 맞으므로 점수만으로 경로를 바꾸지 않는다. |
| Terra High vs Sol Light | Intelligence는 50 vs 51, Coding Agent Index는 둘 다 55다. 비슷한 점수가 model tier의 역할·지시 준수·정합성 능력이 같다는 뜻은 아니다. 필요한 판단 권한과 실제 재작업 비용으로 선택한다. |
| Sol Medium vs 상위 effort | Coding Agent Index 62로 High 64·Max 65에 가깝고 Estimated Consumption Index는 High보다 약 29.6%, Max보다 약 65.6% 낮다. 규칙·정합성 작업의 기본 우선 고려는 Sol Medium으로 유지한다. |

이 비교는 benchmark task 집합의 평균 관측이다. 개별 작업의 성공확률이나 지시 준수를 보장하지 않으며,
비슷한 종합 점수라도 DeepSWE·Terminal-Bench·SWE-Atlas-QnA의 세부 강점은 다를 수 있다.

### 비용과 점수의 관계

Estimated Consumption Index와 benchmark 점수는 모델 tier와 effort가 올라갈수록 대체로 함께 증가한다.
그러나 증가율은 비례하지 않고 높은 설정일수록 점수의 한계효용이 작아지는 구간이 있다.

| 비교 | 추정 지수 변화 | Coding Agent Index 변화 | 해석 |
| --- | ---: | ---: | --- |
| Luna Light → Medium | 1.00× → 2.61× | 25 → 42 | 점수 상승이 크지만 비용 배수와 동일한 비율은 아니다. |
| Terra Light → Medium | 4.46× → 5.35× | 39 → 48 | 상대적으로 작은 지수 증가로 의미 있는 점수 상승이 관측됐다. |
| Sol Medium → High | 18.04× → 25.63× | 62 → 64 | 비용 증가는 크고 점수 상승은 제한적이다. |
| Sol High → XHigh | 25.63× → 35.62× | 64 → 63 | 비용이 늘어도 해당 benchmark 점수는 오히려 낮아졌다. |

두 값은 산출 출처와 단위가 다르고 Estimated Consumption Index의 원시 산식도 재현되지 않았다.
또한 지수 산정 설명에 CursorBench 관측이 포함되어 있어 CursorBench와의 유사성은 독립적인 검증이 아니다.
따라서 상관 경향을 비용 대비 품질의 공식이나 설정 간 교환비로 사용하지 않는다.

### Downshift Child 선택 보완

아래 기준은 benchmark 관측을 기존 Gate B 권한 정책에 보조 신호로 적용한 것이다.
점수나 effort가 Child의 위임 권한을 확대하지 않으며, 실제 위임에는 Economic Gate도 적용한다.

| 작업 조건 | Child 후보 | 판단 근거와 적용 경계 |
| --- | --- | --- |
| 구현 방법과 수정 위치가 고정된 짧은 기계적 실행 | **Luna Light** | 가장 낮은 Estimated Consumption Index를 활용한다. Coding Agent Index가 25이므로 탐색·해석·복구 판단을 새로 맡기지 않는다. |
| 구현은 닫혀 있고 bounded search 또는 검증 실패에 고정 Rule로 대응하는 1회 복구가 필요 | **Luna Medium** | Coding Agent Index가 Light 25에서 Medium 42로 상승했다. 추가 token과 Parent 검증을 감수할 실행량이 있을 때 사용하며, 새 구현 판단이 생기면 Parent에게 반환한다. |
| 구현은 닫혀 있으나 Medium 실패의 재작업 비용이 크고 높은 effort를 사용자가 승인 | **Luna High 예외 고려** | Coding Agent Index 52로 Medium보다 높지만 task당 token도 4.3M에서 9.6M으로 늘었다. 구현 판단 권한은 확대하지 않으며 자동 선택하지 않는다. |
| 외부 계약은 고정됐지만 implementation-local 선택이 남음 | **Terra Medium** | Sol Parent에서만 선택한다. Luna High의 점수가 더 높아도 effort로 구현 권한을 대신하지 않는다. Terra Parent는 직접 처리한다. |

### 사용자 설정 추천

일반적인 구현 작업의 비용/품질 균형 기본 추천은 **Terra Medium**이다.
상위 판단과 정합성 유지가 중요한 아래 조건에서는 **Sol Medium을 우선 고려**하고,
Sol의 사용량 부담을 줄이려는 경우에는 **Sol Light를 절충안으로 고려**한다.
이는 사용자가 Parent 설정을 선택할 때의 조언이며, 현재 세션의 모델을 자동 전환하는 규칙이 아니다.

| 작업 조건 | Parent 추천 | 판단 근거와 적용 경계 |
| --- | --- | --- |
| 요구사항과 외부 계약이 명확하고 기존 패턴으로 진행하는 일반적인 구현 | **Terra Medium 기본** | Light보다 Coding Agent Index가 39에서 48로 높고 Estimated Consumption Index 증가는 4.46×에서 5.35×다. 일반 구현까지 Sol Medium을 기본 추천하지 않는다. |
| Terra를 사용하며 작업이 정형적이고 사용량 절감이 품질 여유보다 중요 | **Terra Light 고려** | Light의 점수와 재작업 가능성을 감수할 수 있을 때만 선택한다. implementation-local 판단이나 다중 파일 조정에는 Medium을 유지한다. |
| 외부 계약은 고정됐지만 내부 설계·다중 파일 구현 난도가 실제로 높음 | **Terra High 고려** | Coding Agent Index가 Medium 48에서 High 55로 상승했다. 높은 effort의 추가 사용량보다 재작업 비용이 클 때 선택한다. |
| Sol의 판단 능력이 필요하지만 계약이 명확하고 사용량 부담을 줄여야 함 | **Sol Light 고려** | Intelligence 51·Coding Agent Index 55로 단순 구현에는 충분할 수 있다. Medium과 같은 정합성·재작업 비용을 전제하지 않는다. |
| 규칙·하네스·아키텍처 또는 여러 문서·계약의 정합성을 유지 | **Sol Medium 우선 고려** | Coding Agent Index 62로 High 64·Max 65에 가깝다. 독립 요구사항과 completion set을 추적할 판단 부담을 기준으로 삼는다. |
| Sol Medium에서 난도가 확인됐고 오류·재작업 비용이 추가 사용량보다 큼 | **Sol High 고려** | Coding Agent Index 상승은 62에서 64로 제한적이다. 어려운 구현·검증에서 추가 여유가 필요한 경우에만 선택하며 지시 준수를 보장하지 않는다. |
| XHigh·Max가 필요한 장기 추론이나 실패가 반복해서 관측됨 | **XHigh·Max 예외 고려** | Intelligence는 상승하지만 Coding Agent Index의 한계효용은 작고 Sol XHigh는 High보다 1점 낮다. Medium·High가 부족하다는 작업 근거 없이 기본값으로 사용하지 않는다. |

Sol Medium의 조건부 우선 고려는 이번 프로젝트의 실제 사용 경험을 반영한 **정성적 운영 휴리스틱**이다.
위 비교표의 모든 모델·effort를 이번 작업에서 직접 비교 평가했다는 뜻은 아니다.
통제된 모델 비교나 측정된 재작업 감소율을 뜻하지 않으며, Sol Medium도 지시 준수를 보장하지 않는다.
추천 설정을 사용해도 요구사항·completion set과 결과를 대조하고, 완료 주장에 맞는 검증을 수행해야 한다.

### 실제 작업 비용

모델 사용량 외에 작업을 완료하는 데 드는 다음 부담을 함께 비교한다.

| 비용 요소 | 비교할 관찰 근거 |
| --- | --- |
| Model usage | Parent와 Child의 준비·실행·검증 및 재시도에 사용한 토큰·reasoning·tool/agent steps |
| Human steering | 사용자가 누락을 지적하고 의도·조건을 재설명하는 횟수와 소요 시간 |
| Rework | 누락·오해·계약 불일치로 다시 분석·수정해야 하는 범위와 반복 실행 |
| Verification | 결과를 요구사항 및 문서·계약과 대조하고 검사·재검사하는 노력 |

이는 크레딧과 사람의 시간을 동일 단위로 더하는 공식이 아니다.
[Model Economics의 비용 분해](model-economics.md#6-effective-downshift-economics-non-official-heuristics)에 사용자 부담과 반복 작업을 함께 고려하는 관점이며,
이미 실행·검증 비용에 포함된 재작업을 별도 비용으로 중복 합산하지 않는다.
추가 모델 사용량보다 재지시·재작업·검증 부담을 줄일 가치가 있다고 판단되면
Sol Medium을 우선 고려할 수 있지만, 절감 효과를 보장하거나 고정 배율로 환산하지 않는다.
실제 기록이 없으면 예상으로 구분하고, 관찰된 사용량과 사용자 개입·재작업을 바탕으로 추천을 재평가한다.

### Downshift 정책과의 관계

Parent 설정 추천 이후에도 실제 runtime에서 확인한 Active Parent를 기준으로
Gate A → Gate B → Economic Gate를 적용한다. 안전성·권한·검증 요건이 비용 판단보다 우선한다.

- Sol Parent는 기존 조건에 따라 Luna 또는 Terra Child로 downshift할 수 있다.
- Terra Parent는 Luna Child만 사용할 수 있으며, implementation-local 판단이 남으면 Terra Parent Direct다.
- Sol Medium 추천은 Sol Child, 상향·동일 티어 위임, 자동 Parent 전환을 허용하지 않는다.
- 실제 위임은 Delegation Preparation Test 네 조건을 모두 통과하고, 위임의 추가 부담이 실행 절감분을 상쇄하지 않을 때만 수행한다.

상위 판단과 정합성 유지는 Parent가 맡고, 그 판단으로 닫힌 bounded execution만
기존 정책에 따라 downshift하는 방식으로 Parent 설정과 위임 경제성을 함께 판단한다.
