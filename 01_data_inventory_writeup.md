# Data Inventory: Profiling the Source Dataset

**Notebook:** `01_data_inventory.ipynb`
**Purpose:** Establish what the source data contains, and whether it can be trusted, before any modelling decisions are made.

---

## Why this stage exists

The dataset used in this project is the IBM Telco Customer Churn extract: 7,043 customer records across 33 fields. It is a widely used public dataset, and it arrives with several fields already calculated — including a churn score and a customer lifetime value figure.

The temptation with a prepared dataset is to begin modelling immediately. This stage exists to resist that. Before a single feature is engineered, the data is examined for three things:

1. **Structure** — how many records, what fields, what type is each field held as
2. **Completeness** — where are values missing, and is the absence explicable
3. **Reliability** — do the supplied calculated fields actually measure what they claim to measure

The third point is the one that produced the most consequential finding in this project. Two fields supplied with the dataset were examined and subsequently excluded from the model. Had they been accepted at face value, the resulting model would have been both technically invalid and impossible to defend in a regulated environment.

A note on scope: this notebook is exploratory only. No transformation performed here is carried into the modelling pipeline. All joins, aggregation, feature engineering and lifetime value logic are implemented in SQL. The notebook establishes findings; the SQL layer acts on them.

---

## Step 1 — Retrieving the dataset

The dataset was downloaded programmatically via the `kagglehub` library rather than through a manual file download.

This is a deliberate choice. A programmatic download means the data acquisition step is reproducible: anyone running the notebook retrieves the identical dataset from the identical source, with no dependency on a file sitting on a particular machine. The path and the file listing are printed to confirm what was retrieved.

The full version of the dataset was used rather than the more commonly circulated abridged release. The abridged version omits the customer lifetime value field, the churn reason field, and the geographic detail — all of which are required for the customer value and segmentation work later in the project.

---

## Step 2 — Loading the file and confirming its structure

The workbook was loaded into a dataframe, and three things were printed immediately: the record count, the column count, and the full list of column names.

**Result: 7,043 rows, 33 columns.**

The purpose of printing the column list before doing anything else is to verify that the fields the project depends on are actually present. The customer value segmentation is the central component of this project; if the relevant fields were absent, that would need to be known at the outset rather than discovered several hours into the work. Confirming the contents is faster than assuming them.

The first ten records were also displayed to give a visual sense of the data — what the values look like, how categories are worded, and whether anything is obviously irregular.

---

## Step 3 — Reviewing field types and missing values

Two checks were run: the data type held by each field, and a count of missing values, filtered to show only fields where missing values actually occur.

### Missing values

**Result: missing values occur in exactly one field — `Churn Reason` — with 5,174 records affected.**

This number is not arbitrary, and the arithmetic confirms it. The dataset holds 7,043 customers. Of those, 1,869 have churned. That leaves 5,174 customers who have not churned — exactly matching the number of missing values.

The conclusion is that `Churn Reason` is populated only for customers who have actually left. For a customer who is still with the business, there is no reason for leaving, because they have not left. The field is not incomplete; it is correctly empty.

**No treatment was applied.** This matters. A common and damaging habit is to fill missing values automatically — substituting an average, or a placeholder — without first establishing why the values are missing. Here, filling them would have fabricated a departure reason for 5,174 customers who never departed. The correct response to a missing value is first to explain it, and only then to decide whether it requires action.

### Field types

**Result: `Monthly Charges` is stored as a number. `Total Charges` is stored as text.**

Both fields hold currency amounts. Both should be numeric. When a field that ought to be numeric is held as text, it is because at least one entry in that field cannot be read as a number — a single non-numeric value forces the entire column to be treated as text.

This is a data quality signal, and it was investigated rather than corrected on sight.

---

## Step 4 — Completing the type inventory

The initial type output was truncated in display, so the final ten fields were printed separately to ensure no field went unexamined.

This is a small step, but a necessary one. A truncated output means fields were not inspected, and an uninspected field is an assumption. The check confirmed the `Total Charges` finding and confirmed that no other field carried an unexpected type.

---

## Step 5 — Investigating the non-numeric entries

The `Total Charges` field could have been converted to numeric in a single line, with any unreadable values discarded. That was not done. Converting first and asking questions later would have destroyed the evidence needed to understand the problem.

Instead, the conversion was used diagnostically. Each value was tested for whether it could be read as a number, and any value that failed was flagged. The flagged records were then isolated and examined against the customer's tenure and churn status.

**Result: 11 records affected. Every one of them shares the same profile:**

- Tenure of **zero months**
- A monthly charge on record
- Still an **active** customer

The explanation follows directly. These are newly acquired customers who have signed up and have a monthly rate agreed, but who have not yet been billed for a full cycle. There is no total charged amount because nothing has been charged yet.

The blank is therefore **accurate, not corrupt**. It represents a real state of affairs rather than a data entry failure.

**Decision: substitute zero, and retain all 11 records.**

Zero is the truthful value — these customers have genuinely paid nothing to date. Deleting the records, which is the more common shortcut, would have removed the entire population of brand-new customers from the analysis. Since new customers are precisely the group most exposed to early churn, removing them would have introduced a bias into the model at the very first step.

---

## Step 6 — Correcting the field and summarising the numeric data

The conversion was applied, with zero substituted for the eleven unbilled accounts, and the field confirmed as numeric. Descriptive statistics were then produced for the core numeric fields — tenure, monthly charges, total charges, and the supplied CLTV figure.

Descriptive statistics here means the count, average, spread, minimum, maximum, and the quarter-point values of each field. The purpose is to see the shape and range of every numeric field at once.

**This is where the significant finding emerged.**

The supplied `CLTV` field ranges from a minimum of **2,003** to a maximum of **6,500**. Meanwhile, `Total Charges` — revenue that customers have *already paid* — reaches **8,684**.

That is a contradiction. Customer lifetime value is meant to represent the total worth of a customer to the business across the whole relationship. It cannot be lower than the money that customer has already handed over. A field claiming a customer is worth 6,500 at most, when that customer has already paid 8,684, is not measuring value in currency.

The floor is equally telling. No customer scores below 2,003, and none above 6,500. A genuine distribution of customer value would not be neatly bounded at both ends in this way. Real customer populations contain both very low-value and very high-value outliers.

This raised sufficient concern to warrant a formal test rather than a judgement call.

---

## Step 7 — Testing the reliability of the supplied CLTV field

### The reasoning behind the test

Customer lifetime value, however it is calculated, is fundamentally a function of two things: how much a customer pays per period, and how long they remain a customer. Any legitimate lifetime value measure must therefore move in step with monthly charges and with tenure. A long-standing customer paying a high monthly rate must score higher than a recent customer paying a low one. If it does not, it is not measuring lifetime value.

This gives a testable proposition: **does the supplied field order customers in the same way its own mathematical inputs would?**

### The method

Spearman rank correlation was used rather than Pearson correlation.

The distinction matters. Pearson correlation measures whether two fields move together on the same scale. Spearman measures only whether they **rank customers in the same order**, disregarding scale entirely. Since the supplied field was already suspected of being on an arbitrary scale, testing the scale relationship would have been meaningless. The relevant question was narrower: setting scale aside, does this field at least rank customers sensibly?

Correlation is expressed between −1 and 1. A value near 1 indicates two measures rank items almost identically; near 0 indicates almost no relationship; near −1 indicates they rank in opposite order.

### The result

| Field | Correlation with CLTV | What a valid measure would show |
|---|---|---|
| Tenure Months | **0.37** | Strong positive — longer tenure means higher value |
| Total Charges | **0.31** | Strong positive — more revenue means higher value |
| Monthly Charges | **0.11** | Strong positive — higher rate means higher value |
| Churn Value | **−0.12** | Clearly negative — departing customers are worth less |

Every correlation falls materially short of what the measure requires. The weakest is the most damaging: **monthly charges, at 0.11, is effectively no relationship at all.** What a customer pays every month is a direct and primary input to their lifetime value. A field that is nearly indifferent to it is not calculating lifetime value.

### The conclusion

Read together, the two findings are conclusive. The field is bounded in a way no genuine value distribution would be, it falls below revenue already collected for some customers, and it does not track the variables that define it.

**The supplied `CLTV` field is a synthetic score on an arbitrary scale, not a financial measure. It was rejected.**

Customer lifetime value is instead derived independently in the SQL layer, calculated from monthly charges, tenure, and an explicitly stated cost-to-serve assumption, with every assumption documented.

Critically, the derived figure is **not validated against the supplied field**. A rejected measure cannot serve as a benchmark for the measure replacing it. Checking new work against a reference already established as unreliable would simply reintroduce the fault.

---

## Fields excluded from the model, and why

Three fields were excluded from the feature set. The reasons differ, and the distinction between them is material.

### `Churn Score` — excluded as target leakage

This field is a churn prediction produced by IBM's own model and shipped with the dataset.

Using it as an input would mean building a model that predicts another model's predictions. The resulting model would appear to perform extremely well, because it would be reproducing an answer it was handed rather than learning anything about customer behaviour. This is known as **target leakage**: information that reveals the outcome finds its way into the inputs, and the model's apparent accuracy becomes an illusion.

There is a second objection, and in a regulated financial context it is the more serious one. The method behind IBM's score is not disclosed. A model built on top of it could not be explained, because a core input could not be explained. This project ships a logistic regression specifically because its decisions can be traced and audited. Building it on an opaque input would defeat that purpose entirely.

### `Churn Reason` — excluded as target leakage, retained for reporting

This field records why a customer left, and it exists only for customers who have already left.

Using it as a model input would mean the model has access to information that only becomes available after the event it is meant to predict. In practice the model would learn that any customer with a recorded departure reason has departed — which is true, useless, and not a prediction.

However, the field **is retained in the database** and is used in the Power BI reporting layer. Knowing that departed customers most commonly cite competitor offers is genuinely valuable to the business. The distinction is between what a model may learn from and what a report may show: the field is legitimate for explaining churn that has happened, and illegitimate for predicting churn that has not.

### `CLTV` — excluded as an unreliable measurement

This exclusion rests on entirely different grounds. `CLTV` is not leakage; it does not reveal the outcome. It was excluded because the testing above established that it does not measure what it claims to measure.

The separation is worth stating plainly, because the three fields are easily lumped together as "the columns that were dropped":

- **`Churn Score` and `Churn Reason`** were excluded because they are **valid information available at the wrong time** — they would corrupt the model by revealing the answer.
- **`CLTV`** was excluded because it is **invalid information**, at any time.

### Fields removed for having no variation

Three further fields were removed on straightforward grounds: `Count` is 1 for every record, `Country` is "United States" for every record, and `State` is "California" for every record. A field with the same value in every row carries no information and cannot contribute to a model. The `Lat Long` field was also removed as a redundant text concatenation of the separate latitude and longitude fields, which are retained.

---

## An encoding issue identified for the SQL stage

Six service fields — online security, online backup, device protection, technical support, streaming television and streaming movies — each hold three possible values rather than two: "Yes", "No", and "No internet service".

The third value is not a variant of "No". "No" means the customer was offered the service and declined it. "No internet service" means the service was never available to them, because they hold no internet subscription at all. These describe entirely different customers: one made a choice, the other never had one.

Collapsing the third category into "No" — the automatic default in most encoding routines — would merge a declined sale with an impossible sale, and the model would draw conclusions about customer preference from records where no preference was ever expressed.

The fields are therefore stored exactly as received, and the encoding decision is made explicitly and visibly in the feature engineering layer rather than absorbed silently into a data preparation step.

---

## A limitation stated openly

This dataset is a **single point-in-time snapshot**. Each row is one customer as at one moment. There are no dates, no transaction history, and no record of how any customer's behaviour changed over time.

This constrains what the model can honestly claim. It cannot state that it predicts which customers will churn in the next ninety days, because there is no observation window in the data to support such a claim. What it can state is that given a customer's current profile, it identifies whether that profile resembles those of customers who have churned.

A production system built inside a telecommunications provider or a bank would be designed differently. It would use a defined time window and behavioural indicators — declining usage, increased support contact, late payments, changes in product mix — which are the strongest early signals of departure and are entirely absent here.

This limitation is stated at the outset rather than left to be discovered, because a stated constraint is a demonstration of understanding, while an unstated one is a gap.

---

## Summary of findings

| # | Finding | Action taken |
|---|---|---|
| 1 | 7,043 records across 33 fields; 1,869 customers churned | Confirmed dataset suitable for the project |
| 2 | Missing values confined to `Churn Reason`, fully explained by churn status | No treatment — absence is correct |
| 3 | `Total Charges` held as text due to 11 blank entries, all unbilled new customers | Converted to numeric, zero substituted, all records retained |
| 4 | Supplied `CLTV` field bounded, falls below collected revenue, and does not correlate with its own inputs | Rejected; lifetime value derived independently in SQL |
| 5 | `Churn Score` and `Churn Reason` both reveal the outcome | Excluded from features; `Churn Reason` retained for reporting only |
| 6 | `Count`, `Country`, `State` identical across all records; `Lat Long` redundant | Removed from the schema |
| 7 | Six service fields hold a third category meaning "never available" | Stored as received; encoding decided explicitly in SQL |

**Next stage:** design the relational schema and implement the feature engineering and lifetime value logic in SQL.

---

## The principle underlying this stage

The dataset arrived with a customer lifetime value already calculated and a churn score already produced. Both could have been used without comment, and the project would have run faster for it.

Both were tested instead, and both failed. The lifetime value figure does not behave like a currency measure, and the churn score is an unexplainable input that would have invalidated the model's central design justification.

The work above is not data cleaning. It is the decision to establish whether supplied numbers are trustworthy before building on them — and the willingness to discard them when they are not.
