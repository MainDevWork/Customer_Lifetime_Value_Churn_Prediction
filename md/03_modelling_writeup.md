# Model Development: Building, Testing and Selecting a Churn Model

**Notebook:** `03_modelling.ipynb`
**Purpose:** Build two churn prediction models, compare them under equal conditions, and select one to carry forward — with the reason for the choice stated in advance.

---

## Why this stage exists

The previous stage produced a database of 7,043 customers with seven derived features and a calculated lifetime value for each.

This stage answers one question: **given what we know about a customer today, how likely are they to leave?**

Two models are built. A logistic regression, and a gradient boosting classifier. Both are measured under identical conditions and one is selected.

### The choice is stated before the results, not after

**Logistic regression is the intended production model, and the reason is explainability.**

A logistic regression produces one number for each feature, showing the direction and size of its effect. Any individual prediction can therefore be traced back to the reasons behind it: this customer was flagged because of their contract type, their monthly charge, and their tenure, in these proportions.

In a regulated financial environment this is not a preference. A customer may ask why a decision was made about them, and a regulator may require the institution to demonstrate that the decision was made on defensible grounds. A model that cannot be explained cannot meet that requirement.

Gradient boosting is built regardless. A stated preference for the simpler model only carries weight if the more complex alternative was actually measured. Without the comparison, the choice appears to be an avoidance of difficulty rather than a decision.

---

## Step 1 — Loading the features

The completed feature table was read from the database in a single query. 7,043 rows, 18 columns.

No preparation was performed at this point — no cleaning, no reshaping, no calculation. Every feature was derived in SQL in the previous stage and arrives ready for use.

This is worth noting explicitly, because the absence of work here is the result of work done earlier. The database performs the transformation; the modelling layer consumes a finished result.

---

## Step 2 — Deciding what the model is allowed to see

Not every available column belongs in a model. Four groups were excluded, for four different reasons.

### The identifier

`customer_id` labels a customer but describes nothing about them. It cannot help predict behaviour.

### The target

`churn_value` records whether the customer left. It is the thing being predicted and cannot also be an input.

### The customer value fields

`clv`, `historic_margin`, `expected_remaining_months` and `value_decile` were all excluded, and this exclusion is central to the project.

**Churn risk and customer value are two separate questions.** The model answers the first: how likely is this customer to leave. The economics layer answers the second: what is this customer worth. The two are combined afterwards, at the point where a decision is made about whether to act.

If customer value were fed into the model as an input, that separation would collapse. The model's output would already contain value information, and it would no longer be possible to demonstrate that ranking by value produces a different — and better — retention list than ranking by risk. The argument the project is built on would be lost.

### Duplicated fields

Four further fields were removed because they repeat information already present:

- `tenure_band` is `tenure_months` in grouped form
- `spend_band` is `monthly_charges` in grouped form
- `contract` is `contract_risk` expressed in words
- `has_internet` is already contained within `internet_service`, one of whose values is "No"

Supplying the same information twice causes a specific problem, examined in detail below. In short: the model divides the effect between the duplicated fields in an arbitrary way, and the resulting numbers can no longer be read reliably — which would defeat the purpose of choosing an explainable model.

The grouped fields remain in the database for reporting, where grouping is exactly what is wanted.

### Converting text to numbers

`internet_service` holds three text values: DSL, fibre optic, and none. A model cannot read text, so these were converted into numeric columns.

One of the three was deliberately removed. With two of them known, the third is implied — if a customer is not on fibre and not on "none", they must be on DSL. Retaining all three would reintroduce the duplication described above. DSL therefore becomes the baseline, and the two remaining columns are read as differences from it.

**Nine features carried forward.**

---

## Step 3 — Separating training data from test data

The customers were divided into two groups. The model learns from one and is measured on the other, which it never sees during training.

**This separation is what makes the measurement meaningful.** A model evaluated on the same records it learned from can simply reproduce what it has memorised. It would report a level of performance it could not repeat on customers it had never encountered.

Three settings were applied:

**A quarter of customers held back.** 5,282 for training, 1,761 for measurement.

**The churn proportion preserved in both groups.** 26.5% of all customers churned, and both groups were forced to hold that same proportion. Without this, a random division could produce a test group with an unrepresentative share of departing customers, and every figure measured against it would be misleading. Both groups came out at 0.265, confirming this worked.

**The division fixed so it repeats identically.** Anyone re-running the notebook obtains the same split and the same results, and can therefore verify them. Without this, the reported figures would shift slightly on every run and could not be checked.

---

## Step 4 — Training the logistic regression

Three components were used, each addressing a specific problem.

### Placing features on a common scale

The features are measured in very different units. Total charges run into the thousands; the add-on count runs from zero to six.

Left unadjusted, the model treats the larger numbers as more influential purely because they are larger. Scaling places every feature on the same footing, so the resulting numbers reflect genuine influence rather than the unit of measurement.

### Combining the steps into a single process

The scaling and the model were bundled together into one object. This is a correctness measure, not a matter of tidiness.

The scaler must learn its adjustments from the training data alone, then apply them to the test data. Performing the steps separately makes it easy to scale all the data at once — which allows information from the test set to influence the training, and quietly inflates the reported performance.

### Correcting for the imbalance

Only 26.5% of customers churned. A model optimising for overall accuracy could therefore score 73.5% by predicting that nobody ever leaves — a result that is arithmetically correct and commercially worthless.

The model was instructed to treat a missed churner as a proportionately more serious error than a false alarm.

---

## Step 5 — Measuring performance

### The measures used

**Precision** — of the customers the model flagged, what share genuinely churned. Low precision means retention money is spent on customers who were never going to leave.

**Recall** — of the customers who genuinely churned, what share the model identified. Low recall means customers are lost with no warning.

These two measures move against one another. Flagging more customers catches more leavers but wastes more money; flagging fewer wastes less but misses more. **The balance between them is a commercial decision, not a technical one** — and it is precisely the decision the lifetime value layer exists to inform.

**ROC AUC** — a single figure between 0.5 and 1.0 describing how well the model separates departing customers from staying customers overall. Approximately 0.84 is the established range for this dataset. A figure close to 1.0 would indicate that information about the outcome had leaked into the inputs.

### The result

**ROC AUC: 0.840** — within the expected range, confirming nothing has leaked.

Of the 1,761 held-back customers, 467 genuinely left:

- The model identified **370** of them
- It missed **97**
- It flagged **732 customers in total**, meaning **362 flags** were raised on customers who stayed

That is **79.2% recall** and **50.5% precision**.

### Stated commercially

Approximately four out of every five departing customers are identified. For each genuine churner found, roughly one additional customer is flagged unnecessarily.

Whether that represents a sound investment depends entirely on what an intervention costs relative to what the customer is worth. For a customer in the top value decile, worth R1,044, spending R340 on a false alarm is easily absorbed. For a customer in the bottom decile, worth R81, the same intervention destroys value even when it succeeds.

**That is why the economics layer exists**, and why the model's output is kept as a probability rather than a yes-or-no answer.

### A deliberate observation on accuracy

**Overall accuracy came out at 73.9%** — marginally *below* the 73.5% obtainable by predicting that no customer ever churns.

This is retained rather than omitted, because it demonstrates directly why accuracy is the wrong measure for problems of this kind. A model that appears to perform worse than doing nothing is in fact identifying four out of five departing customers.

---

## Step 6 — Reading the coefficients, and finding a problem

The coefficient attached to each feature was printed. This is the practical benefit of logistic regression: the model's reasoning is fully visible.

A positive number pushes toward churn; a negative number pulls away from it. Because all features were placed on a common scale, the sizes can be compared directly.

### Consistent with the SQL findings

| Feature | Coefficient | Meaning |
|---|---|---|
| `monthly_charges` | **+1.84** | Higher monthly cost is the strongest driver of churn |
| `contract_risk` | +0.73 | Month-to-month customers leave more |
| `tenure_months` | **−1.22** | Longer-standing customers leave less |
| `addon_count` | −0.82 | Each additional service held reduces churn |

Every one of these matches a finding already established in SQL, independently. That agreement is itself a check on the work.

### Two coefficients that did not make sense

**`total_charges` at +0.57** stated that customers who have paid more over their lifetime are *more* likely to leave. That directly contradicts `tenure_months`, which stated the opposite. Both cannot be true.

**Fibre optic at −0.27** stated that fibre customers leave *less*, when fibre customers are known to be the highest-churn group in this dataset.

### The cause

**The features overlapped with one another.**

`total_charges` is approximately `monthly_charges` multiplied by `tenure_months`. It introduces no new information — it is two existing features combined.

When features carry overlapping information, the model distributes the effect between them arbitrarily. **The predictions remain sound**, which is why the ROC AUC of 0.840 is genuine. But the individual numbers stop being reliable — and those numbers are the entire justification for selecting this model.

---

## Step 7 — Removing the duplicate and refitting

`total_charges` was removed and the model retrained.

**ROC AUC moved from 0.840 to 0.838.** Effectively unchanged, confirming the feature contributed nothing beyond confusion. Its removal is a decision that can be defended rather than a loss to be explained.

**More significantly, `tenure_months` corrected itself** — from −1.22 to −0.74. That movement is the evidence. Its value had been distorted by the duplicated feature, and settled once the duplication was removed.

### The fibre coefficient, correctly interpreted

The fibre coefficient remained negative, and this turns out not to be a fault.

**A coefficient always describes an effect while holding everything else constant.** A value of −0.28 therefore does not say that fibre customers churn less. It says: comparing a fibre customer and a DSL customer *paying the same monthly amount*, the fibre customer is slightly less likely to leave.

This was verified directly against the data:

| Internet service | Customers | Churn rate |
|---|---|---|
| Fibre optic | 3,096 | **41.9%** |
| DSL | 2,421 | 19.0% |
| None | 1,526 | 7.4% |

Fibre customers do churn at more than twice the DSL rate. But they also pay more, and monthly charges have already accounted for that effect. The model has separated the influence of price from the influence of the product.

**The commercial implication is specific: the problem lies in fibre pricing, not in the fibre product.**

---

## Step 8 — Building the comparison model

Gradient boosting was trained on the same features.

Rather than fitting a single equation, it constructs a large number of small decision rules in sequence, each correcting the errors of the ones before it. This allows it to capture patterns a single equation cannot — for example, that high charges matter only for customers on month-to-month contracts.

No scaling was applied. This type of model divides the data at thresholds rather than measuring distances between values, so differences in units do not affect it.

### The first comparison was not valid

The first attempt produced ROC AUC of 0.829 and recall of 48.6% — apparently far worse than the logistic regression.

**But the comparison was rigged, unintentionally, in favour of the preferred model.** The logistic regression had been given the imbalance correction described in Step 4. The gradient boosting model had not. It was therefore optimising for overall accuracy, which on imbalanced data means quietly favouring "will not churn" — hence the low recall.

The failed comparison is retained in the notebook rather than deleted, because the correction is more instructive than a clean result would have been.

---

## Step 9 — The comparison, conducted fairly

The gradient boosting model was retrained with the same imbalance correction applied.

| Measure | Logistic regression | Gradient boosting |
|---|---|---|
| ROC AUC | **0.838** | 0.833 |
| Recall — churners identified | **79.2%** | 76.2% |
| Precision | 50.5% | 50.7% |
| Can individual decisions be explained | **Yes** | No |

**The simpler model performs marginally better on both headline measures, and it is the one whose decisions can be explained.**

This is an unusually clean outcome. The normal argument is that a small loss in performance is worth the gain in explainability. Here there is no loss to defend.

### A necessary qualification

The two results are close enough that a different random division of the data could reverse the ordering.

The defensible claim is therefore not that logistic regression is superior. It is that **the additional complexity of gradient boosting delivers no measurable benefit on this data** — and where complexity buys nothing, the explainable model is the correct choice.

---

## What the model shows

The preceding sections describe how the model was built and tested. This section sets out what it revealed.

### 1. Price is the strongest single driver of churn

`monthly_charges` carries the largest coefficient of any feature — larger than contract type, larger than tenure, larger than the number of services held.

**What this means commercially.** A retention conversation that does not address the bill is addressing the second-order problem. Contract type and tenure matter, but the amount a customer pays each month influences their decision to leave more than anything else measured here.

It also sets a limit on what the business can do. Some of this risk is not manageable through service improvement or engagement. A customer leaving because the bill is too high leaves for a reason only a pricing decision can address.

### 2. Fibre has a pricing problem, not a product problem

Fibre customers churn at 41.9%, more than twice the DSL rate of 19.0%. On that figure alone, the natural conclusion is that something is wrong with the fibre service.

The model shows otherwise. Once price is held constant, fibre customers are marginally *less* likely to leave than DSL customers paying the same amount. The high churn is explained by the fact that fibre customers pay more, not by the product itself.

**What this means commercially.** The correct response is a pricing review, not a service investigation. Those are materially different exercises with materially different costs, and the raw churn figure points to the wrong one.

This is the clearest example in the project of why an explainable model is worth having. A model producing only a probability would have flagged fibre customers as high risk and stopped there. The coefficients identify *why*, and the why determines what the business should actually do.

### 3. Half of any retention spend will be directed at customers who were never leaving

The model identifies 79.2% of departing customers. It also flags roughly one additional customer for every genuine churner it finds — precision of 50.5%.

**This is not a fault to be corrected. It is the working condition**, and it holds for any model on this kind of data. Churn cannot be predicted with certainty from a customer profile, because the decision to leave depends on circumstances the business cannot observe.

**What this means commercially.** The decision to intervene cannot rest on the model's output alone. Contacting a flagged customer costs the same whether or not they were going to leave, so the question is always whether the value protected justifies the total spend — including the half that will be wasted.

For a customer in the top value decile, worth R1,044, an intervention costing R340 pays for itself even at a 50% waste rate. For a customer in the bottom decile, worth R81, the same intervention loses money even when it succeeds.

**The model identifies who is at risk. It cannot determine who is worth keeping.** That is a separate question, answered by the value layer, and this is precisely why the two were kept apart.

### 4. Accuracy would have given a misleading picture

Overall accuracy is 73.9% — marginally below the 73.5% obtainable by predicting that no customer ever leaves.

By that measure the model appears worse than doing nothing. In fact it identifies four out of every five departing customers.

**What this means commercially.** Any model of a rare event will produce this pattern, and reporting accuracy alone would suggest abandoning a model that works. Recall, precision and the trade-off between them are the measures that describe what the model is actually worth.

### 5. The added complexity delivered no benefit

| Measure | Logistic regression | Gradient boosting |
|---|---|---|
| ROC AUC | 0.838 | 0.833 |
| Churners identified | 79.2% | 76.2% |

The usual argument for an explainable model is that a small loss in performance is worth the gain in transparency. On this data there is no loss to weigh.

**What this means commercially.** In a regulated environment the explainable model would have been the correct choice even at a modest disadvantage, because a decision that cannot be explained cannot be defended to a customer or a regulator. Here that choice carries no cost at all.

The finding also carries a general lesson worth stating: the substantial gains in this project came from understanding the data — the encoding correction, the removal of a duplicated feature, the separation of value from risk — not from the choice of algorithm.

---

## Summary of this stage

| # | What was done | Outcome |
|---|---|---|
| 1 | Nine features selected, value fields deliberately excluded | Churn risk and customer value kept as separate questions |
| 2 | Data divided into training and test groups, proportions preserved | Both groups at 26.5% churn |
| 3 | Logistic regression trained with imbalance correction | ROC AUC 0.840, 79.2% of departing customers identified |
| 4 | Coefficients inspected | Two behaved unexpectedly and were investigated |
| 5 | Duplicated feature removed | Performance unchanged; a distorted coefficient corrected itself |
| 6 | Fibre coefficient investigated rather than accepted | Found correct once properly interpreted; price identified as the driver, not the product |
| 7 | Gradient boosting built and compared | First comparison found to be unfair and corrected |
| 8 | Final comparison under identical conditions | 0.838 against 0.833 — complexity delivers no benefit |

**Model carried forward:** logistic regression, on grounds of regulatory explainability — a choice that, on this data, costs nothing.

**Next stage:** the intervention economics layer, combining these churn probabilities with the lifetime values derived in SQL to determine which customers are commercially worth retaining.

---

## Known limitation, stated openly

This dataset is a single point-in-time snapshot. Each row describes one customer at one moment, with no dates and no history of how their behaviour changed.

**This limits what the model can honestly claim.** It cannot state that it predicts which customers will leave in the next ninety days, because there is no observation period in the data to support such a claim. What it can state is that, given a customer's current profile, it identifies whether that profile resembles those of customers who have already left.

A production system inside a telecommunications provider or a bank would be built differently. It would use a defined time window and behavioural indicators — declining usage, increased contact with support, late payments, changes in the products held — which are the strongest early warnings of departure and are entirely absent from this data.

The constraint is stated here rather than left to be discovered. A limitation that has been identified and articulated demonstrates understanding of the method; one that has not been mentioned is simply a gap.

---

## The principle underlying this stage

Two things in this stage were wrong at first: a coefficient that contradicted an established finding, and a model comparison weighted in favour of the preferred outcome.

Both were found, corrected, and left visible in the record rather than tidied away.

A model that reports a good result is common. A model whose author can show what they checked, what they got wrong, and how they found it is the one that can be relied upon.
