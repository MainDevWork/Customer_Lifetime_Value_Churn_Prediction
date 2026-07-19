# Stage Two — Database Construction and Customer Value Derivation

**Notebook:** `02_schema_build.ipynb`
**Supporting files:** `sql/01_schema.sql`, `02_load.sql`, `02b_validate.sql`, `03_features.sql`, `04_clv.sql`

---

## Project overview

Telecommunications providers lose customers to competitors on a continuous basis. The industry term for this is **churn**. It represents a significant commercial cost, as acquiring a new customer is considerably more expensive than retaining an existing one.

The standard response is to predict which customers are most likely to leave, and to contact those customers with a retention offer.

This project undertakes that prediction, and then addresses a second question which most churn projects omit: **whether a given customer is worth the cost of retaining them.** For a substantial proportion of the customer base, the answer is no. The cost of contacting them exceeds the value they represent.

The work is delivered in four stages, each documented separately:

| Stage | Purpose |
|---|---|
| One | Assess the contents and reliability of the source data |
| **Two (this document)** | Construct the database, derive the required measures, and calculate customer value |
| Three | Build, test and select the predictive model |
| Four | Determine which customers justify intervention, and quantify the commercial return |

**This document is written to be read independently of the underlying code.** All work undertaken and all findings reached are set out in full below.

---

## Position within the project

Stage One examined the source data supplied by IBM — 7,043 customers of a telecommunications provider in California, with 33 items of information recorded for each. It reached three conclusions which govern the present stage:

- Of the 7,043 customers, **1,869 have departed** from the business.
- Eleven records contained no value in the total charges field. These were established to be newly acquired customers who have not yet been billed, meaning the correct value is zero and the records should be retained.
- **The customer lifetime value figure supplied within the dataset is unreliable and must be disregarded.** It was found to carry impossible boundaries and to bear almost no relationship to the variables which determine customer value. It is therefore calculated independently at this stage.

---

## The problem this stage addresses

The source data is supplied as a single flat spreadsheet. Every item of information relating to a customer occupies one row: their location, the products they hold, the amounts they pay, and whether they have departed.

This arrangement is convenient for distribution and unsuitable for analysis. It also bears no resemblance to the manner in which a telecommunications provider holds its information in practice. Within an operating business, customer records, address references, product subscriptions and billing arrangements are maintained in separate systems, administered by different departments and updated on different cycles.

This stage therefore has four objectives:

1. **Restructure the flat spreadsheet into four related tables**, reflecting how the information is genuinely organised.
2. **Load the data and demonstrate that nothing was lost or misplaced in the process.**
3. **Derive the measures required by the predictive model** — quantities such as tenure banding, the number of products held, and the ease with which a customer may terminate their contract.
4. **Calculate the value of each customer**, replacing the rejected figure supplied with the dataset.

### Division of responsibility between technologies

All of the above is implemented in **SQL**, the standard language used to define and query databases. The instructions are held in numbered files which may be opened and read as plain text.

A second technology, Python, is used for three functions only: establishing a connection to the database, retrieving the source spreadsheet, and executing the SQL files. **No calculation of any kind is performed in Python.**

This division was deliberate, for two reasons.

It reflects established practice within operating businesses, where the database performs the substantive processing and the analytical layer consumes a completed result.

It also preserves transparency. Every calculation resides in a file which can be read directly, rather than being embedded within code that must be executed before its behaviour can be understood.

---

## 1. Restructuring the data into four related tables

The single flat spreadsheet was reorganised into four connected tables:

| Table | Contents | Records |
|---|---|---|
| `geography` | Postal code, city, latitude, longitude | 1,652 |
| `customer` | Customer characteristics, tenure, departure status | 7,043 |
| `subscription` | Products and services held | 7,043 |
| `billing` | Payment method and amounts charged | 7,043 |

Three of these tables hold one record per customer. The address table is structured differently, and the reason merits explanation.

**A substantial number of customers share a postal code.** Recording the city, latitude and longitude against every individual customer would mean storing identical address details thousands of times over. Addresses are therefore stored once each — 1,652 postal codes serving 7,043 customers — with each customer record referring to the appropriate entry.

### A verification performed before the design was adopted

This arrangement is only viable if each postal code corresponds to exactly one city and one set of coordinates. Were a single postal code to appear against two different cities, there would be no basis on which to determine which to record.

This was verified before the design was settled. **All 1,652 postal codes correspond to exactly one city and one location, with no contradictions anywhere within the dataset.**

The verification was necessary. Had it failed, the design would have collapsed during loading, and the resulting fault would have surfaced later and proved considerably more difficult to diagnose.

### A statement regarding the nature of this design

The source data was supplied in flat form. It was not originally structured in this manner. **The four-table design is a decision taken within this project, not a pre-existing structure recovered from the source.**

This is stated explicitly rather than left for a reader to identify. The value of the exercise does not lie in uncovering a concealed structure. It lies in the ability to design one, define the relationships between its components, and require the database to enforce those relationships.

### Constraints enforced by the database

Rather than relying upon the data behaving as expected, the database was configured with constraints it will not permit any process to violate:

- **No customer and no postal code may be recorded more than once.**
- **A customer record cannot refer to an address which does not exist**, and no subscription or billing record may exist without an associated customer.
- **All fields are mandatory**, with the exception of the three which are legitimately empty for certain customers.

These constraints render particular categories of error impossible rather than merely improbable. Should a future load prove defective, the database will reject it rather than silently storing corrupted information.

---

## 2. Loading the data and verifying its integrity

The spreadsheet was loaded into the four tables in a defined sequence, with addresses populated first. Customer records refer to addresses, and a reference cannot be established to an entry which does not yet exist.

Two corrections were applied during loading, both arising from Stage One.

**Duplicate address records were eliminated.** The spreadsheet contains 7,043 rows but only 1,652 postal codes, each repeating once for every customer resident there. Loading the data unchanged would have produced 7,043 address records, the substantial majority of them duplicates. Only distinct addresses were retained.

**Total charges was converted from text into a numeric field.** Stage One established that this field was supplied as text because eleven customers held no value within it, and that those eleven are newly acquired customers who have not yet been billed. Zero was recorded for them, and all eleven were retained rather than deleted.

### Demonstrating that the load was successful

Counting records establishes very little in isolation. A file may load the correct number of records while placing the values in incorrect fields.

Five verification checks were therefore performed, each against a figure already established during Stage One. Had the load been defective, at least one of these would have returned an incorrect result.

| Verification check | Expected | Returned |
|---|---|---|
| Customers who departed | 1,869 | 1,869 |
| Records holding a recorded reason for departure | 1,869 | 1,869 |
| Records showing zero total charges | 11 | 11 |
| Records showing zero months of tenure | 11 | 11 |
| Customers connecting across all four tables | 7,043 | 7,043 |

All five returned their expected values.

**The final check is the most significant.** It reconstructs the original single row for every customer by reconnecting all four tables, and counts the result.

Had the restructuring lost any customer — through a broken reference, a mismatched postal code, or a defect in the loading process — this figure would return below 7,043. It returned the full complement. Every customer remains correctly connected to their address, their products and their billing record.

These checks are held within a dedicated file, `02b_validate.sql`, so that the verification remains visible alongside the remainder of the work rather than being embedded within a notebook.

---

## 3. Deriving the required measures

The fields as supplied are not directly usable by a predictive model. The statement that a customer has held an account for thirty-four months is a fact; it is not yet a measure upon which a business can act.

Seven measures were therefore derived from the loaded data:

| Measure | What it captures |
|---|---|
| Tenure band | Whether the customer is newly acquired, established, or long-standing |
| Internet subscription | Whether the customer holds internet service at all |
| Telephone service | Whether the customer holds a telephone line |
| Count of additional services | How many of the six optional services are held, from zero to six |
| Contract risk | The ease with which the customer may terminate, based on contract type |
| Automatic payment | Whether payment is collected automatically or made manually |
| Spend band | Monthly charge grouped into low, medium and high categories |

These measures are implemented as **views**. A view is a stored instruction rather than a stored result: the calculation is performed afresh each time the measure is requested.

The alternative would have been to calculate each measure once and store the outcome. Views were selected because they preserve the visibility of the method — the definition of every measure can be read directly. With a dataset of 7,043 records, there is no meaningful cost in processing time.

---

## 4. Findings arising from the derived measures

All findings in this section were produced within the database, before any predictive model was constructed.

### Finding 1 — Departures are concentrated within the first year

| Tenure | Customers | Proportion departed |
|---|---|---|
| Under one year | 2,186 | **47.4%** |
| One to three years | 1,856 | 25.5% |
| Over three years | 3,001 | **11.9%** |

Nearly half of all customers in their first year depart. Beyond three years, that proportion falls to approximately one in eight.

A customer reaching their third year is roughly four times less likely to depart than one still within their first. **Risk is not distributed evenly across the customer base. It is concentrated almost entirely at the beginning of the relationship.**

**Commercial implication.** Expenditure directed toward a customer already preparing to depart is applied at the least effective point. The equivalent expenditure directed toward supporting newly acquired customers through their first year addresses the period in which the substantial majority of losses occur.

This finding requires no model, no scoring and no probability estimates. It requires only the observation that risk is concentrated within a clearly identifiable period.

### Finding 2 — Each additional product held reduces the likelihood of departure

Among customers holding an internet subscription, the proportion departing declines with each additional service taken:

| Additional services held | Proportion departed |
|---|---|
| 0 | **52.2%** |
| 1 | 45.8% |
| 2 | 35.8% |
| 3 | 27.4% |
| 4 | 22.3% |
| 5 | 12.4% |
| 6 | **5.3%** |

A customer holding all six additional services departs at 5.3%. A customer holding none departs at 52.2% — **ten times the rate**.

**Commercial implication.** Selling a second or third product to an existing customer is not solely a means of increasing revenue from that customer. It functions as a retention measure. This places the argument for product bundling on commercial rather than promotional grounds, and provides a retention function with a substantive proposition beyond a price reduction.

**A necessary qualification.** This constitutes an association observed within the data, not established causation. It remains entirely possible that customers who were already committed proceed to purchase additional services, rather than that purchasing additional services generates commitment. The pattern is sufficiently consistent to warrant formal testing, but it should be presented as a proposition worth trialling rather than an established mechanism.

### Finding 3 — A conventional shortcut would have concealed the largest disparity in the dataset

The table above covers only customers holding an internet subscription. When all customers holding zero additional services are counted together — including those with no internet subscription at all — the figure returns as 21.4% rather than 52.2%.

That single figure was concealing two entirely distinct populations:

| Population | Customers | Proportion departed |
|---|---|---|
| No internet subscription, no additional services | 1,526 | **7.4%** |
| Holds internet subscription, no additional services | 693 | **52.2%** |

**The lowest-risk population within the business and the highest-risk population within the business were recorded identically.** Seven times apart, averaged together into a single figure which describes neither accurately.

This is the recording issue identified during Stage One. The six service fields record "No internet service" as a value distinct from "No", and most automated data preparation consolidates the two on the basis that they appear equivalent. They are not. The first population declined the service; the second was never in a position to be offered it.

Had that consolidation been applied, these two populations would have been merged permanently, and **no subsequent output would have provided any indication that anything was incorrect.**

**Commercial implication.** The 693 customers holding an internet subscription with no additional services, of whom more than half depart, constitute the single highest-risk population within the business. They can be identified and listed immediately. A shortcut applied during data preparation would have rendered them invisible.

---

## 5. Calculating customer value

Stage One rejected the customer lifetime value figure supplied within the dataset. It never exceeds 6,500 despite certain customers having already paid 8,684, and it responds only marginally to the amounts customers pay or the duration of their tenure.

Customer value is therefore derived here independently, and deliberately never compared against the rejected figure.

### The calculation

> **Customer value = monthly charge × profit margin × expected remaining months**

Each component is addressed below.

**The monthly charge** is taken directly from the source data.

**The profit margin** converts revenue into profit, which is necessary because revenue does not represent profit. Serving a customer incurs cost.

**Expected remaining months** estimates the further duration of the relationship.

### The assumptions, stated in full

Two of those three components are absent from the dataset. They are assumptions. Both are recorded within the SQL file itself, ensuring they cannot become separated from the figures they produce.

**Assumption 1 — a profit margin of 30 percent.**

Revenue does not represent profit. Serving a customer incurs cost across network infrastructure, support functions, billing systems and equipment. None of these costs appear within this dataset.

Thirty percent falls within the established range for telecommunications operators. Any figure applied here would constitute an assumption; this one is at least defensible.

**Assumption 2 — expected remaining tenure, assigned by contract type.**

Twelve further months for month-to-month customers, twenty-four for one-year contracts, and thirty-six for two-year contracts.

An assumption is required because the dataset is a point-in-time snapshot containing no dates. Actual customer tenure cannot be calculated, as the established method requires observing customers across a defined period and no time dimension exists within the data.

Contract type is used in its place, as the strongest available indicator of customer commitment. The departure rates recorded above support this treatment.

**Assumption 3 — no adjustment is made for the future value of money.**

Revenue received in a future period is worth marginally less than revenue received today. Across periods of thirty-six months or less, at the amounts in question, the effect is too small to alter any decision regarding which customers to contact. The omission is deliberate rather than an oversight.

### Finding 4 — The customers most likely to depart are the least valuable

| Contract type | Customers | Average value | Likelihood of departure |
|---|---|---|---|
| Month-to-month | 3,875 | **R239** | Highest |
| One year | 1,473 | R468 | Intermediate |
| Two year | 1,695 | **R656** | Lowest |

**Risk and value operate in opposing directions across the entire customer base.**

**Commercial implication.** Any retention list ordered by likelihood of departure will be dominated by month-to-month customers, who are the least valuable customers the business holds. A retention function working through that list from the top would direct the majority of its budget toward its least valuable customers, while those genuinely warranting protection remain further down the list and are never contacted.

This is the argument upon which the project rests, and it is evident before any model has been constructed.

---

## 6. Segmenting customers by value

Customers were ranked by value and divided into ten equally sized groups, with group 1 holding the most valuable customers and group 10 the least.

Groups were used in preference to currency thresholds because the decision concerns relative standing — which customers rank highest — rather than attainment of a specific figure.

| Group | Average value | Proportion departed | Total value of group |
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

The customer base carries a total value of **R2.73 million**.

### Finding 5 — The commercial opportunity is concentrated in the middle of the value range

Establishing the value of each group is not sufficient in isolation. What matters is the proportion of that value genuinely exposed to loss.

Multiplying each group's total value by its departure rate produces exactly that figure:

| Group | Share of customers | Value genuinely at risk |
|---|---|---|
| Groups 1–3 (most valuable) | 30% | R154k |
| **Groups 4–6 (intermediate)** | **30%** | **R316k** |
| Groups 7–10 (least valuable) | 40% | R109k |

**Groups 4 to 6 contain 30 percent of customers but 54 percent of all value at risk.**

The explanation is that each end of the value range fails on a different basis. The most valuable customers are not departing — the highest group loses only 5.5 percent, leaving little to protect. The customers departing in the greatest numbers hold insufficient value to justify the cost of retaining them.

The opportunity is concentrated in the middle of the range, where meaningful value coincides with meaningful risk.

**Commercial implication.** This population would not be prioritised by a list ordered on likelihood of departure, nor by a list ordered on customer value. It becomes visible only when the two measures are established separately and subsequently combined, which is the function of Stage Four.

---

## Summary of findings

| Work undertaken | Outcome |
|---|---|
| Four related tables designed, with constraints enforced by the database | Postal code verified as a sound identifier before the design was adopted |
| All 7,043 customers loaded | Eleven unbilled new customers corrected and retained rather than deleted |
| Five verification checks performed against established figures | All five matched, including a full reconnection returning every customer |
| Seven measures derived in SQL | Departures found to be concentrated within the first year, at 47.4% |
| Recording issue identified at Stage One resolved explicitly | Two populations seven times apart found concealed within a single category |
| Customer value calculated on three stated assumptions | The customers most at risk found to be the least valuable |
| Customers segmented into ten value groups | 54% of value at risk located within groups 4 to 6 |

**Next stage:** construct, test and select the predictive model.

---

## Concluding principle

Every figure produced within this stage can be traced to the SQL file which generated it. Every assumption not present within the source data is recorded alongside the calculation which relies upon it.

This carries greater weight than the figures themselves. A figure with no visible derivation cannot be defended when questioned — and a figure which cannot be questioned is one which should not be relied upon.
