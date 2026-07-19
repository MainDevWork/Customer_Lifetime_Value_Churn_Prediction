# Stage Four — Intervention Economics

**Notebook:** `04_economics.ipynb`
**Supporting file:** `sql/05_economics.sql`

---

## Project overview

Telecommunications providers lose customers to competitors on a continuous basis. The industry term for this is **churn**. It represents a significant commercial cost, as acquiring a new customer is considerably more expensive than retaining an existing one.

The standard response is to predict which customers are most likely to leave, and to contact those customers with a retention offer.

This project undertakes that prediction, and then addresses a second question which most churn projects omit: **whether a given customer is worth the cost of retaining them.** For a substantial proportion of the customer base, the answer is no. The cost of contacting them exceeds the value they represent.

The work is delivered in four stages, each documented separately:

| Stage | Purpose |
|---|---|
| One | Assess the contents and reliability of the source data |
| Two | Construct the database, derive the required measures, and calculate customer value |
| Three | Build, test and select the predictive model |
| **Four (this document)** | Determine which customers justify intervention, and quantify the commercial return |

**This document is written to be read independently of the underlying code.** All work undertaken and all findings reached are set out in full below.

---

## Position within the project

Two components are now complete.

**Stage Two** produced a calculated value for every one of the 7,043 customers, derived independently after the value figure supplied with the dataset was found to be unreliable. The customer base carries a total value of R2.73 million.

**Stage Three** produced a model estimating each customer's likelihood of departure. It identifies approximately four in every five departing customers, and for each genuine departure identified it also flags roughly one additional customer who was not in fact leaving.

Those two components were deliberately kept apart throughout. Customer value was excluded from the model entirely, so that likelihood of departure and customer worth remained two separate questions with two separate answers.

**This stage brings them together for the first time.**

---

## The question this stage answers

A churn model produces a list of customers ranked by their likelihood of departure. The conventional next step is to contact the customers at the top of that list.

That step contains an unexamined assumption: that a customer likely to depart is a customer worth retaining. Stage Two established that the opposite is frequently the case. The customers most likely to depart are month-to-month subscribers, who are also the least valuable customers the business holds.

This stage therefore addresses a different question. Not **who is likely to leave**, but **whose retention is commercially justified**.

The distinction is not academic. As demonstrated below, a retention campaign directed at every customer the model identifies would lose money. The same model, applied selectively, returns a profit. The difference between those two outcomes is approximately R184,000, and none of it arises from improving the model.

---

## 1. The decision rule

The rule consists of a single calculation, applied to every customer individually:

> **Value of contacting a customer = probability of departure × probability of successful retention × customer value − cost of contact**

Where the result is positive, contact is justified. Where it is negative, contacting the customer destroys value — and this remains true even where the customer genuinely intended to depart.

The logic is straightforward. A customer is only worth pursuing if three conditions hold together: they are meaningfully likely to leave, there is a reasonable prospect of persuading them to stay, and what they are worth exceeds what the attempt costs. A failure on any one of the three renders the intervention uneconomic.

**The cost is incurred for every customer contacted**, including those who were never departing. This matters because the model, in common with any model of this kind, correctly identifies roughly one flagged customer in two. The rule incorporates that limitation directly into the arithmetic rather than treating it as a separate problem to be argued around. A customer with a low probability of departure generates cost with little prospect of return, and the calculation excludes them automatically.

---

## 2. The assumptions, stated in full

Two figures within the calculation are not present within the dataset, and cannot be derived from it. They are assumptions. Both are recorded within `sql/05_economics.sql`, alongside the calculation which relies upon them, so that they cannot become separated from the results they produce.

### Assumption 1 — cost of contact: R60 per customer

This comprises two components:

| Component | Amount | Basis |
|---|---|---|
| Contact and administration | R20 | An automated electronic communication rather than an agent-led telephone call |
| Retention offer | R40 | A reduction of R20 per month, sustained over two months |

The figure is presented in components so that each may be challenged independently.

**The basis for the amount.** The average customer within this dataset pays R64.76 per month. An offer of R20 per month therefore represents approximately a 30 percent reduction, sustained for a short period. The figure is derived from what customers actually pay, rather than selected to produce a favourable result.

### Assumption 2 — probability of successful retention: 30 percent

Of customers who would otherwise have departed, approximately three in ten are retained when presented with an offer.

**This is the least certain figure within the project**, and it should be treated as such. It is the first figure an operating business would replace with results drawn from its own campaigns. The findings below are directly proportional to it: were the true rate 15 percent, the returns reported here would halve.

### Assumption 3 — no adjustment for the timing of cash flows

Revenue received in a future period is worth marginally less than revenue received today. Across the periods involved, at the amounts involved, the effect is too small to alter any decision regarding which customers to contact. The omission is deliberate rather than an oversight.

---

## 3. A finding produced by the first version of the rule

The rule was initially constructed on an assumption of **R340 per customer**, representing an agent-led telephone contact together with a larger offer sustained over six months. That figure reflects a conventional, high-touch retention programme of the kind many businesses operate.

**Applied to this customer base, it returned a single result: not one of the 7,043 customers justified contact.**

That outcome was initially treated as a possible error in the calculation. Investigation established that it was not. It is a finding, and it is retained within the SQL file rather than discarded.

To confirm it, the maximum recoverable amount was calculated for every customer:

| | Amount |
|---|---|
| Minimum recoverable from a single customer | R0.56 |
| Typical customer | R39.55 |
| Highest 10 percent of customers | above R82.28 |
| Highest 1 percent of customers | above R109.24 |
| **Maximum across the entire customer base** | **R163.09** |

**The most valuable customer in the business justifies expenditure of at most R163 to retain. The typical customer justifies R40.**

This establishes the point conclusively. The problem was never the model, the offer, or the targeting. **No customer within this business carries sufficient value to justify R340 of retention expenditure**, and no improvement to the model could change that.

**Commercial implication.** Retention within this business must be low-cost and automated to be viable at all. An agent-led programme with substantial discounts cannot recover its own cost at these customer values. That conclusion is worth more to the business than the model itself, and it was reached before a single customer was contacted.

The cost assumption was revised to R60 on the basis of that conclusion. **The revision followed from the finding; it was not an adjustment made to obtain a preferred answer.** The distinction matters, and the reasoning is recorded in the SQL file so that the sequence remains auditable.

---

## 4. Results under the revised assumption

Applying the rule at R60 per contact divides the customer base as follows:

| Decision | Customers | Value recovered | Cost | Net |
|---|---|---|---|---|
| **Contact** | 2,218 | R172,742 | R133,080 | **+R39,662** |
| Do not contact | 4,825 | R105,819 | R289,500 | −R183,681 |

The second row carries the substance of the finding. Those 4,825 customers would cost R289,500 to contact and would return R105,819. **Pursuing them destroys R183,681.**

### The comparison between the two available approaches

**Contacting every customer:** recovers R278,562 against expenditure of R422,580. The programme **incurs a net loss of R144,018**.

**Contacting only the 2,218 customers identified by the rule:** the programme **returns R39,662**, representing a 30 percent return on expenditure.

The difference between those two outcomes is approximately **R184,000**.

**None of that difference arises from model accuracy.** The model is identical in both cases, producing identical probabilities for identical customers. The entire difference arises from the decision regarding which customers should not be contacted.

> **Principal finding.** A churn model considered in isolation indicates that a retention campaign is commercially justified. The economics establish that it is not, unless targeted. The value lay not in the prediction but in the decision regarding whom to exclude.

---

## 5. The decision distributed across value groups

Stage Two divided the customer base into ten equally sized groups ranked by value. Applying the decision rule within each group produces the following:

| Value group | Customers | Justify contact | Net if targeted | Net if all contacted |
|---|---|---|---|---|
| 1 (most valuable) | 705 | 83 | +R1,600 | −R17,761 |
| 2 | 705 | 349 | +R10,262 | −R2,598 |
| 3 | 705 | 138 | +R2,642 | −R17,693 |
| **4** | 704 | **589** | **+R13,506** | +R11,196 |
| **5** | 704 | **532** | **+R8,206** | +R5,216 |
| 6 | 704 | 363 | +R2,974 | −R9,179 |
| 7 | 704 | 164 | +R472 | −R19,151 |
| 8 | 704 | **0** | R0 | −R28,863 |
| 9 | 704 | **0** | R0 | −R30,434 |
| 10 (least valuable) | 704 | **0** | R0 | −R34,750 |

Three findings arise from this distribution.

### Finding 1 — The least valuable 30 percent do not justify contact under any circumstances

Not one customer within groups 8, 9 and 10 meets the threshold. That is none of the 2,112 individuals concerned.

Contacting that population would destroy **R94,048**. The rule does not reduce expenditure upon this group; it eliminates it entirely.

**Commercial implication.** These customers are not worth retaining at any price the business could realistically offer. Recognising that releases roughly a third of the retention budget for deployment where it produces a return.

### Finding 2 — The return is concentrated within groups 4 and 5

Those 1,408 customers produce R21,712 between them, representing **55 percent of the programme's entire return from 20 percent of the customer base**.

These are also the only two groups which return a profit even without targeting, as shown in the final column.

**Commercial implication.** If the business were able to run only one campaign, this is the population it should address.

### Finding 3 — The most valuable customers feature only marginally

Only 83 of the highest-value 705 customers justify contact. The remainder are not departing: this group carries a departure rate of 5.5 percent.

High value combined with low risk leaves correspondingly little to recover. Contacting the entire group would incur a loss of **R17,761**.

**Commercial implication.** Retention effort directed at the most valuable customers, which is the intuitive approach and a common practice, would lose money here. Those customers are already secure, and the expenditure protects value which was not at risk.

> **Finding.** Ranking customers by likelihood of departure directs attention toward groups 4 to 6. Ranking by customer value directs attention toward groups 1 to 3. Neither list is correct in isolation. The return is located where the two overlap, and only this stage identifies it.

---

## Summary of findings

| Work undertaken | Outcome |
|---|---|
| Model probabilities combined with calculated customer value | 7,043 customers each carrying both a risk and a worth |
| Decision rule applied at R340 per contact | No customer justified contact — establishing that high-touch retention is not viable at these values |
| Maximum recoverable value established per customer | R163 at the highest, R40 for the typical customer |
| Cost assumption revised to R60 on the basis of that finding | 2,218 customers identified as justifying contact |
| Targeted approach compared against contacting all customers | A loss of R144,018 converted into a return of R39,662 |
| Decision distributed across the ten value groups | 55% of the return concentrated in groups 4 and 5; groups 8 to 10 excluded entirely |

---

## Constraints and qualifications

Four qualifications apply to the figures above, and each is stated rather than left for a reader to identify.

**1. The two principal assumptions are engineered, not observed.** Neither the cost of contact nor the retention success rate appears within the dataset. Both are documented within the SQL file. An operating business would replace both with figures drawn from its own campaign records, and the results would move accordingly.

**2. The results are directly proportional to the retention success rate.** The 30 percent assumption is the least certain input within the project. Were the true rate 15 percent, every return reported here would approximately halve, and the number of customers justifying contact would fall substantially. This is the first figure which should be tested against real campaign data.

**3. The probabilities cover customers the model was trained upon.** Stage Three withheld a quarter of customers for evaluation, and all performance figures quoted in that stage derive from that withheld group. This stage, however, requires a probability for all 7,043 customers in order to total value across the complete customer base. The majority of those customers were used in training, so their probabilities are marginally optimistic. This does not affect the structure of the decision or the comparison between targeted and untargeted approaches, but the absolute returns should be read as indicative rather than precise.

**4. The underlying dataset is a point-in-time snapshot.** It contains no dates and no behavioural history, so the model estimates whether a customer's present profile resembles that of customers who have already departed. It does not forecast departures within a defined future period. The economics rest upon that same foundation.

---

## Outstanding work

Two items remain within this stage:

- **A sensitivity analysis on the retention success rate**, establishing how far that assumption may move before the programme ceases to be viable.
- **An export of the scored and classified customer base**, to support the reporting layer.

---

## Concluding principle

The model constructed at Stage Three performs competently. It identifies approximately four in every five departing customers, and its reasoning can be inspected and explained.

Acting upon its output alone would have lost the business R144,018.

The difference between that outcome and a profitable campaign was not a better model, more data, or a more sophisticated method. It was the decision to establish what each customer was worth, to keep that question separate from the question of who was likely to leave, and to combine the two only at the point where money was to be committed.

**A prediction identifies what is likely to happen. It does not establish what is worth doing about it.** That remains a separate question, and it is the one this stage was built to answer.
