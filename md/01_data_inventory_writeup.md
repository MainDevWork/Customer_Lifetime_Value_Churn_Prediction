# Stage One: Data Inventory and Reliability Assessment

**Notebook:** `01_data_inventory.ipynb`

---

## Project overview

Telecommunications providers lose customers to competitors on a continuous basis. The industry term for this is **churn**. It costs the business a great deal, because winning a new customer is far more expensive than keeping one it already has.

The usual response is to predict which customers are most likely to leave, and to contact them with a retention offer.

This project makes that prediction, and then asks a further question: **whether a customer is worth the cost of keeping.** For a large share of the customer base, the answer is no. Contacting them costs more than they are worth, so keeping them destroys value rather than creating it.

The project has two parts:

1. **A model**: estimating how likely each customer is to leave.
2. **A customer value calculation**: working out the lifetime value of the customers who are worth the cost of contacting.

The work is delivered in **four stages**:

| Stage                         | Purpose                                                                        |
| ----------------------------- | ------------------------------------------------------------------------------ |
| **One (this document)** | Check what the source data holds and whether it can be trusted                 |
| Two                           | Build the database, work out the measures needed, and calculate customer value |
| Three                         | Build, test and choose the model                                               |
| Four                          | Decide which customers are worth contacting, and put a figure on the return    |

Each stage has a write-up of its own, and this is the first. **The four documents form one continuous account of the project.** All the work done and all the findings are set out in the documents themselves.

---

## The dataset

The project uses a publicly available dataset published by IBM, describing the customer base of a telecommunications provider in California. It contains **7,043 customers**, with **33 fields of information recorded for each**.

Those items fall into five categories:

- **Customer characteristics**: gender, senior citizen status, whether the customer has a partner or dependants
- **Location**: city, postal code, geographic coordinates
- **Products held**: telephone line, internet service type, and six optional additional services including online security and streaming television
- **Financial information**: monthly charge, total amount paid to date, contract type, payment method
- **Outcome**: whether the customer has left, and if so, the reason recorded

---

## Rationale for this stage

Two further figures were also provided with the dataset:

- **A churn score**: IBM's own estimate of each customer's likelihood of leaving
- **A customer lifetime value figure**: an estimate of the total worth of each customer to the business across the relationship

Both figures arrived already calculated, which appears to save effort. The temptation is to accept them and move straight to the modelling work. That carries a risk. If either figure is wrong, everything built on it is wrong as well, and the fault stays hidden inside a calculation that somebody else has already made. A figure that ***looks*** official is rarely questioned. The problem only comes to light when a result has to be explained or defended.

Three assessments were therefore carried out before any development work began:

1. **A structural review**: the number of records, the fields present, and how each field is stored
2. **A check on missing values**: where data is blank, and whether the blank can be explained
3. **A reliability test of the supplied figures**: whether they measure what they claim to measure

The third check produced the most important finding of this stage. **Both supplied figures were tested, and both were rejected.** The reasons are set out below.

**A note on scope.** No data is altered at this stage. This notebook examines and records only. All corrections are applied at Stage Two, implemented in SQL.

---

## 1. Structural review

The notebook fetches the dataset straight from its published source each time it runs, rather than relying on a copy downloaded by hand. This means the data is always the same as the source, with no separate copy to keep up to date. It also means anyone can run the work again and check it.

The complete version of the dataset was used instead of the shortened version which circulates more widely. The shortened version removes the customer lifetime value figure, the recorded reason for departure, and the geographic detail. Not every one of these fields is used in the analysis that follows, but each of them was needed for this project.

7,043 records across 33 fields were found in the dataset, which is consistent with what was expected. The full list of field names was checked before any further work was done on the data. If fields were absent, that needed to be known early, rather than discovered after substantial work had been completed.

The first ten records were also displayed, to see the format of the values and pick up anything obviously wrong.

---

## 2. Assessment of missing values

All fields were examined for missing values. **Only one field contains any: the recorded
<u>reason for departure</u>, which is absent for 5,174 customers.**

At first, this looked like there was a serious gap in the data, affecting nearly three quarters of the dataset in one field, but a closer look showed that it is not.

The reason for departure is recorded for **1,869 customers** and empty for the remaining **5,174**. Those 1,869 are exactly the customers who have left the business. The 5,174 are the customers who are still with it.

The field is therefore populated only where a customer has actually departed. Where a customer remains with the business, no reason exists to be recorded. **The field is not incomplete; it is correctly empty.**

**No values were substituted, and the reasoning matters.**

A common habit in data preparation is to fill missing values automatically, usually with an average or a stand-in value, before finding out why they are missing. Doing that here would have invented a reason for departure for 5,174 customers who have not departed. Every later analysis using that field would then have rested on made-up data.

The lesson is that the cause of a gap should be understood before deciding whether to fill it. In most cases, understanding the cause shows that the gap should be left alone.

---

## 3. Review of field types

Each field is stored in a set format, as a number, a date, or as text. A field holding amounts of money should be stored as a number, so that it can be added up and averaged.

One field failed this requirement. **Monthly charges is stored as a number, whereas total charges is stored as text.** Both contain monetary amounts and both should therefore be numeric.

There is a specific reason for this. If even one entry in a column cannot be read as a number, the entire column is treated as text. One unreadable value among 7,043 records is therefore enough to make the whole field unusable for calculation.

The quick response would have been to convert the whole column in one go and throw away any values that failed. This was not done. Converting first and investigating afterwards destroys the evidence needed to find the cause.

Each value was tested on its own instead, and those that failed were set aside and examined.

**Finding: eleven records are affected, and all eleven share an identical profile:**

- Tenure of **zero months**
- A monthly charge on record
- **Active customer status**

The explanation is simple. These are new customers who have agreed a price but have not yet been billed for a full month. No total charge exists because no charge has been raised yet.

**The blank value is therefore correct rather than broken.** It records something that is genuinely true.

**Decision: put zero in, and keep all eleven records.**

Zero is the right figure, as these customers really have paid nothing so far. Deleting the eleven records would have been quicker, and is what usually happens in practice. It would also have removed every single new customer from the analysis.

That matters more than it first appears. As Stage Two shows, new customers are the group most likely to leave. Removing them would have tilted the whole analysis before the real work had even started.

---

## 4. Reliability testing of the supplied customer lifetime value figure

Once the field types were corrected, summary figures were produced for each numeric field, covering the lowest value, the highest value, the average and the spread.

This produced the most important finding of the stage.

**The supplied customer lifetime value figure has a minimum of 2,003 and a maximum of 6,500. Total charges, representing revenue already collected from customers, reaches 8,684.**

This cannot be right. Customer lifetime value is the total worth of a customer to the business across the whole relationship. It cannot be lower than money the business has already taken from that customer. A figure that caps a customer's worth at 6,500 when they have already paid 8,684 is not a figure measured in money.

The upper and lower limits give a second warning sign. No customer scores below 2,003, and none above 6,500. Real customer value does not behave like that. Any real customer base has customers who are worth almost nothing and customers who are worth a great deal.

With two warning signs, the figure was put to a proper test rather than judged by eye.

### The basis of the test

Whatever formula is used, customer lifetime value is driven by two things: **the amount a customer pays each period**, and **how long the relationship lasts**. Any sound lifetime value figure must therefore move with both. A long-standing customer paying a high monthly charge must rank above a new customer paying a low one.

That gives something that can be tested: **does the supplied figure rank customers in the same order as the things it is built from?**

### Method

The test used **rank correlation**, which measures whether two things put a set of items in the same order. It ignores scale completely.

Ignoring scale was deliberate. The figure was already suspected of sitting on a made-up scale, so testing its size would have proved nothing. The narrower question was whether it at least put customers in a sensible order.

The result is expressed as a value between −1 and 1:

- A result close to **1** means the two measures rank customers almost the same way
- A result close to **0** means there is no relationship
- A result close to **−1** means they rank customers in opposite order

### Results

| Supplied figure tested against | Result           | Expected for a valid measure |
| ------------------------------ | ---------------- | ---------------------------- |
| Tenure with the business       | **0.37**   | Strong positive              |
| Total amount paid              | **0.31**   | Strong positive              |
| Monthly charge                 | **0.11**   | Strong positive              |
| Whether the customer departed  | **−0.12** | Clearly negative             |

All four results fall well below what would be needed. **The third result settles the question.**

The monthly charge feeds directly into customer lifetime value. Doubling the monthly charge should roughly double the lifetime value. The relationship found is **0.11**, which is effectively no relationship at all.

A figure that barely moves when the amount a customer pays changes is not measuring what that customer is worth.

### Conclusion

Taken together, limits that cannot be right and almost no relationship to the things the figure is built from leave no room for doubt.

**The supplied customer lifetime value figure is a score on a made-up scale. It is not an amount of money, and it was rejected.**

Customer value is worked out from scratch at Stage Two instead, using the real monthly charges and the real tenure, with every assumption written down and open to challenge.

**The new figure is deliberately never checked against the supplied one.** Once a measure has been shown to be unreliable, it cannot be used as the yardstick for the work replacing it. Doing so would bring back the very fault just found.

---

## 5. Fields excluded from the model

A model finds patterns in the information it is given. If that information quietly gives away the answer, the model will look like it is performing very well while having learned nothing useful. This is known as **leakage**.

Three fields were left out of the model, each for a different reason. The difference matters, because fields like these are often lumped together as though they were the same.

### The churn score: excluded because of leakage

This field contains IBM's own prediction of customer departure, supplied with the dataset.

Including it would mean the model was no longer predicting customer departure at all, it would simply be copying another model's answer. Reported performance would look excellent, because the model would be repeating a supplied answer rather than finding any real pattern.

A second objection matters more in a regulated industry. IBM has not published the method behind the score. A model using it could not be fully explained, because one of its main inputs cannot be explained.

This project deliberately uses a model whose reasoning can be traced and shown to a regulator. Feeding in something that cannot be explained would defeat that.

### The recorded reason for departure: excluded because of leakage

This field records the reason a customer gave for leaving and, as set out above, only exists for customers who have already left.

Using it to predict would show only that any customer with a reason recorded has left. That is true, useless, and not a prediction.

**The field is still kept in the database** and used in reporting. Knowing that most leaving customers point to a competitor's offer is genuinely useful to the business.

The difference is between information a model may learn from and information a report may show. The field is fine for explaining departures that have happened, and no use for predicting ones that have not.

### The supplied customer lifetime value figure: excluded because it is unreliable

This one is left out for a completely different reason. The field does not give away the outcome. It was left out because, as shown in Section 4, it does not measure what it claims to measure.

Put simply:

- **The churn score and the recorded reason for departure are sound information that only becomes available at the wrong moment.**
- **The supplied lifetime value figure is not sound information at any moment.**

### Fields carrying no information

Four further fields were removed for a simpler reason:

- One field records the value 1 for every customer
- One records "United States" for every customer
- One records "California" for every customer
- One combines latitude and longitude into a single text value, both of which are already present as separate numeric fields

A field that holds the same value for every record says nothing and cannot help any analysis.

---

## 6. A recording issue within the service fields

Six fields record optional additional services which a customer may hold: online security, online backup, device protection, technical support, streaming television and streaming films.

Each of these fields holds **three possible values rather than two**: "Yes", "No", and "No internet service".

**The third value is not another way of saying "No", and treating it as one would be a serious mistake.**

- **"No"** means the service was offered and turned down.
- **"No internet service"** means the service was never available, because the customer holds no internet subscription.

The first customer made a choice. The second was never given one. They are two completely different groups.

In most standard data preparation, the third value would simply be folded into "No", because at a glance the two look the same. Stage Two shows what that shortcut would have cost: the two groups of customers leave at rates seven times apart.

The fields were therefore kept exactly as supplied. How to handle them is decided openly at Stage Two rather than being swallowed up by an automatic preparation step.

---

## Constraints of the dataset

The dataset is a **snapshot taken at a single moment**. Each record describes one customer at one point in time. It holds no dates, no history of transactions, and no record of how customer behaviour changed over time.

This limits what the project can honestly claim, and the limit is stated here rather than left for a reader to find.

**The model cannot say which customers will leave within the next ninety days.** A claim like that needs customers to be watched over a set period, and this dataset holds no time information at all.

What the model can honestly say is narrower, but still useful to the business: whether a customer's present profile looks like the profiles of customers who have already left.

A real system inside a telecommunications provider or a bank would be built differently. It would watch customers over a set period and track changes in their behaviour, falling usage, more calls to support, late payment, cancellation of individual products. These are the earliest signs that a customer intends to leave, and none of them are present in this dataset.

---

## Summary of findings

| Finding                                                                                                            | Action taken                                         |
| ------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------- |
| 7,043 customers across 33 fields, of whom 1,869 departed                                                           | Dataset confirmed as suitable for the project        |
| Missing values found only in the recorded reason for departure, fully explained by whether the customer left       | Left alone, as the blank is correct                  |
| Total charges stored as text because of 11 unbilled new customers                                                  | Set to zero; all 11 records kept                     |
| Supplied lifetime value figure has limits that cannot be right and almost no relationship to what it is built from | Rejected; value worked out from scratch at Stage Two |
| Churn score and recorded reason for departure both give away the outcome                                           | Left out of the model; reason kept for reporting     |
| Four fields hold the same value for every record                                                                   | Removed                                              |
| Six service fields carry a third value meaning "never available"                                                   | Kept as supplied; dealt with openly at Stage Two     |

**Next stage:** build the database, work out the measures the model needs, and calculate customer value.

---

## Concluding principle

The dataset was supplied with a customer lifetime value figure already calculated and a churn prediction already produced. Both could have been adopted without comment, and the project would have progressed more rapidly as a result.

Both were tested. Both failed.

The work described above is not data cleaning in the usual sense. It represents a decision to establish whether supplied figures are sound before building upon them, and a willingness to discard them where they are not.
