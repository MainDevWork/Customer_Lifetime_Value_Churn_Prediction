# Stage Four: The Economics of Contacting Customers

**Notebook:** `04_economics.ipynb`
**Supporting file:** `sql/05_economics.sql`

---

## Position within the project

This is the last of four documents describing a project which predicts which customers of a telecommunications provider are likely to leave, and works out which of them are worth the cost of keeping. The project and the source data are introduced in the Stage One document. The four write-ups form one continuous account, read in order and without reference to the underlying code.

Two parts of the work are now complete.

**Stage Two** produced a value for every one of the 7,043 customers, worked out from scratch after the value figure supplied with the dataset was found to be unreliable. The customer base carries a total value of R2.73 million.

**Stage Three** produced a model that estimates how likely each customer is to leave. It finds about four in every five leaving customers, and for each real departure it finds, it also flags roughly one extra customer who was not leaving at all.

Those two parts were deliberately kept apart throughout. Customer value was left out of the model completely, so that how likely a customer is to leave and how much they are worth stayed two separate questions with two separate answers.

**This stage brings them together for the first time.**

---

## The question this stage answers

A churn model produces a list of customers sorted by how likely they are to leave. The usual next step is to contact the customers at the top of that list.

That step hides an assumption nobody has checked: that a customer likely to leave is a customer worth keeping. Stage Two showed that the opposite is often true. The customers most likely to leave are month-to-month subscribers, who are also the least valuable customers the business has.

This stage therefore asks a different question. Not **who is likely to leave**, but **who is worth the money it takes to keep them**.

This is not a theoretical point. As shown below, a retention campaign aimed at every customer the model flags would lose money. The same model, used selectively, makes a profit. The gap between those two outcomes is about R184,000, and none of it comes from improving the model.

---

## 1. The decision rule

The rule is a single calculation, applied to every customer one at a time:

> **Value of contacting a customer = chance of leaving × chance of keeping them × customer value − cost of contact**

Where the answer is positive, contact is worth it. Where it is negative, contacting the customer destroys value, and that stays true even when the customer really was about to leave.

The logic is simple. A customer is only worth chasing if three things hold at once: they are genuinely likely to leave, there is a fair chance of talking them out of it, and what they are worth is more than the attempt costs. Fail on any one of the three and the attempt loses money.

**The cost is paid for every customer contacted**, including those who were never leaving. This matters because the model, like any model of this kind, is right about roughly one flagged customer in two. The rule builds that limit straight into the arithmetic rather than treating it as a separate problem to argue around. A customer with a low chance of leaving costs money with little prospect of a return, and the calculation leaves them out automatically.

---

## 2. The assumptions, stated in full

Two figures in the calculation are not in the dataset and cannot be worked out from it. They are assumptions. Both are written into `sql/05_economics.sql`, next to the calculation that uses them, so they cannot become separated from the results they produce.

### Assumption 1: cost of contact, R60 per customer

It is made up of two parts:

| Part | Amount | Basis |
|---|---|---|
| Contact and administration | R20 | An automated message rather than a phone call from a member of staff |
| Retention offer | R40 | A cut of R20 per month, held for two months |

The figure is shown in parts so that each part can be challenged on its own.

**Where the amount comes from.** The average customer in this dataset pays R64.76 per month. An offer of R20 per month is therefore about a 30 percent cut, held for a short period. The figure comes from what customers actually pay, rather than being chosen to produce a flattering result.

### Assumption 2: chance of keeping a customer, 30 percent

Of the customers who would otherwise leave, about three in ten stay when they are made an offer.

**This is the least certain figure in the project**, and it should be treated that way. It is the first figure a working business would replace with results from its own campaigns. The findings below rise and fall with it. If the true rate were 15 percent, the returns reported here would halve.

### Assumption 3: no adjustment for the timing of payments

Money received later is worth slightly less than money received today. Over the periods involved, at the amounts involved, the effect is too small to change any decision about which customers to contact. Leaving it out is a deliberate choice rather than an oversight.

---

## 3. A finding produced by the first version of the rule

The rule was first built on a cost of **R340 per customer**, covering a phone call from a member of staff along with a bigger offer held for six months. That figure reflects the kind of retention programme many businesses run.

**Applied to this customer base, it gave a single result: not one of the 7,043 customers was worth contacting.**

At first this looked like a mistake in the calculation. Checking it showed that it was not. It is a finding, and it is kept in the SQL file rather than thrown away.

To confirm it, the most that could be recovered was worked out for every customer:

| | Amount |
|---|---|
| Least recoverable from a single customer | R0.56 |
| Typical customer | R39.55 |
| Top 10 percent of customers | above R82.28 |
| Top 1 percent of customers | above R109.24 |
| **Most recoverable from any customer in the business** | **R163.09** |

**The most valuable customer in the business is worth spending at most R163 to keep. The typical customer is worth R40.**

That settles it. The problem was never the model, the offer, or the targeting. **No customer in this business is worth enough to justify R340 of retention spend**, and no improvement to the model could change that.

**What this means commercially.** Retention in this business has to be cheap and automated to work at all. A programme built on personal calls and large discounts cannot cover its own cost at these customer values. That conclusion is worth more to the business than the model itself, and it was reached before a single customer was contacted.

The cost assumption was then changed to R60 because of that conclusion. **The change followed from the finding. It was not an adjustment made to get a better answer.** The difference matters, and the reasoning is written into the SQL file so that the order of events stays on record.

---

## 4. Results under the revised assumption

Applying the rule at R60 per contact splits the customer base as follows:

| Decision | Customers | Value recovered | Cost | Net |
|---|---|---|---|---|
| **Contact** | 2,218 | R172,742 | R133,080 | **+R39,662** |
| Do not contact | 4,825 | R105,819 | R289,500 | −R183,681 |

The second row is the important one. Those 4,825 customers would cost R289,500 to contact and would bring back R105,819. **Chasing them destroys R183,681.**

### The two approaches compared

**Contacting every customer:** brings back R278,562 against a spend of R422,580. The programme **loses R144,018**.

**Contacting only the 2,218 customers the rule picks out:** the programme **returns R39,662**, a 30 percent return on the money spent.

The gap between those two outcomes is about **R184,000**.

**None of that gap comes from the model being more accurate.** The model is the same in both cases, giving the same probabilities for the same customers. The whole difference comes from the decision about which customers should be left alone.

> **Main finding.** A churn model looked at on its own suggests that a retention campaign is worth running. The economics show that it is not, unless it is targeted. The value was not in the prediction. It was in deciding who to leave out.

---

## 5. The decision across the value groups

Stage Two split the customer base into ten equally sized groups ranked by value. Applying the decision rule inside each group gives the following:

| Value group | Customers | Worth contacting | Net if targeted | Net if all contacted |
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

Three findings come out of this.

### Finding 1: The least valuable 30 percent are never worth contacting

Not one customer in groups 8, 9 and 10 clears the bar. That is none of the 2,112 people in those groups.

Contacting them would destroy **R94,048**. The rule does not reduce the spend on this group. It removes it altogether.

**What this means commercially.** These customers are not worth keeping at any price the business could realistically offer. Accepting that frees up roughly a third of the retention budget to be used where it earns something back.

### Finding 2: The return sits in groups 4 and 5

Those 1,408 customers produce R21,712 between them, which is **55 percent of the whole programme's return from 20 percent of the customer base**.

They are also the only two groups that make a profit even without targeting, as the final column shows.

**What this means commercially.** If the business could run only one campaign, this is the group it should aim at.

### Finding 3: The most valuable customers barely feature

Only 83 of the top 705 customers are worth contacting. The rest are not leaving, as this group loses only 5.5 percent of its customers.

High value with low risk leaves little to recover. Contacting the whole group would lose **R17,761**.

**What this means commercially.** Aiming retention effort at the most valuable customers, which is the instinctive move and a common one, would lose money here. Those customers are already safe, and the money spent protects value that was never at risk.

> **Finding.** Sorting customers by how likely they are to leave points to groups 4 to 6. Sorting by customer value points to groups 1 to 3. Neither list is right on its own. The return sits where the two overlap, and only this stage finds it.

---

## Summary of findings

| Work undertaken | Outcome |
|---|---|
| Model probabilities combined with customer value | 7,043 customers each carrying both a risk and a worth |
| Decision rule applied at R340 per contact | No customer was worth contacting, showing that expensive staffed retention cannot pay for itself at these values |
| Most recoverable value worked out per customer | R163 at the very top, R40 for the typical customer |
| Cost assumption changed to R60 because of that finding | 2,218 customers found to be worth contacting |
| Targeted approach compared against contacting everyone | A loss of R144,018 turned into a return of R39,662 |
| Decision spread across the ten value groups | 55% of the return sits in groups 4 and 5; groups 8 to 10 are left out entirely |

---

## Limits and qualifications

Four qualifications apply to the figures above, and each is stated rather than left for a reader to find.

**1. The two main assumptions are judgements, not measurements.** Neither the cost of contact nor the success rate appears in the dataset. Both are written down in the SQL file. A working business would replace both with figures from its own campaign records, and the results would move to match.

**2. The results move in step with the success rate.** The 30 percent assumption is the least certain input in the project. If the true rate were 15 percent, every return reported here would roughly halve, and far fewer customers would be worth contacting. This is the first figure that should be tested against real campaign data.

**3. The probabilities cover customers the model learned from.** Stage Three held back a quarter of customers for testing, and all the performance figures quoted there come from that held-back group. This stage needs a probability for all 7,043 customers in order to add up value across the whole customer base. Most of those customers were used in training, so their probabilities are slightly flattering. This does not change the shape of the decision or the comparison between targeting and not targeting, but the exact returns should be read as a guide rather than as precise figures.

**4. The dataset is a snapshot taken at one moment**, as recorded at Stage One. It holds no dates and no history of behaviour, so the model estimates whether a customer's profile today looks like that of customers who have already left. It does not predict departures within a set future period. The economics rest on that same footing.

---

## Outstanding work

Two items remain in this stage:

- **A sensitivity test on the retention success rate**, showing how far that assumption can move before the programme stops being worth running.
- **An export of the scored and classified customer base**, to feed the reporting layer.

---

## Concluding principle

The model built at Stage Three works well. It finds about four in every five leaving customers, and its reasoning can be inspected and explained.

Acting on its output alone would have lost the business R144,018.

The difference between that outcome and a profitable campaign was not a better model, more data, or a cleverer method. It was the decision to work out what each customer was worth, to keep that question apart from the question of who was likely to leave, and to bring the two together only at the point where money was about to be spent.

**A prediction shows what is likely to happen. It does not show what is worth doing about it.** That is a separate question, and it is the one this stage was built to answer.
