# Model Economics & Estimated Consumption Index

본 문서는 `codex-downshift` 스킬의 모델 라우팅, 추론 레벨 선택 및 비용 최적화 판단의 근거가 되는 공식 요율과 추정 소모 지수(Estimated Consumption Index)를 정리한 기술 참조 문서입니다.

### 추론 레벨 표기

일반 설명과 비교표에는 표시 명칭을 사용하고, 설정·도구 호출 및 Routing Notice의 `<effort>`에는 실제 인자값을 사용한다.

| 표시 명칭 | 설정·호출 인자값 |
| --- | --- |
| Light | `low` |
| Medium | `medium` |
| High | `high` |
| XHigh | `xhigh` |
| Max | `max` |

이 표는 프로젝트에서 다루는 명칭의 대응이며, 모든 모델·도구가 모든 레벨을 지원한다는 뜻은 아니다.
실제 호출은 해당 도구 스키마와 기존 자동 선택 정책을 따른다.

---

## 1. OpenAI 공식 Token-Credit Rate

OpenAI가 공식 발표한 모델별 1M 토큰당 크레딧 단가입니다 ([OpenAI Help Center: credit-based usage](https://help.openai.com/en/articles/11481834) 기준).

| 모델 | Input / 1M | Cached / 1M | Output / 1M |
| --- | ---: | ---: | ---: |
| Luna | 5 credits | 0.5 | 30 |
| Terra | 50 | 5 | 300 |
| Sol | 100 | 10 | 500 |

Luna 대비 단순 요율 배수는 Terra가 Input·Cached·Output에서 10×이며,
Sol은 각각 20×·20×·약 16.7×다. 이 배수는 공식 표의 값으로 계산한
프로젝트 해석이며 공식 요율표의 일부가 아니다.

---

## 2. Estimated Codex Consumption Index (예상 실질 소모 지수)

> [!IMPORTANT]
> 아래 값은 OpenAI가 공개한 Plus/Pro Codex allowance 공식 환산식이 아닙니다.
> OpenAI의 공식 token-credit rate와 Codex Radar / CursorBench의 공개 agent 사용량 관측치를 결합하여
> 설정 간 상대적인 비용 효율을 비교하기 위해 만든 **추정 상대 소모 지수(Estimated Consumption Index)**입니다.
> 실제 5시간/주간 allowance 감소율은 context 크기, cache 비율, output, reasoning,
> tool call, agent step, subagent 및 서버 측 metering 정책에 따라 달라질 수 있습니다.
> 기존 지수의 산출 과정은 현재 재현 미확인 상태다. 수치는 보존하며 [산출 근거와 한계](#지수-산출-근거의-재현-상태)를 함께 참고한다.

### 모델별·추론레벨별 예상 상대 소모 지수 (기준: Luna Light = 1.00×)

| 모델 \ 추론 | Light (`low`) | Medium (`medium`) | High (`high`) | XHigh | Max |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Luna** | 🟢 **1.00×** | 🟢 **2.61×** | 🟢 **6.00×** | 🟡 **8.77×** | 🟠 **18.31×** |
| **Terra** | 🟢 **4.46×** | 🟢 **5.35×** | 🟡 **8.39×** | 🟠 **13.99×** | 🔴 **28.85×** |
| **Sol** | 🟡 **9.40×** | 🟠 **18.04×** | 🔴 **25.63×** | 🔴 **35.62×** | 🔴 **52.50×** |

---

## 3. 부모 기준선별 예상 상대 절감률 비교

절감률은 Active Parent의 reasoning effort 설정에 따라 달라집니다. Sol Medium을 단일 고정 baseline으로 삼지 않고, 실제 부모 모델 설정에 맞추어 비교합니다.

| 자식 설정 (Child Config) | 예상 소모 지수 | vs Sol Light (9.40×) 부모 | vs Sol Medium (18.04×) 부모 | 주요 적용 작업 |
| :--- | :---: | :---: | :---: | :--- |
| **Luna Light** | **1.00×** | **~89.4% lower** | **~94.5% lower** | 확정된 기계적 조립, 단위 테스트, 정형 린트/수정 |
| **Luna Medium** | **2.61×** | **~72.2% lower** | **~85.5% lower** | 구현 닫힘 + 경량 심볼/위치 로컬 탐색 |
| **Terra Medium** | **5.35×** | **~43.1% lower** | **~70.3% lower** | 로컬 알고리즘/클래스 내부 설계 (Sol Parent 전용) |

*(※ 모든 절감률은 Estimated Consumption Index 기준 추정치이며, 공식 allowance 보증치가 아닙니다.)*

---

## 4. Luna High vs Terra Medium 비교 및 Sol-Parent Golden Switch

### 1) 비교 기준

| 기준 | Luna High | Terra Medium | 해석 |
| --- | ---: | ---: | --- |
| 기존 Estimated Consumption Index | 6.00× | 5.35× | 프로젝트의 추정 상대 지수 |
| CursorBench 3.2 Score | 56.8% | 50.3% | 해당 평가의 점수 |
| CursorBench 3.2 Steps | 40 | 20 | 실행 단계 수이며 소요 시간 자체가 아님 |
| CursorBench 3.2 비용/작업 | $0.16 | $0.49 | 공개 토큰 가격을 적용한 비용; Codex allowance가 아님 |

출처와 관측 범위는 [외부 평가 데이터](#9-external-evaluation-data)를 따른다.
추정 지수와 Steps는 Terra Medium이 낮지만, 이 평가의 금전 비용은 Luna High가 낮다.
이들을 하나의 비용 척도로 합치거나 Terra Medium의 시간·allowance 절감을 보장해서는 안 된다.

### 2) 라우팅 근거

Golden Switch는 implementation-local 선택 권한을 Terra에 맡기는 기존 역할 정책이다.
Luna의 effort를 높여도 구현 판단 권한은 확장되지 않는다.
Sol Parent는 해당 권한이 남으면 Terra Medium을 후보로 선택하고 Economic Gate를 적용한다.
이 정책을 모든 작업에서 Terra Medium이 더 저렴하거나 품질이 높다는 주장으로 해석하지 않는다.

### 3) Golden Switching의 Parent별 적용 범위 (중요)
- **Sol Parent인 경우**:
  - `Implementation-Local Decision Remains` ➔ **Terra Medium Child**로 Golden Switch 적용 가능.
- **Terra Parent인 경우**:
  - Downshift Only 원칙(`Terra Parent ➔ Terra Child` 금지)에 따라 Terra Child를 생성할 수 없습니다.
  - 따라서 Terra Parent에서 구현 판단이 필요한 작업은 Golden Switch가 아니라 **Terra Parent Direct**로 직접 수행합니다.

---

## 5. 프롬프트 캐시 및 입력 토큰 단순 단가 비교

단순 공식 토큰 단가 기준의 캐시 읽기 예시입니다:

- **Sol 세션 (40,000 cached tokens)**:
  $$\frac{40,000}{1,000,000} \times 10 = \mathbf{0.4\text{ credits}}$$
- **Luna 독립 워커 (3,000 uncached input tokens)**:
  $$\frac{3,000}{1,000,000} \times 5 = \mathbf{0.015\text{ credits}}$$
- **비율**:
  $$\frac{0.4}{0.015} \approx \mathbf{26.67\times}$$

> [!NOTE]
> 해당 입력 부분만 단순 비교하면 약 26.7배 차이가 납니다.
> 단, 실제 작업 전체 비용은 output, reasoning, 추가 tool call 및 반복 agent step에 따라 달라지므로,
> "세션 전체가 항상 26배 저렴하다"고 해석해서는 안 됩니다.

---

## 6. Sources & Snapshot

Snapshot date: **2026-09-03**

### Official Codex credit-rate source
- OpenAI ChatGPT / Codex credit-based usage rate card
  - https://help.openai.com/en/articles/11481834
  - Codex의 모델별 Input / Cached Input / Output token-credit rate 확인에 사용

### API pricing reference
- OpenAI API Pricing
  - https://developers.openai.com/api/docs/pricing
  - API dollar pricing 참고용
  - Codex Plus/Pro 포함 allowance 차감 공식의 직접 근거가 아님

### Observed agent usage / benchmark sources
- Codex Radar
  - https://codexradar.com/
  - 모델 및 reasoning effort별 agent token usage / steps 관측치
- CursorBench 3.2
  - https://cursor.com/evals
  - 모델 및 reasoning effort별 score / token usage / agent steps 관측치


### 지수 산출 근거의 재현 상태

**2026-09-04 확인**: 현재 README·명세·스킬·참조 문서 및 관련 Git 이력을 추적했다.

| 확인 항목 | 확인 결과 |
| --- | --- |
| 현재 지수의 도입 | [d1c572c](https://github.com/callorange/codex-downshift/commit/d1c572c)에서 현재 수치 표를 도입하고 Input·Cached·Output 복합 가중치라고 설명 |
| 추정치로의 구분 | [31f8ee9](https://github.com/callorange/codex-downshift/commit/31f8ee9)에서 공식 allowance가 아닌 Estimated Consumption Index로 구분하고 참조 문서로 분리 |
| 기준값 | Luna Light = 1.00×로 명시 |
| 원시 입력과 계산 과정 | 설정별 토큰 종류별 입력값, cache 비율, 가중치, 정규화 산식·계산 산출물을 복원하지 못함 |

기존 수치는 보존하지만, 출처 링크가 있다는 사실만으로 표 전체의 산출 과정이 검증된 것은 아니다.
현재는 **산출 재현 미확인 snapshot**으로 취급하며, 이 지수만으로 모델 선택이나 위임 경제성을 확정하지 않는다.
3절 절감률은 `(1 - Child index / Parent index) × 100`으로 산술 확인할 수 있으나,
기초 지수의 타당성이나 실제 작업의 절감률을 입증하지는 않는다.
향후 갱신에는 원시 입력·표본·토큰 종류별 단가 적용·정규화 과정을 함께 기록해야 한다.

### Interpretation note
`Estimated Codex Consumption Index`는 위 공식 token-credit rate와 공개 benchmark / agent usage 관측치를 조합한 상대 비교용 추정치입니다.

OpenAI가 공개한 Plus/Pro의 5시간 또는 주간 allowance 공식 차감 배율이 아니다.
외부 평가나 metering 정책 변경 시에는 원시 입력과 산출 과정을 확보한 뒤 갱신 여부를 판단한다.

## 7. Effective Downshift Economics (Non-official Heuristics)

공식 token-credit 요율과 위 Estimated Consumption Index 표는 변경하지 않는다. 다음은 라우팅 판단을 위한 운영 모델이며 allowance 보장이 아니다.

**Effective Downshift Cost** = Parent Delegation Preparation + Child Execution + Parent Verification

**Parent Direct Cost** = Parent Analysis + Parent Implementation + Parent Validation

### 준비 비용과 위임 판단

경제성 비교에는 아래의 실제 작업 비용도 함께 고려한다. 준비 테스트를 통과하더라도
위임으로 늘어나는 사용자 재지시·재작업·검증 부담이 실행 절감분을 상쇄하면 Parent Direct다.

**준비 비용**

Parent preparation의 output/reasoning이 child prompt 비용을 초과할 수도 있다.
과도하게 상세한 Capsule은 savings를 없앤다.

**위임 조건**

위임은 child가 대체하는 실행량이 부모의 준비·검증 오버헤드보다 materially 클 때만 경제적이다.
시키는 데 드는 일이 직접 하는 일과 비슷하면 위임하지 않는다.

### 저비용 Delegation Preparation Test

1. Parent가 goal, scope, fixed decisions, acceptance를 이미 알고 있는가?
2. Child task 준비에 direct execution과 비교 가능한 분석이 필요하지 않은가?
3. Child가 의미 있는 bounded search, 반복, 구현 또는 test/fix work를 대체하는가?
4. Parent preparation plus verification이 대체되는 execution보다 명확히 작은가?

네 질문 모두 예여야 위임 후보를 유지한다. 하나라도 아니면 Parent Direct다.
모두 예여도 추가 재지시·재작업·검증 부담이 실행 절감분을 상쇄하면 Parent Direct다.

### 근거 미확정의 운영 가설과 적용 경계

**검증 전 가정 — 라우팅 기준 아님**

- Luna의 고정 실행량에서 약 **2×** leverage를 기대한다는 운영 가설.
- Terra의 implementation-local 분석·구현·검증량에서 약 **3×** leverage를 기대한다는 운영 가설.

이 문서에는 위 배율의 측정 방법·산출 근거·실측 검증이 제시되어 있지 않다.
수치는 검증 전 가정으로만 보존하며, 위임 임계값이나 모델 선택 기준으로 사용하지 않는다.

**라우팅 판단**

Luna/Terra 후보는 Gate A와 Gate B의 안전성·권한 판정으로 선택하고, 실제 위임은 Economic Gate의 Delegation Preparation Test를 모두 통과할 때만 수행한다.

**보조 신호**

LOC는 secondary reference이며, 단일 deterministic validation은 trigger가 아니고 예상되는 test/fix loop는 높은 위임 가치 신호다.

위 운영 가설은 공식 break-even 또는 token formula가 아니다. 측정 방법과 실제 로그가 확보되면 재검토한다.

## 8. Active Parent Recommendation (Non-official Heuristics)

### 설정별 비용·역할 비교

이 절은 사용자를 위한 참고 자료이며 스킬의 Parent 선택·전환 기능을 정의하지 않는다.
아래 수치는 기존 Estimated Consumption Index를 그대로 사용하며 품질 순위를 뜻하지 않는다.

| 설정 | 추정 소모 지수 | 경제적 가치와 적합한 역할 | 한계·판단 경계 |
| --- | ---: | --- | --- |
| **Luna Light** | **1.00×** | 구현 방법과 대상 위치가 확정된 기계적 실행의 우선 Child 후보. 반복 실행량을 낮은 모델 비용으로 대체할 수 있다. | 요구사항·계약·구현 판단을 새로 맡기는 근거가 아니다. 준비·검증 비용이 실행 절감분을 상쇄하면 Parent Direct다. |
| **Luna Medium** | **2.61×** | 구현은 닫혀 있고 고정 Match Rule 안에서 bounded search가 필요한 Child 후보. | Light보다 탐색에 추론을 배정하는 설정이며 구현 판단 권한을 넓히지 않는다. 문서 간 의미·계약 판단이 남은 일을 단순 검색으로 간주하지 않는다. |
| **Luna High** | **6.00×** | 기존 관측에서는 Terra Medium보다 높은 benchmark score를 보였다. 이를 포함해 비용·step·과업 적합성을 함께 비교한다. | 같은 관측에서 더 높은 소모 지수와 많은 step을 보였다. 특정 점수 우위를 일반 품질 우위로 해석하지 않으며, 자동 선택하지 않는다. |
| **Terra Light** | **4.46×** | Terra Medium보다 낮은 추정 소모 지수의 비교 후보. | 이 문서의 경험만으로 Medium 대비 품질·재작업 차이를 판단할 수 없다. 일반 구현의 Medium 기본 추천이나 Terra Child의 Medium 정책을 바꾸는 근거는 아니다. |
| **Terra Medium** | **5.35×** | 일반 구현의 비용/품질 균형 기본 추천. Sol Parent 아래에서는 외부 계약이 고정된 implementation-local 작업의 Child 후보. | 상위 규칙·계약 판단은 Parent 책임이다. Terra Parent가 Terra Child를 생성할 수는 없다. |
| **Sol Light** | **9.40×** | Sol Medium의 토큰 사용량이 부담될 때 고려하는 Parent 설정의 절충안. | Medium과 같은 결과 품질을 전제하지 않는다. 재지시·재작업·검증을 포함해 비교하며, 일반 구현의 Terra Medium 기본 추천을 대체하지 않는다. |
| **Sol Medium** | **18.04×** | 아래 조건처럼 상위 판단·정합성 유지 및 사용자 재지시 부담을 중시할 때 우선 고려하는 Parent 설정. | 일반 구현의 기본값은 아니다. 높은 사용량을 감수하는 경험 기반 선택이며 지시 준수를 보장하지 않는다. |

Luna의 가치는 단순히 가장 저렴하다는 데 있지 않다.
Parent가 닫아 둔 결정 안에서 확인 가능한 실행량을 대체할 때 downshift의 이점이 생긴다.
반대로 누락된 문맥을 사용자가 보충하거나 Parent가 결과를 다시 구현해야 한다면 낮은 지수가 실제 절감으로 이어지지 않을 수 있다.
이는 Luna의 일반 능력 한계에 대한 단정이 아니라 이 스킬이 부여하는 권한과 경제성의 경계다.
Luna를 Active Parent로 사용하는 방식은 현재 스킬의 지원 범위가 아니다.

Sol Light와 Medium의 외부 관측 비교는 [외부 평가 데이터](#9-external-evaluation-data)를 참조한다.
해당 결과는 이 프로젝트의 정합성 작업이나 Child 위임 결과를 직접 측정한 것은 아니다.

### 사용자 설정 추천

일반적인 구현 작업의 비용/품질 균형 기본 추천은 **Terra Medium**이다.
상위 판단과 정합성 유지가 중요한 아래 조건에서는 **Sol Medium을 우선 고려**하고,
Sol의 사용량 부담을 줄이려는 경우에는 **Sol Light를 절충안으로 고려**한다.
이는 사용자가 Parent 설정을 선택할 때의 조언이며, 현재 세션의 모델을 자동 전환하는 규칙이 아니다.

| 작업 조건 | Parent 추천 | 판단 근거와 적용 경계 |
| --- | --- | --- |
| 요구사항과 외부 계약이 명확하고 기존 패턴으로 진행하는 일반적인 구현 | **Terra Medium 기본** | 단순하거나 일반적인 구현까지 Sol Medium을 기본 추천하지 않는다. |
| Sol을 사용하되 Medium의 토큰 사용량이 부담됨 | **Sol Light 고려** | Medium과 동일 품질을 전제하지 않는다. 요구사항 충족·재지시·재작업·검증을 포함한 실제 작업 비용으로 비교한다. |
| 규칙·하네스·아키텍처의 조건, 예외, 우선순위 또는 책임 경계를 설계·수정 | **Sol Medium 우선 고려** | 판단 누락이 이후 실행에 영향을 주는 작업에 적용한다. 확정된 문구의 단순 치환만으로 이 조건을 충족하지 않는다. |
| 여러 문서·계약 사이에서 동일한 의미와 조건을 유지해야 함 | **Sol Medium 우선 고려** | 문서 간 누락·충돌을 추적하는 부담을 고려한다. 파일 수 자체는 기준이 아니다. |
| 독립 요구사항이 많아 각각의 충족 여부와 누락을 추적해야 함 | **Sol Medium 우선 고려** | 요구사항 수에 임계값을 두지 않고, 따로 유지·검증할 조건과 완료 대상의 부담을 본다. |
| 잘못 처리하면 사용자가 의도를 다시 설명하거나 결과를 되돌려 수정해야 하는 비용이 큼 | **Sol Medium 우선 고려** | 이미 발생한 재지시·재작업이나 예상되는 수정 범위가 판단 근거다. 낮은 소모 지수만으로 추천하지 않는다. |

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
7절의 비용 분해에 사용자 부담과 반복 작업을 함께 고려하는 관점이며,
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

## 9. External Evaluation Data

확인일: **2026-09-04**. 아래 관측 기록은 6절의 **2026-09-03 요율·추정 지수 snapshot**과 별도다.
기존 공식 Token-Credit Rate와 Estimated Consumption Index 수치를 재계산하거나 대체하지 않는다.

### CursorBench 3.2

출처: [CursorBench 결과와 산정 방식](https://cursor.com/evals).
실제 Cursor 세션에서 가져온 모호한 다중 파일 작업 평가다.
원문의 Low는 이 프로젝트의 표시 명칭 Light로 표기한다.

| 설정 | Score | 비용/작업 | Tokens | Steps |
| --- | ---: | ---: | ---: | ---: |
| Sol Light | 52.6% | $1.01 | 5,104 | 19 |
| Sol Medium | 60.0% | $1.95 | 9,747 | 27 |
| Terra Light | 46.9% | $0.42 | 5,312 | 19 |
| Terra Medium | 50.3% | $0.49 | 6,222 | 20 |
| Luna Light | 37.6% | $0.03 | 3,209 | 17 |
| Luna Medium | 47.7% | $0.08 | 7,095 | 28 |
| Luna High | 56.8% | $0.16 | 15,141 | 40 |

비용은 사용 토큰에 공개 가격을 적용한 값이다. Tokens는 원문의 지표명이며 Codex 구독 사용량과 동일시하지 않는다.
작은 점수 차이는 통계적으로 유의하지 않을 수 있다.

**선택에 대한 해석**: Sol Light는 Medium보다 Tokens가 약 47.6% 적고 점수는 7.4%p 낮다.
이는 사용량 절충안을 지지하지만 동일 품질을 보장하지 않는다.
Luna High와 Terra Medium의 금전 비용·추정 지수상 순위가 다르므로, 비교 기준을 명시해야 한다.

### Instavar: Codex 모델·effort 실험

출처: [294 Codex Runs Explained](https://instavar.com/research/agents/gpt-5-6-codex-models-reasoning-levels-benchmark-2026), 게시일 **2026-08-01**.

294회 실행 기록 중 결함 있는 평가 조건에 해당하는 50개 기록을 제외했으며,
수정된 공통 정책 비교에는 210개 기록을 사용했다. 294개 전체를 유효 공통 비교로 취급하지 않는다.

| 공통 비교 설정 | 통과 | 통과 결과당 평균 시간 | 통과 결과당 입력 토큰 |
| --- | ---: | ---: | ---: |
| Medium | 42/42 | 35.61초 | 54,478 |
| High | 42/42 | 37.54초 | 58,591 |
| XHigh | 42/42 | 47.17초 | 66,298 |
| Max | 42/42 | 57.11초 | 72,143 |

위 값은 모델별 값이 아닌 공통 비교의 effort별 집계다.
연구자는 유효 과제들이 대체로 쉬워 모델 간 우열을 구분하지 못했다고 명시한다.
높은 effort를 일률적으로 선택할 근거가 부족하다는 참고는 되지만,
어려운 아키텍처·정합성 작업에서도 Medium이면 충분하다는 근거는 아니다.
입력 토큰만으로 전체 모델 비용을 계산하지 않는다.

### Sonar: 기능 통과율과 코드 품질

출처: [GPT-5.6 Sol & Terra 평가](https://www.sonarsource.com/blog/openai-gpt-5-6-sol-and-terra/).

4,444개 과제의 기능 통과율은 Sol 81.99%, Terra 79.96%였으며,
버그·취약점·복잡도 등도 별도로 평가했다.
기능 통과율만으로 검토·유지보수 부담을 판단하지 않아야 한다는 참고 자료다.
이 기록을 Light와 Medium의 직접 비교 근거로 사용하지 않는다.

### 적용 경계

외부 benchmark 관측, 프로젝트의 추정 지수, 운영 경험을 구분한다.
어느 자료도 이 프로젝트에서 사용자 재지시 비용을 포함한 동일 모델 Medium → Light Child 위임의 순절감을 측정하지 않았다.
따라서 외부 점수만으로 기존 Downshift Only·권한·Economic Gate 정책을 변경하지 않는다.
