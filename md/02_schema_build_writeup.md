# Schema Build: Constructing the Database and Deriving the Features

**Notebook:** `02_schema_build.ipynb`
**SQL files:** `sql/01_schema.sql`, `sql/02_load.sql`, `sql/02b_validate.sql`, `sql/03_features.sql`, `sql/04_clv.sql`
**Purpose:** Turn a single flat spreadsheet into a structured database, verify the result, and derive the features and customer values the model will use.

---

## Why this stage exists

The previous stage established what the source data contains and which parts of it can be trusted. This stage builds on that.

The source is one spreadsheet: 7,043 rows, 33 columns, one row per customer. Everything about a customer sits on that single row — their location, their products, their bill, and whether they left.

That is not how the data would exist in a real telecommunications business, and it is not a useful shape to work from. This stage separates it into four related tables, loads the data into them, checks that nothing was lost or corrupted in the process, and then derives the additional measures the analysis requires.

**A note on where the work is done.** All of it is written in SQL, held in numbered files in the `sql/` folder. Python is used only for three things: opening a connection to the database, fetching the spreadsheet, and running the SQL files. No calculation or transformation happens in Python.

This is deliberate, and it reflects how these systems are built in practice. The database performs the work, and the analysis layer reads a finished result. It also means the logic is visible: anyone can open the SQL files and read exactly how every figure was produced, without needing to run anything.

---

## Step 1 — Designing the four-table structure

The single flat table was separated into four:

| Table | What it holds | Rows |
|---|---|---|
| `geography` | Postal code, city, latitude, longitude | 1,652 |
| `customer` | Demographics, tenure, and whether they churned | 7,043 |
| `subscription` | Which products the customer holds | 7,043 |
| `billing` | How they pay and what they pay | 7,043 |

The split reflects how a telecommunications business genuinely holds this information. Customer records, location references, product subscriptions and billing arrangements sit in separate systems, maintained by separate teams, updated at different times.

### An honest note on the modelling

The source arrived as a flat extract. It was not originally structured this way, and the four-table design is a decision made here rather than a structure inherited from the data.

This is stated openly rather than left to be discovered. The value of the exercise is not in recovering a hidden structure — it is in demonstrating the ability to design one, define the relationships between tables, and enforce them.

### The location table is a genuine dimension

`geography` differs from the other three. The other tables hold one row per customer. `geography` holds one row per postal code — 1,652 rows serving 7,043 customers, because many customers share a postal code.

This was checked before the design was settled. Every one of the 1,652 postal codes resolves to exactly one city, one latitude and one longitude, with no contradictions anywhere in the data. That confirms the postal code can serve as a reliable identifier for the table.

The check mattered. Had a single postal code appeared with two different cities, this design would have failed on loading, and the error would have surfaced later and less clearly.

### Fields deliberately not carried across

Four columns were left out:

- **`Count`** holds the value 1 in every row
- **`Country`** holds "United States" in every row
- **`State`** holds "California" in every row
- **`Lat Long`** repeats the separate latitude and longitude fields as a single piece of text

A field holding the same value in every record carries no information and cannot contribute to any analysis.

### Constraints written into the design

The database itself enforces the rules, rather than relying on the data being correct:

- **Primary keys** ensure no customer and no postal code can appear twice.
- **Foreign keys** ensure a customer cannot reference a postal code that does not exist, and a subscription or billing record cannot exist without a customer.
- **Mandatory fields** — every field is required except `churn_reason`, `churn_score` and `cltv`, which are the three fields legitimately expected to be empty for some customers.

These constraints make certain errors impossible rather than merely unlikely.

---

## Step 2 — Confirming the structure

Each table's definition was printed and checked: the correct fields, the correct types, primary keys registered, and only the three expected fields permitting empty values.

The count also reconciles. The source held 33 columns. Four were dropped, leaving 29. Three key fields repeat across tables — the postal code appears in two, the customer identifier in three — giving 32 columns across the four tables. That is exactly what was created. Nothing was lost or duplicated in the separation.

---

## Step 3 — Loading the data

The spreadsheet was fetched and made visible to the database, then the tables were populated in order. Location first, because customer records refer to it, and a reference cannot point at something that does not yet exist.

Two changes were made during loading, both deliberate.

### The location table was deduplicated

The spreadsheet holds 7,043 rows but only 1,652 postal codes, each repeating once for every customer living there. Loading it directly would have created 7,043 location records, most of them identical copies. `SELECT DISTINCT` reduces this to one row per postal code.

### Total charges was converted from text to a number

Profiling established that this field was stored as text because eleven records held a blank, and a single unreadable value forces an entire column to be treated as text.

Those eleven customers all have zero tenure and are all still active. They are newly acquired accounts that have not yet been billed. The blank is accurate rather than corrupt.

The conversion therefore substitutes zero for those eleven records, and all eleven are retained. Deleting them would have been the quicker option and would have removed the entire population of brand-new customers — the group with the highest exposure to early churn — introducing a bias at the first step.

---

## Step 4 — Validating the load

Row counts alone do not prove a correct load. A file can load the right number of records and still place them in the wrong fields.

Five checks were run, each against a figure already known from the profiling stage. The checks are held in `sql/02b_validate.sql` so that they remain visible alongside the rest of the SQL.

| Check | Expected | Returned |
|---|---|---|
| Customers who churned | 1,869 | 1,869 |
| Records with a churn reason recorded | 1,869 | 1,869 |
| Records showing zero total charges | 11 | 11 |
| Records showing zero tenure | 11 | 11 |
| Customers joining across all four tables | 7,043 | 7,043 |

All five returned their expected values.

**The final check is the most important.** It joins all four tables back together and counts the result. If the separation had lost customers — through a mismatched key, a failed reference, or a fault in the load — this figure would come back below 7,043. It returned the full 7,043, confirming every customer connects correctly to their location, their subscription and their billing record.

---

## Step 5 — Deriving the features

Seven measures were derived from the loaded data, held in a view named `vw_customer_features`.

A **view** is a saved query rather than a stored copy of the data. It runs afresh each time it is used. At 7,043 records the performance difference is immaterial, and a view keeps the derivation of every measure readable rather than concealed inside stored data.

### The seven features

1. **`tenure_band`** — tenure grouped into New (0–12 months), Established (13–36) and Loyal (37 or more). A raw count of months is difficult to act upon; groups are how a retention team organises its work.
2. **`has_internet`** — whether the customer holds an internet subscription at all.
3. **`has_phone`** — whether they hold a telephone service.
4. **`addon_count`** — how many of the six optional services they hold, from zero to six.
5. **`contract_risk`** — contract type ranked by how readily the customer can leave, with month-to-month highest.
6. **`automatic_payment`** — whether payment is automatic or manual.
7. **`spend_band`** — monthly charges grouped into low, medium and high.

### Tenure banding confirms where risk sits

| Band | Customers | Churn rate |
|---|---|---|
| New (0–12 months) | 2,186 | **47.4%** |
| Established (13–36 months) | 1,856 | 25.5% |
| Loyal (37+ months) | 3,001 | **11.9%** |

Nearly half of all first-year customers depart. Beyond three years, that falls to approximately one in eight.

Churn risk is concentrated overwhelmingly in the first year of the customer relationship. That finding directs where retention effort should be spent regardless of what any model subsequently produces.

---

## Step 6 — The encoding problem, and the number that proves it mattered

Profiling identified that the six optional service fields hold three values rather than two: "Yes", "No", and "No internet service".

The third value does not mean the customer declined the service. It means the service was never available to them, because they hold no internet subscription at all. One customer made a choice; the other was never offered one.

Counting the optional services held produced this:

| Add-ons held | Customers | Churn rate |
|---|---|---|
| 0 | 2,219 | **21.4%** |
| 1 | 966 | 45.8% |
| 2 | 1,033 | 35.8% |
| 3 | 1,118 | 27.4% |
| 4 | 852 | 22.3% |
| 5 | 571 | 12.4% |
| 6 | 284 | 5.3% |

From one add-on upward the pattern is consistent — each additional service reduces churn. But the zero group breaks it entirely, showing a low 21.4% where it should be the highest of all.

### Separating the two populations

The zero group was split using the internet flag:

| Group | Customers | Churn rate |
|---|---|---|
| No internet, zero add-ons | 1,526 | **7.4%** |
| Has internet, zero add-ons | 693 | **52.2%** |

**The same figure in the data, and a churn rate seven times apart.**

The lowest-risk customers in the entire dataset and the highest-risk customers in the entire dataset were occupying a single category, their averages concealing both.

Treating "No internet service" as equivalent to "No" is the standard shortcut, applied automatically by most data preparation routines. It would have merged these two groups permanently and without any visible sign that it had happened.

Once separated, the internet-subscribing population forms an uninterrupted progression:

**52.2% → 45.8% → 35.8% → 27.4% → 22.3% → 12.4% → 5.3%**

Every additional service a customer holds makes their departure measurably less likely — a clear commercial finding, and one that only becomes visible once the encoding is handled correctly.

---

## Step 7 — Deriving customer lifetime value

The lifetime value figure supplied with the dataset was rejected during profiling. It is bounded between 2,003 and 6,500 while total charges reach 8,684, and it shows almost no relationship with the variables that determine lifetime value. It is a score of some kind, not an amount of money.

Lifetime value is therefore calculated independently here, and deliberately **not** compared against the supplied field. A measure already established as unreliable cannot serve as a benchmark for the measure replacing it.

### The calculation

```
Lifetime value  =  monthly charges  ×  profit margin  ×  expected remaining months
```

### The assumptions, stated in full

Two of the three inputs are not present in the data. They are assumptions, and they are recorded in the SQL file itself so they cannot be separated from the figures they produce.

**1. A profit margin of 30%.**
Revenue is not profit. Serving a customer carries costs — network, support, billing, equipment — and none of these appear in this dataset. Thirty percent falls within the normal range for telecommunications operators. Any figure used here would be an assumption; this one is at least a defensible one.

**2. Expected remaining tenure, assigned by contract type.**
Twelve months for month-to-month customers, twenty-four for one-year contracts, thirty-six for two-year contracts.

This dataset is a single point-in-time snapshot with no dates. True expected tenure cannot be calculated from it, because the established method requires observing customers over time, and there is no time dimension here. Contract type is used as a substitute because it is the strongest available indicator of commitment, supported by the churn rates observed above.

**3. No discounting is applied.**
Money received in future is worth slightly less than money received today. Over periods of thirty-six months or less, at these amounts, the effect is too small to change any decision about whether to intervene. The omission is deliberate rather than an oversight.

Amounts are presented in rands.

### The result

| Contract | Customers | Average lifetime value |
|---|---|---|
| Month-to-month | 3,875 | **R239** |
| One year | 1,473 | R468 |
| Two year | 1,695 | **R656** |

The customers most likely to leave are also the least valuable. The most valuable customers are contractually committed and rarely leave.

This is the central argument of the project stated in a single table: **a retention list ranked by churn probability alone directs spending toward the least valuable customers in the business.**

---

## Step 8 — Segmenting customers by value

Customers were divided into ten equally sized groups ranked by lifetime value, with decile 1 holding the most valuable.

Deciles are used rather than currency thresholds because intervention decisions are taken on relative standing — which customers rank highest — rather than on specific amounts.

| Decile | Average value | Churn rate | Total value |
|---|---|---|---|
| 1 | R1,044 | 5.5% | R736k |
| 2 | R724 | 13.8% | R510k |
| 3 | R487 | 12.5% | R343k |
| **4** | R355 | **51.7%** | R250k |
| **5** | R311 | **48.7%** | R219k |
| **6** | R276 | **41.1%** | R194k |
| 7 | R242 | 25.9% | R170k |
| 8 | R200 | 18.8% | R141k |
| 9 | R153 | 23.3% | R108k |
| 10 | R81 | 24.3% | R57k |

Total book value: **R2.73m**.

### Where the value is actually at risk

Multiplying each decile's total value by its churn rate gives the value genuinely exposed:

- **Deciles 4 to 6: R316k at risk** — 54% of all exposed value, from 30% of customers
- Deciles 1 to 3: R154k at risk
- Deciles 7 to 10: R109k at risk

The most valuable customers are not leaving. The customers leaving in the greatest numbers are not the most valuable. **The retention opportunity sits in the middle deciles** — a group that a list ranked purely on churn probability would not identify as a priority.

This finding was produced entirely in SQL, before any model was trained.

---

## What the analysis shows

The preceding sections describe how the database was built. This section sets out what it revealed. These findings were produced entirely in SQL, before any model was trained.

### 1. Churn is a first-year problem

Nearly half of all customers in their first year leave — 47.4%. Beyond three years, that falls to 11.9%.

A customer who reaches their third year is roughly four times less likely to leave than a customer in their first. The risk is not evenly distributed across the customer base; it is concentrated almost entirely at the beginning of the relationship.

**What this means commercially.** Retention effort spent at the point a customer is preparing to leave is spent at the least effective moment. The same money spent on onboarding, early support and first-year engagement addresses the period where nearly all of the loss occurs.

This can be acted on immediately. It requires no model, no scoring, and no probability — only the observation that the risk sits in a specific and identifiable window.

### 2. Each additional service held makes a customer harder to lose

Among customers with an internet subscription, churn falls consistently with every additional service taken:

**52.2% → 45.8% → 35.8% → 27.4% → 22.3% → 12.4% → 5.3%**

A customer holding all six optional services churns at 5.3%. A customer holding none churns at 52.2% — ten times the rate.

**What this means commercially.** Selling a second or third product to an existing customer is not only a revenue measure; it is a retention measure. This places the case for bundling on commercial grounds rather than promotional ones, and it gives a retention team something concrete to offer beyond a discount.

**A necessary caution.** This is an association observed in the data, not a proven cause. It is possible that committed customers buy more services rather than that additional services create commitment. The pattern is consistent enough to justify testing, but it should be presented as a hypothesis worth trialling rather than an established mechanism.

### 3. A standard shortcut would have hidden the largest single difference in the data

Two groups sat inside a single category, indistinguishable from one another:

| Group | Customers | Churn rate |
|---|---|---|
| No internet, no add-ons | 1,526 | **7.4%** |
| Has internet, no add-ons | 693 | **52.2%** |

The lowest-risk customers in the dataset and the highest-risk customers in the dataset, recorded identically.

Treating "No internet service" as equivalent to "No" is the automatic default in most data preparation routines. Applying it would have merged these two groups permanently, and nothing in any subsequent output would have indicated that anything had been lost.

**What this means commercially.** The 693 customers with internet and no additional services are the single highest-risk group in the business, and they are identifiable today. A shortcut at the data preparation stage would have made them invisible.

### 4. The customers most likely to leave are the least valuable

| Contract | Customers | Average value | Churn |
|---|---|---|---|
| Month-to-month | 3,875 | R239 | Highest |
| One year | 1,473 | R468 | Middle |
| Two year | 1,695 | R656 | Lowest |

Risk and value run in opposite directions across the entire customer base.

**What this means commercially.** Any retention list ordered by churn probability will be dominated by month-to-month customers — the cheapest customers in the business. A team working through that list from the top would spend the majority of its budget on the least valuable customers it has, while the customers actually worth protecting sit further down.

This is the finding the project is built around, and it is visible before any model exists.

### 5. The retention opportunity sits in the middle of the value range

Multiplying each decile's total value by its churn rate gives the value genuinely exposed:

| Group | Share of customers | Value at risk |
|---|---|---|
| Deciles 1–3 (highest value) | 30% | R154k |
| **Deciles 4–6 (middle)** | **30%** | **R316k** |
| Deciles 7–10 (lowest value) | 40% | R109k |

**Deciles 4 to 6 hold 30% of customers but 54% of all value at risk.**

The most valuable customers are not leaving — the top decile churns at 5.5%. The customers leaving in the greatest numbers are worth too little to justify the cost of keeping them. The commercial opportunity lies in the middle, where meaningful value coincides with meaningful risk.

**What this means commercially.** This group would not be prioritised by a churn probability ranking, and would not be prioritised by a value ranking either. It becomes visible only when the two are measured separately and then combined — which is the argument for building the economics layer at all.

---

## Summary of this stage

| # | What was done | Outcome |
|---|---|---|
| 1 | Designed a four-table structure with enforced relationships | Postal code confirmed as a reliable identifier before the design was settled |
| 2 | Loaded all 7,043 records | Eleven unbilled accounts corrected and retained rather than discarded |
| 3 | Validated the load against five known figures | All five matched, including a full four-table join returning every customer |
| 4 | Derived seven features in SQL | Churn risk found to be concentrated in the first year, at 47.4% |
| 5 | Separated the encoding problem identified during profiling | Two populations differing sevenfold in churn rate were found within a single category |
| 6 | Derived lifetime value on three stated assumptions | The most at-risk customers found to be the least valuable |
| 7 | Segmented customers into value deciles | 54% of value at risk located in deciles 4 to 6 |

**Next stage:** model development in `03_modelling.ipynb`.

---

## The principle underlying this stage

Every figure in this stage can be traced to the SQL file that produced it, and every assumption that is not present in the data is written down beside the calculation that uses it.

That matters more than the figures themselves. A number without a stated derivation cannot be defended when questioned, and a number nobody can question is a number nobody should rely on.
