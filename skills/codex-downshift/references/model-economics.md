# Model Economics & Estimated Consumption Index

본 문서는 `codex-downshift`의 공식 Token-Credit Rate, 추정 소모 지수(Estimated Consumption Index), 위임 비용 모델과 산출 한계를 정리한 비용 참조 문서입니다.

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
| **Luna Medium** | **2.61×** | **~72.2% lower** | **~85.5% lower** | 구현 닫힘 + bounded 탐색·고정 복구 실행 |
| **Terra Medium** | **5.35×** | **~43.1% lower** | **~70.3% lower** | 고정된 외부 계약 안의 로컬 알고리즘/클래스 내부 설계 |

*(※ 모든 절감률은 Estimated Consumption Index 기준 추정치이며, 공식 allowance 보증치가 아닙니다.)*

### 3.1 같은 모델 effort 하향의 예상 지수 차이

같은 모델의 더 낮은 effort를 Child로 쓰면 model token-credit rate는 같지만 Estimated Consumption Index는 낮아진다.
아래는 자동 target인 Light 또는 Medium으로 내리는 대표 비교이며, 실제 Parent effort를 확인한 경우에만 적용한다.

| Parent → Child | 예상 소모 지수 | Child 지수의 상대 감소 |
| --- | ---: | ---: |
| Terra Medium → Terra Light | 5.35× → 4.46× | ~16.6% lower |
| Terra High → Terra Medium | 8.39× → 5.35× | ~36.2% lower |
| Sol Medium → Sol Light | 18.04× → 9.40× | ~47.9% lower |
| Sol High → Sol Medium | 25.63× → 18.04× | ~29.6% lower |

이 감소율은 Child 실행분만 비교한 추정치다. Capsule 준비, Parent 검증, 재지시와 재작업이 추가되므로
위임 전체가 같은 비율로 절감된다는 뜻은 아니다. lower-model 후보가 충분하면 공식 요율도 더 낮으므로 먼저 비교한다.
Terra same-model 경로는 implementation-local 선택 때문에 Luna 권한을 넘을 때, Sol same-model 경로는 관계·요구사항 누락을 결정적 검증만으로 확인하기 어려워 Terra가 Parent 수동 검증·재작업을 늘릴 때의 제한된 대안이다.

---

## 4. 프롬프트 캐시 및 입력 토큰 단순 단가 비교

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

## 5. Sources & Snapshot

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

### Estimated index supporting sources
- Codex Radar
  - https://codexradar.com/
  - 모델 및 reasoning effort별 agent token usage / steps 관측치
- CursorBench 3.2
  - https://cursor.com/evals
  - 모델 및 reasoning effort별 token usage / agent steps 관측치

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

## 6. Effective Downshift Economics (Non-official Heuristics)

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

---

모델·추론 레벨별 외부 관측값은 [Model Benchmarks](model-benchmarks.md),
비용과 성능을 함께 적용한 추천은 [Model Selection Guide](model-selection.md)를 참조한다.
