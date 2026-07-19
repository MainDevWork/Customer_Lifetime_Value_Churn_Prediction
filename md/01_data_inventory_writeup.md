# Stage One — Data Inventory and Reliability Assessment

**Notebook:** `01_data_inventory.ipynb`

---

## Project overview

Telecommunications providers lose customers to competitors on a continuous basis. The industry term for this is **churn**. It represents a significant commercial cost, as acquiring a new customer is considerably more expensive than retaining an existing one.

The standard response is to predict which customers are most likely to leave, and to contact those customers with a retention offer.

This project undertakes that prediction, and then addresses a second question which most churn projects omit: **whether a given customer is worth the cost of retaining them.** For a substantial proportion of the customer base, the answer is no. The cost of contacting them exceeds the value they represent, and retaining them therefore destroys value rather than creating it.

The project consists of two components:

1. **A predictive model** estimating the likelihood that each customer will leave.
2. **A customer value calculation**, used to determine which customers justify the cost of intervention.

The work is delivered in four stages, each documented separately:

| Stage | Purpose |
|---|---|
| **One (this document)** | Assess the contents and reliability of the source data |
| Two | Construct the database, derive the required measures, and calculate customer value |
| Three | Build, test and select the predictive model |
| Four | Determine which customers justify intervention, and quantify the commercial return |

**This document is written to be read independently of the underlying code.** All work undertaken and all findings reached are set out in full below.

---

## The dataset

The project uses a publicly available dataset published by IBM, describing the customer base of a telecommunications provider in California. It contains **7,043 customers**, with **33 items of information recorded for each**.

Those items fall into five categories:

- **Customer characteristics** — gender, senior citizen status, whether the customer has a partner or dependants
- **Location** — city, postal code, geographic coordinates
- **Products held** — telephone line, internet service type, and six optional additional services including online security and streaming television
- **Financial information** — monthly charge, total amount paid to date, contract type, payment method
- **Outcome** — whether the customer has left, and if so, the reason recorded

Two further figures are supplied with the dataset, and both are material to this stage:

- **A churn score** — IBM's own estimate of each customer's likelihood of leaving
- **A customer lifetime value figure** — an estimate of the total worth of each customer to the business across the relationship

---

## Rationale for this stage

The two supplied figures identified above are the principal reason this assessment was undertaken.

Both appear authoritative, and both arrive already calculated, which represents a considerable saving in effort. The immediate temptation is to adopt them and proceed to the modelling work.

That course of action carries a specific risk. Where a supplied figure is unsound, all subsequent work built upon it is also unsound — and the defect remains concealed, because the figure carries an appearance of authority and is therefore not questioned. Such problems typically surface only at the point where a result must be explained or defended.

Three assessments were therefore carried out before any development work began:

1. **A structural review** — the number of records, the fields present, and the manner in which each field is stored
2. **An assessment of missing values** — where data is absent, and whether the absence can be accounted for
3. **A reliability test of the supplied figures** — whether they measure what they purport to measure

The third assessment produced the most significant finding of this stage. **Both supplied figures were tested, and both were rejected.** The grounds for rejection are set out below.

**A note on scope.** No data is altered at this stage. This notebook examines and records only. All corrections are applied at Stage Two, implemented in SQL, where they remain visible and open to inspection.

---

## 1. Structural review

The dataset was retrieved programmatically by the notebook rather than downloaded manually. This ensures that any party running the project obtains identical data from an identical source, with no dependency on a file held locally on an individual machine. Work which cannot be reproduced cannot be verified.

The complete version of the dataset was used in preference to the abridged version which circulates more widely. The abridged version omits the customer lifetime value figure, the recorded reason for departure, and the geographic detail, all of which are required by this project.

**Finding: 7,043 records across 33 fields, consistent with expectations.**

The full list of field names was printed before any further work was undertaken. This project depends upon the presence of specific fields; had any been absent, that needed to be established immediately rather than discovered after substantial work had been completed.

The first ten records were also displayed in order to establish the format of the values and identify any obvious irregularities.

---

## 2. Assessment of missing values

All fields were examined for missing values. **Only one field contains any: the recorded reason for departure, which is absent for 5,174 customers.**

On initial inspection this represents a substantial gap, affecting nearly three quarters of the dataset. Examination of the figures establishes that it is not.

The dataset contains 7,043 customers. Of these, **1,869 have departed**. This leaves **5,174 customers still with the business** — precisely the number of absent values.

The field is therefore populated only where a customer has actually departed. Where a customer remains with the business, no reason exists to be recorded. **The field is not incomplete; it is correctly empty.**

**No values were substituted, and the reasoning is material.**

Standard practice in much data preparation is to populate missing values automatically, typically with an average or a placeholder value, before establishing the cause of the absence. Applying that approach here would have fabricated a reason for departure for 5,174 customers who have not departed. All subsequent analysis involving that field would then have rested on invented data.

The principle demonstrated is that the cause of a gap should be established before any decision is taken regarding whether to fill it. In the majority of cases, understanding the cause establishes that the gap should be left as it is.

---

## 3. Review of field types

Each field is stored in a defined format — as a number, a date, or as text. A field containing monetary amounts should be stored as a number, so that it can be aggregated and averaged.

One field failed this requirement. **Monthly charges is stored as a number, whereas total charges is stored as text.** Both contain monetary amounts and both should therefore be numeric.

The cause of this behaviour is specific. Where a single entry within a column cannot be interpreted as a number, the entire column is treated as text. One unreadable value among 7,043 records is therefore sufficient to render the whole field unusable for calculation.

The expedient response would have been to convert the column in a single operation, discarding any values which failed. This was not done. Converting first and investigating afterwards destroys the evidence required to establish the underlying cause.

Each value was instead tested individually, and those which failed were isolated and examined.

**Finding: eleven records are affected, and all eleven share an identical profile:**

- Tenure of **zero months**
- A monthly charge on record
- **Active customer status**

The explanation follows directly. These are newly acquired customers who have agreed a price but have not yet been billed for a full cycle. No total charge exists because no charge has yet been raised.

**The blank value is therefore accurate rather than corrupt.** It records a genuine circumstance.

**Decision: substitute zero, and retain all eleven records.**

Zero is the correct figure, as these customers have genuinely paid nothing to date. Deleting the eleven records would have been the faster course, and is what commonly occurs in practice. It would also have removed the entire population of newly acquired customers from the analysis.

The consequence is greater than it first appears. As Stage Two establishes, newly acquired customers constitute the population most likely to depart. Their removal would have introduced a systematic bias into the analysis before the substantive work had commenced.

---

## 4. Reliability testing of the supplied customer lifetime value figure

Following the correction of field types, summary statistics were produced for each numeric field, comprising the minimum value, maximum value, average and distribution.

This produced the most significant finding of the stage.

**The supplied customer lifetime value figure has a minimum of 2,003 and a maximum of 6,500. Total charges — representing revenue already collected from customers — reaches 8,684.**

This combination is not possible. Customer lifetime value represents the total worth of a customer to the business across the entire relationship. It cannot be lower than revenue the business has already received from that customer. A figure recording a maximum worth of 6,500 for a customer who has already paid 8,684 is not denominated in currency.

The boundaries provide a second indication. No customer scores below 2,003, and none above 6,500. Genuine customer value does not exhibit this pattern. Any real customer base contains customers of negligible value and customers of exceptional value.

Two independent indications of unreliability were considered sufficient to warrant a formal test rather than a judgement.

### The basis of the test

Irrespective of the formula applied, customer lifetime value is determined by two variables: **the amount a customer pays per period**, and **the duration of the relationship**. Any legitimate lifetime value figure must therefore vary in accordance with both. A long-standing customer paying a high monthly charge must be ranked above a recently acquired customer paying a low one.

This provides a testable proposition: **does the supplied figure rank customers in the same order as its own constituent variables?**

### Method

The test applied **rank correlation**, a measure of whether two variables order a set of items in the same sequence. It disregards scale entirely.

Disregarding scale was the intention. The figure was already suspected of being expressed on an arbitrary scale, so testing the scale relationship would have established nothing. The narrower question was whether the figure ordered customers in a defensible sequence.

The result is expressed as a value between −1 and 1:

- A result approaching **1** indicates that the two measures rank customers almost identically
- A result approaching **0** indicates no relationship
- A result approaching **−1** indicates that they rank customers in opposing sequences

### Results

| Supplied figure tested against | Result | Expected for a valid measure |
|---|---|---|
| Tenure with the business | **0.37** | Strong positive |
| Total amount paid | **0.31** | Strong positive |
| Monthly charge | **0.11** | Strong positive |
| Whether the customer departed | **−0.12** | Clearly negative |

All four results fall materially below the threshold required. **The third result is determinative.**

The monthly charge is a direct and primary constituent of customer lifetime value. A doubling of the monthly charge should produce an approximate doubling of lifetime value. The recorded relationship is **0.11**, which indicates effectively no relationship at all.

A figure which responds only marginally to the amount customers pay is not calculating what customers are worth.

### Conclusion

Considered together — impossible boundaries, combined with negligible relationship to its own constituent variables — the conclusion is not in doubt.

**The supplied customer lifetime value figure is a score expressed on an arbitrary scale. It is not a currency measure, and it was rejected.**

Customer value is instead derived independently at Stage Two, calculated from actual monthly charges and actual tenure, with each assumption documented and open to challenge.

**The derived figure is deliberately not validated against the supplied figure.** Once a measure has been established as unreliable, it cannot serve as a benchmark for the work replacing it. To do so would reintroduce the defect just identified.

---

## 5. Fields excluded from the model

A predictive model identifies patterns within the information it is provided. Where it is provided with information which indirectly reveals the outcome, it will report excellent performance while having established nothing of value. This condition is known as **leakage**.

Three fields were excluded from the model on three distinct grounds. The distinction is material, as such fields are frequently grouped together without differentiation.

### The churn score — excluded on grounds of leakage

This field contains IBM's own prediction of customer departure, supplied with the dataset.

Its inclusion would mean the model was no longer predicting customer departure, but rather reproducing the conclusions of another model. Reported performance would be excellent, as the model would be replicating a supplied answer rather than identifying any underlying pattern.

A second objection carries greater weight in a regulated environment. IBM has not published the methodology behind the score. A model incorporating it could not be fully explained, as one of its principal inputs cannot be explained.

This project deliberately employs a model whose reasoning can be traced and presented to a regulator. Incorporating an unexplainable input would defeat that objective.

### The recorded reason for departure — excluded on grounds of leakage

This field records the reason a customer gave for leaving and, as established above, exists only for customers who have already departed.

Its use in prediction would establish only that any customer with a recorded reason has departed. That is accurate, without value, and does not constitute a prediction.

**The field is nevertheless retained within the database** and used in the reporting layer. The knowledge that most departing customers cite a competitor's offer is of genuine commercial value.

The distinction is between information a model may learn from and information a report may present. The field is legitimate for explaining departures which have occurred, and unsuitable for predicting departures which have not.

### The supplied customer lifetime value figure — excluded on grounds of unreliability

This exclusion rests on entirely separate grounds. The field does not reveal the outcome. It was excluded because, as demonstrated in Section 4, it does not measure what it purports to measure.

Stated concisely:

- **The churn score and the recorded reason for departure constitute valid information available at the wrong point in time.**
- **The supplied lifetime value figure does not constitute valid information at any point in time.**

### Fields carrying no information

Four further fields were removed on more straightforward grounds:

- One field records the value 1 for every customer
- One records "United States" for every customer
- One records "California" for every customer
- One combines latitude and longitude into a single text value, both of which are already present as separate numeric fields

A field holding an identical value across every record conveys no information and cannot contribute to any analysis.

---

## 6. A recording issue within the service fields

Six fields record optional additional services which a customer may hold: online security, online backup, device protection, technical support, streaming television and streaming films.

Each of these fields holds **three possible values rather than two**: "Yes", "No", and "No internet service".

**The third value is not a variant of "No", and treating it as such would represent a significant error.**

- **"No"** indicates that the service was offered and declined.
- **"No internet service"** indicates that the service was never available, as the customer holds no internet subscription.

The first customer exercised a choice. The second was never presented with one. They represent fundamentally different populations.

Most automated data preparation consolidates the third value into "No", as the two appear equivalent on inspection. Stage Two quantifies the cost of that assumption: the two populations prove to have departure rates differing by a factor of seven.

The fields were therefore retained exactly as supplied. The decision regarding their treatment is taken explicitly at Stage Two rather than absorbed into an automated preparation routine.

---

## Constraints of the dataset

The dataset constitutes a **single point-in-time snapshot**. Each record describes one customer at one moment. It contains no dates, no transaction history, and no record of how customer behaviour changed over time.

This constrains what may legitimately be claimed, and the constraint is stated here rather than left for a reader to identify.

**The model cannot state which customers will depart within the next ninety days.** A claim of that nature requires observation of customers across a defined period, and this dataset contains no time dimension.

What the model can legitimately state is narrower but remains commercially useful: whether a customer's present profile resembles the profiles of customers who have already departed.

A production system operating within a telecommunications provider or a financial institution would be constructed differently. It would employ a defined observation window and monitor behavioural change — declining usage, increased contact with support functions, late payment, cancellation of individual products. These constitute the earliest indicators of intended departure, and none are present within this dataset.

---

## Summary of findings

| Finding | Action taken |
|---|---|
| 7,043 customers across 33 fields, of whom 1,869 departed | Dataset confirmed as suitable for the project |
| Missing values confined to the recorded reason for departure, fully accounted for by departure status | Left unaltered — the absence is correct |
| Total charges stored as text owing to 11 unbilled new customers | Set to zero; all 11 records retained |
| Supplied lifetime value figure exhibits impossible boundaries and negligible relationship to its constituent variables | Rejected; value derived independently at Stage Two |
| Churn score and recorded reason for departure both reveal the outcome | Excluded from the model; reason retained for reporting purposes |
| Four fields hold an identical value across all records | Removed |
| Six service fields carry a third value denoting "never available" | Retained as supplied; addressed explicitly at Stage Two |

**Next stage:** construct the database, derive the required measures, and calculate customer value.

---

## Concluding principle

The dataset was supplied with a customer lifetime value figure already calculated and a churn prediction already produced. Both could have been adopted without comment, and the project would have progressed more rapidly as a result.

Both were tested. Both failed.

The work described above does not constitute data cleaning in the conventional sense. It represents a decision to establish whether supplied figures are sound before building upon them, and a willingness to discard them where they are not.
