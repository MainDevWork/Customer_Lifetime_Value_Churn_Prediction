# Stage Two: Database Construction and Customer Value Calculation

**Notebook:** `02_schema_build.ipynb`
**Supporting files:** `sql/01_schema.sql`, `02_load.sql`, `02b_validate.sql`, `03_features.sql`, `04_clv.sql`

---

This is the second of four documents describing a project which predicts which customers of a telecommunications provider are likely to leave, the industry term is **churn**, and works out which of them are worth the cost of keeping. The project and the source data are introduced in full in the Stage One document. The four write-ups form one continuous account, read in order and without reference to the underlying code.

Stage One examined the source data supplied by IBM, 7,043 customers of a telecommunications provider in California, with 33 items of information recorded for each. It reached three conclusions which shape this stage:

- Of the 7,043 customers, **1,869 have left** the business.
- Eleven records had no value in the total charges field. These were found to be new customers who have not been billed yet, so the correct value is zero and the records should be kept.
- **The customer lifetime value figure supplied with the dataset cannot be trusted and has been set aside.** Its upper limit was lower than amounts customers had already paid, and it barely moved when the things that drive customer value changed. It is therefore worked out again from scratch at this stage.

---

## The problem this stage addresses

The source data comes as a single flat spreadsheet. Everything known about a customer sits in one row: their location, the products they hold, the amounts they pay, and whether they have left.

That arrangement is convenient for sending a file to someone. It is not suitable for analysis, and it looks nothing like the way a telecommunications provider actually holds its information. In a real business, customer records, addresses, product subscriptions and billing details sit in separate systems, run by different departments and updated at different times.

This stage therefore has four aims:

1. **Split the flat spreadsheet into four linked tables**: matching how the information is really organised.
2. **Load the data and show that nothing was lost or misplaced along the way.**
3. **Work out the measures the model needs**: things such as how long a customer has been with the business, how many products they hold, and how easily they can end their contract.
4. **Work out the value of each customer**: replacing the figure supplied with the dataset, which was rejected.

### How the work is split between the two technologies

All of the above is written in **SQL**, the standard language used to build and question databases. The instructions sit in numbered files which can be opened and read as plain text.

A second technology, Python, is used for three jobs only: opening a connection to the database, fetching the source spreadsheet, and running the SQL files. **No calculation of any kind happens in Python.**

This split was deliberate, for two reasons.

It matches how real businesses work. The database does the heavy processing, and the analysis reads a finished result.

It also keeps the work open to inspection. Every calculation sits in a file that can be opened and read, rather than inside code that has to be run before anyone can see what it does.

---

## 1. Splitting the data into four linked tables

The single flat spreadsheet was reorganised into four linked tables:

| Table            | Contents                                           | Records |
| ---------------- | -------------------------------------------------- | ------- |
| `geography`    | Postal code, city, latitude, longitude             | 1,652   |
| `customer`     | Customer characteristics, tenure, departure status | 7,043   |
| `subscription` | Products and services held                         | 7,043   |
| `billing`      | Payment method and amounts charged                 | 7,043   |

Three of these tables hold one record per customer. The address table is built differently, and the reason is worth setting out.

**Many customers share a postal code.** Recording the city, latitude and longitude against every single customer would mean storing the same address details thousands of times over. Addresses are therefore stored once each, 1,652 postal codes serving 7,043 customers, with each customer record pointing to the right entry.

### A check carried out before the design was accepted

This arrangement only works if each postal code belongs to exactly one city and one set of coordinates. If a single postal code appeared against two different cities, there would be no way to decide which one to record.

This was checked before the design was settled. **All 1,652 postal codes belong to exactly one city and one location, with no contradictions anywhere in the dataset.**

The check was needed. Had it failed, the design would have broken during loading, and the fault would have surfaced later, where it would have been much harder to trace.

### A note on this design

The source data came in flat form. It was not originally built this way. **The four-table design is a decision taken within this project, not an existing structure recovered from the source.**

This is said openly rather than left for a reader to work out. The value of the exercise is not in finding a hidden structure. It is in being able to design one, set out how its parts link together, and have the database enforce those rules.

### Rules enforced by the database

Rather than trusting the data to behave as expected, the database was set up with rules it will not let any process break:

- **No customer and no postal code may be recorded more than once.**
- **A customer record cannot point to an address which does not exist**, and no subscription or billing record can exist without a customer attached to it.
- **All fields must be filled in**, apart from the three which are correctly empty for some customers.

These rules make certain kinds of error impossible rather than just unlikely. If a future load is faulty, the database will reject it rather than quietly store bad information.

---

## 2. Loading the data and checking it

The spreadsheet was loaded into the four tables in a set order, with addresses first. Customer records point to addresses, and a record cannot point to an entry that does not exist yet.

Two corrections were made during loading, both coming out of Stage One.

**Repeated address records were removed.** The spreadsheet holds 7,043 rows but only 1,652 postal codes, each one repeating once for every customer living there. Loading the data unchanged would have created 7,043 address records, most of them copies. Only the distinct addresses were kept.

**Total charges was converted from text into a number.** Stage One found that this field arrived as text because eleven customers had no value in it, and that those eleven are new customers who have not been billed yet. Zero was recorded for them, and all eleven were kept rather than deleted.

### Showing that the load worked

Counting records proves very little on its own. A file can load the right number of records while putting values in the wrong fields.

Five checks were therefore run, each against a figure already established during Stage One. Had the load gone wrong, at least one of these would have come back with the wrong answer.

| Check                                           | Expected | Returned |
| ----------------------------------------------- | -------- | -------- |
| Customers who left                              | 1,869    | 1,869    |
| Records holding a recorded reason for departure | 1,869    | 1,869    |
| Records showing zero total charges              | 11       | 11       |
| Records showing zero months of tenure           | 11       | 11       |
| Customers joining up across all four tables     | 7,043    | 7,043    |

All five returned the expected values.

**The last check is the most important one.** It rebuilds the original single row for every customer by joining all four tables back together, and counts the result.

Had the split lost any customer through a broken link, a mismatched postal code, or a fault in the loading, this figure would come back below 7,043. It came back at all 7,043. Every customer is still correctly linked to their address, their products and their billing record.

These checks sit in a file of their own, `02b_validate.sql`, so that the checking stays visible alongside the rest of the work rather than being buried inside a notebook.

---

## 3. Working out the measures the model needs

The fields as supplied cannot be used by a model directly. The fact that a customer has held an account for thirty-four months is a fact and nothing more. On its own it is not yet something a business can act on.

Seven measures were therefore worked out from the loaded data:

| Measure                      | What it captures                                                  |
| ---------------------------- | ----------------------------------------------------------------- |
| Tenure band                  | Whether the customer is new, established, or long-standing        |
| Internet subscription        | Whether the customer holds internet service at all                |
| Telephone service            | Whether the customer holds a telephone line                       |
| Count of additional services | How many of the six optional services are held, from zero to six  |
| Contract risk                | How easily the customer can end their contract, based on its type |
| Automatic payment            | Whether payment is collected automatically or made by hand        |
| Spend band                   | Monthly charge grouped into low, medium and high                  |

These measures are built as **views**. A view stores the instruction rather than the answer: the calculation runs again each time the measure is asked for.

The alternative would have been to work each measure out once and store the result. Views were chosen because they keep the method visible, as the definition of every measure can be read directly. With 7,043 records there is no meaningful cost in processing time.

---

## 4. Findings from the derived measures

All findings in this section came out of the database, before any model was built.

### Finding 1: Departures are concentrated in the first year

| Tenure             | Customers | Proportion departed |
| ------------------ | --------- | ------------------- |
| Under one year     | 2,186     | **47.4%**     |
| One to three years | 1,856     | 25.5%               |
| Over three years   | 3,001     | **11.9%**     |

Nearly half of all customers in their first year leave. Beyond three years, that falls to about one in eight.

A customer who reaches their third year is roughly four times less likely to leave than one still in their first. **Risk is not spread evenly across the customer base. It sits almost entirely at the start of the relationship.**

**What this means commercially.** Money spent on a customer who is already preparing to leave arrives at the worst possible moment. The same money spent supporting new customers through their first year covers the period in which most of the losses happen.

This finding needs no model, no scoring and no probabilities. It needs only the observation that risk sits inside a clearly identifiable period.

### Finding 2: Each extra product held makes departure less likely

Among customers holding an internet subscription, the proportion leaving falls with each extra service taken:

| Additional services held | Proportion departed |
| ------------------------ | ------------------- |
| 0                        | **52.2%**     |
| 1                        | 45.8%               |
| 2                        | 35.8%               |
| 3                        | 27.4%               |
| 4                        | 22.3%               |
| 5                        | 12.4%               |
| 6                        | **5.3%**      |

A customer holding all six extra services leaves at 5.3%. A customer holding none leaves at 52.2%, **ten times the rate**.

**What this means commercially.** Selling a second or third product to an existing customer is not only a way of earning more from that customer. It also keeps them. This makes selling products together a commercial matter rather than a marketing one, and gives a retention team something to offer besides a price cut.

**One qualification is needed.** This is a pattern seen in the data, not a proven cause. It is entirely possible that customers who were already committed went on to buy extra services, rather than that buying extra services created the commitment. The pattern is strong enough to be worth testing, but it should be put forward as an idea worth trying rather than a settled fact.

### Finding 3: A common shortcut would have hidden the biggest difference in the dataset

The table above covers only customers holding an internet subscription. When all customers holding zero extra services are counted together, including those with no internet subscription at all, the figure comes back as 21.4% rather than 52.2%.

That single figure was hiding two completely different groups of customers:

| Group of customers                                  | Customers | Proportion departed |
| --------------------------------------------------- | --------- | ------------------- |
| No internet subscription, no additional services    | 1,526     | **7.4%**      |
| Holds internet subscription, no additional services | 693       | **52.2%**     |

**The safest customers in the business and the riskiest customers in the business were recorded in exactly the same way.** Seven times apart, averaged together into a single figure which describes neither of them.

This is the recording issue found during Stage One. The six service fields record "No internet service" as a separate value from "No", and most standard preparation routines merge the two because they look the same. They are not the same. The first group turned the service down. The second was never in a position to be offered it.

Had the two values been merged, these two groups would have been stuck together permanently, and **nothing further down the line would have given any sign that anything was wrong.**

**What this means commercially.** The 693 customers who hold an internet subscription and no extra services, of whom more than half leave, are the single riskiest group in the business. They can be found and listed straight away. A shortcut taken during data preparation would have hidden them.

---

## 5. Working out customer value

Stage One rejected the customer lifetime value figure supplied with the dataset. It never goes above 6,500 even though some customers have already paid 8,684, and it barely moves in response to the amounts customers pay or how long they have been with the business.

Customer value is therefore worked out here from scratch, and deliberately never compared against the rejected figure.

### The calculation

> **Customer value = monthly charge × profit margin × expected remaining months**

Each part is set out below.

**The monthly charge** is taken straight from the source data.

**The profit margin** turns revenue into profit. This is needed because revenue is not profit. Serving a customer costs money.

**Expected remaining months** is an estimate of how much longer the relationship will last.

### The assumptions, stated in full

Two of those three parts are not in the dataset. They are assumptions. Both are written into the SQL file itself, so they cannot become separated from the figures they produce.

**Assumption 1: a profit margin of 30 percent.**

Revenue is not profit. Serving a customer costs money across network equipment, support staff, billing systems and hardware. None of those costs appear in this dataset.

Thirty percent sits within the usual range for telecommunications operators. Any figure used here would be an assumption. This one can at least be defended.

**Assumption 2: expected remaining time, set by contract type.**

Twelve further months for month-to-month customers, twenty-four for one-year contracts, and thirty-six for two-year contracts.

An assumption is needed because the dataset is a snapshot taken at a single moment and holds no dates. How long customers actually stay cannot be worked out, because the usual method needs customers to be followed over a period of time and there is no time information in the data.

Contract type is used instead, as the best available sign of how committed a customer is. The departure rates above support this.

**Assumption 3: no adjustment is made for the future value of money.**

Revenue received later is worth slightly less than revenue received today. Over periods of thirty-six months or less, at the amounts involved here, the effect is too small to change any decision about which customers to contact. Leaving it out is a deliberate choice rather than an oversight.

### Finding 4: The customers most likely to leave are the least valuable

| Contract type  | Customers | Average value  | Likelihood of departure |
| -------------- | --------- | -------------- | ----------------------- |
| Month-to-month | 3,875     | **R239** | Highest                 |
| One year       | 1,473     | R468           | In between              |
| Two year       | 1,695     | **R656** | Lowest                  |

**Risk and value run in opposite directions right across the customer base.**

**What this means commercially.** Any retention list sorted by likelihood of leaving will be filled with month-to-month customers, who are the least valuable customers the business has. A retention team working down that list from the top would spend most of its budget on its least valuable customers, while the customers actually worth protecting sit further down the list and never get contacted.

This is the argument the project rests on, and it is already clear before any model has been built.

---

## 6. Grouping customers by value

Customers were sorted by value and split into ten equally sized groups, with group 1 holding the most valuable customers and group 10 the least.

Groups were used instead of amounts in rand because the decision is about relative standing, which customers rank highest, rather than whether a particular amount has been reached.

| Group       | Average value | Proportion departed | Total value of group |
| ----------- | ------------- | ------------------- | -------------------- |
| 1           | R1,044        | 5.5%                | R736k                |
| 2           | R724          | 13.8%               | R510k                |
| 3           | R487          | 12.5%               | R343k                |
| **4** | R355          | **51.7%**     | R250k                |
| **5** | R311          | **48.7%**     | R219k                |
| **6** | R276          | **41.1%**     | R194k                |
| 7           | R242          | 25.9%               | R170k                |
| 8           | R200          | 18.8%               | R141k                |
| 9           | R153          | 23.3%               | R108k                |
| 10          | R81           | 24.3%               | R57k                 |

The customer base carries a total value of **R2.73 million**.

### Finding 5: The commercial opportunity sits in the middle of the value range

Knowing the value of each group is not enough on its own. What matters is how much of that value is actually at risk of being lost.

Multiplying each group's total value by its departure rate gives exactly that:

| Group                                | Share of customers | Value actually at risk |
| ------------------------------------ | ------------------ | ---------------------- |
| Groups 1 to 3 (most valuable)        | 30%                | R154k                  |
| **Groups 4 to 6 (in between)** | **30%**      | **R316k**        |
| Groups 7 to 10 (least valuable)      | 40%                | R109k                  |

**Groups 4 to 6 hold 30 percent of customers but 54 percent of all value at risk.**

The reason is that each end of the value range falls short for a different reason. The most valuable customers are not leaving, as the top group loses only 5.5 percent, so there is little there to protect. The customers leaving in the greatest numbers are not worth enough to cover the cost of keeping them.

The opportunity sits in the middle of the range, where real value and real risk meet.

**What this means commercially.** This group would not be picked out by a list sorted on likelihood of leaving, nor by a list sorted on customer value. It only becomes visible when the two measures are worked out separately and then combined, which is the job of Stage Four.

---

## Summary of findings

| Work undertaken                                                  | Outcome                                                                  |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------ |
| Four linked tables designed, with rules enforced by the database | Postal code checked as a sound identifier before the design was accepted |
| All 7,043 customers loaded                                       | Eleven unbilled new customers corrected and kept rather than deleted     |
| Five checks run against figures established earlier              | All five matched, including a full rejoin returning every customer       |
| Seven measures worked out in SQL                                 | Departures found to sit in the first year, at 47.4%                      |
| Recording issue found at Stage One dealt with openly             | Two groups seven times apart found hidden inside a single category       |
| Customer value worked out on three stated assumptions            | The customers most at risk found to be the least valuable                |
| Customers split into ten value groups                            | 54% of value at risk found in groups 4 to 6                              |

**Next stage:** build, test and select the model.

---

## Concluding principle

Every figure produced in this stage can be traced back to the SQL file which produced it. Every assumption not present in the source data is written down next to the calculation which uses it.

This matters more than the figures themselves. A figure whose origin cannot be seen cannot be defended when questioned, and a figure that cannot be questioned should not be relied upon.
