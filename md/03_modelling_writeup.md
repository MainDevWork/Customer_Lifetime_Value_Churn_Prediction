# Stage Three — Model Construction, Testing and Selection

**Notebook:** `03_modelling.ipynb`

---

## Project overview

Telecommunications providers lose customers to competitors on a continuous basis. The industry term for this is **churn**. It represents a significant commercial cost, as acquiring a new customer is considerably more expensive than retaining an existing one.

The standard response is to predict which customers are most likely to leave, and to contact those customers with a retention offer.

This project undertakes that prediction, and then addresses a second question which most churn projects omit: **whether a given customer is worth the cost of retaining them.** For a substantial proportion of the customer base, the answer is no.

The work is delivered in four stages, each documented separately:

| Stage | Purpose |
|---|---|
| One | Assess the contents and reliability of the source data |
| Two | Construct the database, derive the required measures, and calculate customer value |
| **Three (this document)** | Build, test and select the predictive model |
| Four | Determine which customers justify intervention, and quantify the commercial return |

**This document is written to be read independently of the underlying code.** All work undertaken and all findings reached are set out in full below.

---

## Position within the project

Stage Two produced a structured database covering 7,043 customers of a telecommunications provider in California. For each customer it holds seven derived measures — tenure banding, the number of additional services held, the ease with which the customer may terminate their contract, and others — together with a calculated value for that customer.

The present stage addresses a single question: **based upon the information held about a customer at the present time, how likely are they to depart?**

---

## What a predictive model does

A predictive model is supplied with a set of historical customers, together with the known outcome for each — whether that customer departed or remained. It identifies the patterns which distinguish the two groups.

Once trained, the model can be presented with a customer and asked to estimate the likelihood of departure, expressed as a probability between 0 and 1.

Two models were constructed for this project.

**A logistic regression.** This method fits a single equation. Each item of information about a customer is assigned one number, indicating the direction in which it influences the outcome and the strength of that influence. A large positive number indicates a strong influence toward departure; a negative number indicates an influence toward retention.

**A gradient boosting model.** Rather than a single equation, this method constructs several hundred small decision rules in sequence, each correcting the errors of those preceding it. It is capable of identifying more complex patterns — for instance, that a high monthly charge is significant only for customers able to terminate at any time.

### The selection was determined in advance of the results

**The logistic regression was the intended production model throughout, on the grounds that its reasoning can be explained.**

Because each item of information carries a single readable number, any individual prediction can be traced to the factors which produced it. A customer was identified as at risk on the basis of their contract type, their monthly charge and their tenure, in stated proportions which any party may inspect.

Within a bank or a telecommunications provider this is not a matter of preference but of requirement. A customer may ask why a particular decision was reached concerning them. A regulator may require the institution to demonstrate that the decision rested on defensible grounds. **A model whose reasoning cannot be presented cannot satisfy that requirement**, irrespective of its accuracy.

The gradient boosting model was nevertheless constructed. A stated preference for the simpler method carries weight only where the more complex alternative has been built and measured. In the absence of that comparison, the selection appears to represent an avoidance of difficulty rather than a considered decision.

---

## 1. Determining the information available to the model

Not every item of information is appropriate for inclusion within a model. Four categories were deliberately excluded, on four separate grounds.

**The customer reference number.** This identifies a customer but describes nothing about them, and cannot contribute to predicting behaviour.

**The departure outcome.** This is the item being predicted and cannot simultaneously serve as an input.

**All information relating to customer value.** The calculated value, the profit realised to date, the expected remaining tenure and the value group were all excluded. This is the most consequential of the four exclusions.

The reasoning is central to the project. **Likelihood of departure and customer worth constitute two separate questions.** The model addresses the first. Stage Two addressed the second. The two are combined only at Stage Four, at the point where a decision regarding intervention is taken.

Were customer value supplied to the model as an input, that separation would be lost. The model's output would already incorporate value information. It would then be impossible to demonstrate that ranking customers by value produces a different, and superior, list to ranking them by risk. The central argument of the project would be forfeited.

**Information recorded more than once.** Four further fields repeat information already present: the banded form of tenure, the banded form of monthly spend, contract type expressed in words rather than as a ranking, and the internet indicator, which is already contained within the internet service field.

Supplying a model with the same fact twice produces a specific difficulty, examined in Section 5 below. In summary, the model apportions the effect between the duplicated items on an essentially arbitrary basis, and the resulting numbers cease to be reliable. As the readability of those numbers constitutes the entire justification for selecting this model, the duplicates were removed. The banded forms remain within the database for reporting purposes, where grouping is the intended treatment.

**Conversion of text values into numeric form.** Internet service is recorded as text: DSL, fibre optic, or none. A model cannot interpret text, so these values were converted into numeric columns.

One of the three was deliberately omitted. Where a customer holds neither fibre nor "none", they necessarily hold DSL, so the third column contributes no information and would reintroduce the duplication described above. DSL therefore serves as the baseline, and the remaining two columns are interpreted as differences from it.

**Nine measures were carried into the model.**

---

## 2. Separating the data before training

The customers were divided into two groups. The model learns from the first and is evaluated against the second, which it does not encounter during training.

**This separation is what renders the evaluation meaningful.** A model evaluated against the same records from which it learned may simply reproduce what it has memorised, reporting a level of performance it could not achieve against customers it had not previously encountered.

Three settings were applied.

**One quarter of customers were withheld** — 5,282 records used for training, and 1,761 reserved for evaluation.

**Both groups were required to hold the same proportion of departed customers.** Across the full dataset, 26.5 percent of customers departed. Without this setting, a random division could readily produce an evaluation group containing an unrepresentative proportion of departed customers, rendering every subsequent measurement misleading. Both groups returned 26.5 percent, confirming the setting operated correctly.

**The division was fixed so that it reproduces identically.** Any party re-running the notebook obtains the same division and therefore the same figures, and is able to verify them. Without this setting, the reported figures would vary slightly on each execution and could not be independently confirmed.

---

## 3. Training the model

Three measures were applied during training, each addressing a specific difficulty.

**Placing the measures on a common scale.** The measures are recorded in substantially different units. Total charges extend into the thousands, whereas the count of additional services ranges from zero to six.

Without adjustment, the model would treat the larger figures as more influential purely by virtue of their magnitude. Scaling places every measure on equivalent footing, ensuring the resulting numbers reflect genuine influence rather than the unit of measurement.

**Combining the scaling and the model into a single process.** This addresses correctness rather than convenience. The scaling must be derived from the training data alone and subsequently applied unchanged to the evaluation data. Performing the two operations separately makes it straightforward to scale all data together, which permits information from the evaluation set to influence training and inflates the reported performance.

**Correcting for the imbalance between the two outcomes.** Only 26.5 percent of customers departed. A model optimising for overall accuracy could therefore achieve 73.5 percent simply by predicting that no customer ever departs. That result is arithmetically correct and commercially worthless.

The model was instructed to treat a missed departure as a more serious error than a false identification, in proportion to the relative infrequency of departures.

---

## 4. Evaluating performance

### The measures applied

**Precision** — of the customers identified by the model as at risk, the proportion who genuinely departed. Low precision indicates that retention expenditure is being directed toward customers who were not in fact leaving.

**Recall** — of the customers who genuinely departed, the proportion the model identified. Low recall indicates that customers are being lost without warning.

These two measures operate against one another. Identifying more customers captures more genuine departures but incurs greater wasted expenditure. Identifying fewer reduces waste but permits more losses. **The balance between them constitutes a commercial decision rather than a technical one**, and it is precisely the decision Stage Four exists to inform.

**ROC AUC** — a single figure between 0.5 and 1.0 describing how effectively the model distinguishes departing customers from those who remain. A figure of 0.5 indicates performance no better than random selection. Approximately 0.84 represents the established range for this dataset. A figure approaching 1.0 would indicate that information concerning the outcome had reached the inputs.

### Results

**ROC AUC: 0.840** — within the expected range, confirming that no information concerning the outcome had leaked into the inputs.

Of the 1,761 customers withheld for evaluation, 467 genuinely departed. The model:

- **Identified 370 of them**
- **Failed to identify 97**
- **Flagged 732 customers in total**, meaning **362 identifications** related to customers who remained

This equates to **79.2 percent recall** and **50.5 percent precision**.

### Interpretation in commercial terms

Approximately four in every five departing customers are identified. For each genuine departure identified, roughly one additional customer is flagged unnecessarily.

Whether this represents sound commercial practice depends entirely upon the cost of contacting a customer relative to that customer's value. For a customer within the highest value group, worth R1,044, expenditure of R340 on a false identification is comfortably absorbed. For a customer within the lowest group, worth R81, the same expenditure destroys value even where the intervention succeeds.

**This is the reason Stage Four exists**, and the reason the model's output is retained as a probability rather than a binary determination. A probability may be weighed against a value; a binary determination cannot.

### A deliberate observation regarding accuracy

**Overall accuracy was recorded at 73.9 percent** — marginally below the 73.5 percent obtainable by predicting that no customer ever departs.

Assessed on that measure alone, the model appears to perform worse than taking no action whatsoever. In practice it identifies four in every five departing customers.

Any model addressing a relatively infrequent event produces this pattern. Reporting accuracy in isolation would have indicated that a functioning model should be abandoned, which is why precision and recall are reported in its place.

---

## 5. Examining the model's reasoning

As this is a logistic regression, each measure carries a single number indicating its influence. These were printed and examined.

A positive number indicates influence toward departure; a negative number indicates influence toward retention. As all measures were placed on a common scale, the magnitudes may be compared directly against one another.

### Results consistent with the Stage Two findings

| Measure | Value | Interpretation |
|---|---|---|
| Monthly charge | **+1.84** | A higher monthly charge is the strongest influence toward departure |
| Contract risk | +0.73 | Month-to-month customers depart more frequently |
| Tenure | **−1.22** | Longer-standing customers depart less frequently |
| Additional services held | −0.82 | Each additional service reduces the likelihood of departure |

Each of these corresponds to a finding already produced independently at Stage Two, using entirely separate methods. That correspondence itself constitutes a check upon the work.

### Two results which were not coherent

**Total charges, at +0.57**, indicated that customers who have paid more across their lifetime are *more* likely to depart. This directly contradicts the tenure result, which indicates the opposite. Both cannot be correct.

**Fibre optic, at −0.27**, indicated that fibre customers depart *less frequently*, when fibre customers are known to constitute the highest-departure population within this dataset.

### The cause

**Two of the measures overlapped with others already present.**

Total charges is approximately the monthly charge multiplied by the number of months the customer has held an account. It introduces no new information, consisting of two measures already within the model combined together.

Where two measures carry the same underlying information, the model apportions the effect between them on an essentially arbitrary basis. **The predictions themselves remain sound** — which is why the figure of 0.840 is genuine — but the individual numbers cease to be dependable.

As those numbers constitute the entire justification for selecting this model, the position could not be left unaddressed.

---

## 6. Removing the duplicated measure and refitting

Total charges was removed and the model retrained.

**The figure moved from 0.840 to 0.838.** Effectively unchanged, confirming that the measure contributed nothing beyond confusion. Its removal therefore represents a decision which can be defended, rather than a loss requiring explanation.

**More significantly, the tenure result corrected itself**, moving from −1.22 to −0.74. That movement constitutes the evidence. Its value had been distorted by the duplicated measure and settled once the duplication was removed.

### The fibre result, correctly interpreted

The fibre result remained negative. On investigation this proved not to be a defect.

**A result of this kind always describes an effect while all other factors are held constant.** A value of −0.28 therefore does not indicate that fibre customers depart less frequently. It indicates that, comparing a fibre customer and a DSL customer *paying an identical monthly amount*, the fibre customer is marginally less likely to depart.

This was verified directly against the data:

| Internet service | Customers | Proportion departed |
|---|---|---|
| Fibre optic | 3,096 | **41.9%** |
| DSL | 2,421 | 19.0% |
| None | 1,526 | 7.4% |

Fibre customers do depart at more than twice the DSL rate. They also pay considerably more, and the monthly charge has already accounted for that effect. **The model has separated the influence of price from the influence of the product itself.**

---

## 7. Constructing the comparison model

The gradient boosting model was then trained upon the same nine measures.

No scaling was applied. This category of model divides the data at threshold points rather than measuring distances between values, so differences in units do not affect it.

### The initial comparison was not valid

The first attempt produced a figure of 0.829 and recall of 48.6 percent, apparently substantially inferior to the logistic regression.

**The comparison was, however, weighted in favour of the preferred model.** The logistic regression had been given the imbalance correction described in Section 3. The gradient boosting model had not.

It was therefore optimising for overall accuracy, which upon data of this composition means favouring the prediction that customers will remain. This accounts entirely for its low recall. The comparison was measuring a difference in configuration rather than a difference in method.

**The invalid comparison is retained within the notebook rather than deleted**, as the correction is more instructive than a clean result would have been.

---

## 8. The comparison conducted on equivalent terms

The gradient boosting model was retrained with the same imbalance correction applied.

| Measure | Logistic regression | Gradient boosting |
|---|---|---|
| ROC AUC | **0.838** | 0.833 |
| Departures identified | **79.2%** | 76.2% |
| Precision | 50.5% | 50.7% |
| Reasoning available for inspection | **Yes** | No |

**The simpler model returned marginally superior results on both headline measures, and it is the model whose decisions can be explained.**

This represents an unusually favourable outcome. The customary argument is that a modest reduction in performance is an acceptable exchange for transparency. Here there is no reduction to defend.

**One necessary qualification.** The two results are sufficiently close that a different random division of the data could reverse the ordering. The defensible claim is therefore not that the logistic regression is superior, but that **the additional complexity of gradient boosting delivers no measurable benefit upon this dataset** — and where complexity delivers no benefit, the explainable model is the correct selection.

---

## Findings arising from the model

### Finding 1 — Price is the strongest single influence upon departure

The monthly charge carries the largest value of any measure — greater than contract type, greater than tenure, and greater than the number of services held.

**Commercial implication.** A retention discussion which does not address the customer's bill is addressing the second-order problem. Contract type and length of relationship are both material, but the amount a customer pays each month influences their decision more than any other factor measured here.

It also establishes a boundary upon what the business is able to address. A portion of this risk cannot be managed through improved service or increased contact. A customer departing because their bill is too high departs for a reason which only a pricing decision can resolve.

### Finding 2 — Fibre presents a pricing problem rather than a product problem

Fibre customers depart at 41.9 percent, more than twice the DSL rate of 19.0 percent. Assessed on that figure alone, the natural conclusion is that a fault exists within the fibre service, and the natural response is an investigation into service quality.

The model demonstrates otherwise. Once price is held constant, fibre customers are marginally *less* likely to depart than DSL customers paying an equivalent amount. The elevated departure rate is explained by fibre customers paying more, not by the product itself.

**Commercial implication.** The appropriate response is a pricing review rather than a service investigation. These constitute substantially different exercises carrying substantially different costs, and the unadjusted departure figure directs attention toward the wrong one.

This represents the clearest demonstration within the project of why an explainable model justifies its selection. A model producing only a probability would have identified fibre customers as high risk and proceeded no further. The individual results establish *why*, and the reason determines the appropriate commercial response.

### Finding 3 — Approximately half of any retention expenditure will reach customers who were not departing

The model identifies 79.2 percent of departing customers. It also flags approximately one additional customer for every genuine departure identified.

**This does not constitute a defect requiring correction. It is the operating condition**, and it holds for any model constructed upon data of this nature. Departure cannot be predicted with certainty from a customer profile, as the decision depends upon circumstances the business cannot observe — a competitor's offer, a change of residence, an alteration in household income.

**Commercial implication.** The decision to intervene cannot rest upon the model's output alone. Contacting an identified customer incurs the same cost whether or not that customer intended to depart. The operative question is therefore always whether the value protected justifies the total expenditure, including the proportion which will be wasted.

**The model establishes who is at risk. It cannot establish who is worth retaining.** That constitutes a separate question, and it is precisely why customer value was excluded from the model and addressed independently.

### Finding 4 — The additional complexity delivered no benefit

The customary argument for selecting an explainable model is that a modest reduction in performance represents a fair exchange for transparency. Upon this dataset there is no reduction to weigh: 0.838 against 0.833.

**Commercial implication.** Within a regulated environment the explainable model would have been the correct selection even at a modest disadvantage, as a decision which cannot be explained cannot be defended to a customer or a regulator. Here the selection carries no cost whatsoever.

A broader observation is warranted. **The substantive gains within this project arose from understanding the data** rather than from the selection of algorithm — correcting the recording issue at Stage Two, removing the duplicated measure at this stage, and maintaining the separation between value and risk throughout.

---

## Summary of findings

| Work undertaken | Outcome |
|---|---|
| Nine measures selected, all value information deliberately excluded | Risk and worth preserved as two separate questions |
| Data divided into training and evaluation groups, proportions preserved | Both groups at 26.5% departed |
| Logistic regression trained with the imbalance corrected | Figure of 0.840, with 79.2% of departures identified |
| The model's reasoning examined | Two results behaved incoherently and were investigated |
| Duplicated measure removed | Performance unchanged; a distorted result corrected itself |
| Fibre result investigated rather than accepted | Found correct once properly interpreted; price identified as the underlying cause |
| Gradient boosting constructed and compared | Initial comparison found to be invalid, and corrected |
| Final comparison conducted on equivalent terms | 0.838 against 0.833 — the additional complexity delivers no benefit |

**Model selected:** the logistic regression, on the grounds that its decisions can be explained — a selection which, upon this dataset, carries no cost in performance.

**Next stage:** determine which customers justify the cost of intervention.

---

## Constraints of the dataset

The dataset constitutes a single point-in-time snapshot. Each record describes one customer at one moment, containing no dates and no record of how that customer's behaviour altered over time.

**This constrains what may legitimately be claimed.** The model cannot state which customers will depart within the next ninety days, as such a claim requires observation across a defined period and this dataset contains no time dimension.

What the model may legitimately state is narrower: whether a customer's present profile resembles the profiles of customers who have already departed.

A production system operating within a telecommunications provider or a financial institution would be constructed differently. It would employ a defined observation window and monitor behavioural change — declining usage, increased contact with support functions, late payment, cancellation of individual products. These constitute the earliest indicators of intended departure, and none are present within this dataset.

The constraint is stated here rather than left for a reader to identify. A limitation which has been recognised and articulated demonstrates command of the method; one which goes unmentioned reads as an oversight.

---

## Concluding principle

Two elements of this stage were initially incorrect: a result which contradicted an established finding, and a model comparison weighted toward the preferred outcome.

Both were identified, corrected, and retained visibly within the record rather than removed.

A model reporting a favourable result is commonplace. A model whose author is able to demonstrate what was examined, what proved incorrect, and how the error was identified is the model which can be relied upon.
