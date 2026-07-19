# Stage Three: Model Construction, Testing and Selection

**Notebook:** `03_modelling.ipynb`

---

This is the third of four documents describing a project which predicts which customers of a telecommunications provider are likely to leave, and works out which of them are worth the cost of keeping. The project and the source data are introduced in the Stage One document. The four write-ups form one continuous account, read in order and without reference to the underlying code.

Stage Two produced a structured database covering all 7,043 customers. For each customer it holds seven worked-out measures: how long they have been with the business, how many extra services they hold, how easily they can end their contract, and others, together with a value for that customer. It also produced the finding the project rests on: the customers most likely to leave are the least valuable the business has.

This stage deals with a single question: **based on what is known about a customer today, how likely are they to leave?**

---

## What a model does

A model is given a set of past customers, along with what happened to each one, whether they left or stayed. It finds the patterns that separate the two groups.

Once trained, the model can be shown a customer and asked how likely that customer is to leave. The answer comes back as a probability between 0 and 1.

Two models were built for this project.

**A logistic regression.** This method fits a single equation. Every piece of information about a customer is given one number, showing which way it pushes the outcome and how hard. A large positive number pushes strongly toward leaving. A negative number pushes toward staying.

**A gradient boosting model.** Instead of one equation, this method builds several hundred small rules one after another, each one fixing the mistakes of the ones before it. It can pick up more complicated patterns, for example that a high monthly charge only matters for customers who are free to leave at any time.

### The choice was made before the results were known

**The logistic regression was always the intended model to use, because its reasoning can be explained.**

Because every piece of information carries a single readable number, any one prediction can be traced back to the things that caused it. A customer was flagged as at risk because of their contract type, their monthly charge and how long they have been with the business, in stated proportions that anyone can check.

Inside a bank or a telecommunications provider this is not a preference. It is a requirement. A customer may ask why a decision about them was made. A regulator may ask the business to show that the decision rested on solid ground. **A model that cannot show its reasoning cannot meet that requirement**, however accurate it is.

The gradient boosting model was still built. Saying the simpler method is preferred only carries weight if the more complicated one has been built and measured. Without that comparison, the choice looks like avoiding the harder work rather than a considered decision.

---

## 1. Deciding what information the model gets

Not every piece of information belongs in a model. Four kinds were left out on purpose, each for a different reason.

**The customer reference number.** This identifies a customer but says nothing about them, so it cannot help predict behaviour.

**Whether the customer left.** This is the thing being predicted, so it cannot also be an input.

**Everything to do with customer value.** The customer value figure, the profit earned so far, the expected remaining time and the value group were all left out. This is the most important of the four exclusions.

The reasoning is central to the project. **How likely a customer is to leave and how much that customer is worth are two separate questions.** The model answers the first. Stage Two answered the second. The two are only brought together at Stage Four, at the point where the decision to act is taken.

If customer value were fed into the model, that separation would be lost. The model's answer would already have value baked into it. It would then be impossible to show that sorting customers by value gives a different, and better, list than sorting them by risk. The main argument of the project would collapse.

**Information recorded twice.** Four further fields repeat information already there: tenure in banded form, monthly spend in banded form, contract type written out in words rather than ranked, and the internet indicator, which is already inside the internet service field.

Giving a model the same fact twice causes a particular problem, looked at in Section 5 below. In short, the model splits the effect between the repeated items more or less at random, and the resulting numbers stop being trustworthy. Since those readable numbers are the whole reason for choosing this model, the repeats were removed. The banded forms stay in the database for reporting, where grouping is exactly what is wanted.

**Turning text values into numbers.** Internet service is recorded as text: DSL, fibre optic, or none. A model cannot read text, so these values were turned into number columns.

One of the three was left out on purpose. A customer who holds neither fibre nor "none" must hold DSL, so the third column adds nothing and would bring back the repetition described above. DSL therefore acts as the starting point, and the other two columns are read as differences from it.

**Nine measures went into the model.**

---

## 2. Splitting the data before training

The customers were split into two groups. The model learns from the first and is tested against the second, which it never sees during training.

**This split is what makes the test mean anything.** A model tested on the same records it learned from may simply repeat what it has memorised, reporting a level of performance it could not reach against customers it had never seen.

Three settings were used.

**One quarter of customers were held back**: 5,282 records for training, and 1,761 kept aside for testing.

**Both groups had to hold the same proportion of customers who left.** Across the whole dataset, 26.5 percent of customers left. Without this setting, a random split could easily produce a test group with an unusual share of departed customers, which would make every later measurement misleading. Both groups came back at 26.5 percent, which confirms the setting worked.

**The split was fixed so that it comes out the same way every time.** Anyone re-running the notebook gets the same split and therefore the same figures, and can check them. Without this setting, the reported figures would shift slightly each time and nobody could confirm them.

---

## 3. Training the model

Three things were done during training, each dealing with a specific problem.

**Putting the measures on a common scale.** The measures are recorded in very different units. Total charges run into the thousands, while the count of extra services runs from zero to six.

Left alone, the model would treat the bigger figures as more important purely because they are bigger. Scaling puts every measure on an equal footing, so the resulting numbers reflect real influence rather than the unit of measurement.

**Joining the scaling and the model into one process.** This is about being correct, not about convenience. The scaling has to be worked out from the training data alone and then applied unchanged to the test data. Doing the two steps separately makes it easy to scale all the data together by mistake, which lets information from the test group leak into the training and makes the reported performance look better than it is.

**Correcting for the imbalance between the two outcomes.** Only 26.5 percent of customers left. A model chasing overall accuracy could therefore score 73.5 percent simply by predicting that nobody ever leaves. That answer is arithmetically correct and commercially useless.

The model was told to treat a missed departure as a more serious mistake than a false alarm, with the weighting set by how rare departures are.

---

## 4. Testing performance

### The measures used

**Precision**: of the customers the model flags as at risk, the share who really did leave. Low precision means retention money is going to customers who were not leaving anyway.

**Recall**: of the customers who really did leave, the share the model found. Low recall means customers are being lost with no warning.

These two measures pull against each other. Flagging more customers catches more real departures but wastes more money. Flagging fewer wastes less but lets more losses through. **The balance between them is a commercial decision, not a technical one**, and it is exactly the decision Stage Four exists to inform.

**ROC AUC**: a single figure between 0.5 and 1.0 describing how well the model tells leavers apart from stayers. A figure of 0.5 means the model is no better than guessing. Around 0.84 is the usual range for this dataset. A figure close to 1.0 would suggest the inputs contained something that gives the answer away.

### Results

**ROC AUC: 0.840**, inside the expected range, which confirms that no information about the outcome had leaked into the inputs.

Of the 1,761 customers held back for testing, 467 really did leave. The model:

- **Found 370 of them**
- **Missed 97**
- **Flagged 732 customers in total**, meaning **362 flags** were customers who stayed

That works out at **79.2 percent recall** and **50.5 percent precision**.

### What this means commercially

About four in every five leaving customers are found. For each real departure found, roughly one extra customer is flagged for no reason.

Whether that is a sensible way to spend money depends entirely on the cost of contacting a customer against what that customer is worth. For a customer in the top value group, worth R1,044, spending R340 on a false alarm is easily absorbed. For a customer in the bottom group, worth R81, the same spend destroys value even when the approach works.

**This is why Stage Four exists**, and why the model's answer is kept as a probability rather than a flat yes or no. A probability can be weighed against a customer's value. A yes or no cannot.

### A deliberate note about accuracy

**Overall accuracy came out at 73.9 percent**, slightly below the 73.5 percent available from predicting that nobody ever leaves.

Judged on that measure alone, the model looks worse than doing nothing at all. In practice it finds four in every five leaving customers.

Any model dealing with a fairly rare event shows this pattern. Reported on its own, accuracy would have suggested throwing away a model that works, which is why precision and recall are reported instead.

---

## 5. Looking at the model's reasoning

Because this is a logistic regression, every measure carries a single number showing its influence. These were printed out and examined.

A positive number pushes toward leaving. A negative number pushes toward staying. Since every measure was put on a common scale, the sizes can be compared directly against each other.

### Results that matched the Stage Two findings

| Measure                  | Value            | What it says                                                 |
| ------------------------ | ---------------- | ------------------------------------------------------------ |
| Monthly charge           | **+1.84**  | A higher monthly charge is the strongest push toward leaving |
| Contract risk            | +0.73            | Month-to-month customers leave more often                    |
| Tenure                   | **−1.22** | Longer-standing customers leave less often                   |
| Additional services held | −0.82           | Each extra service makes leaving less likely                 |

Each of these matches a finding already produced on its own at Stage Two, using completely separate methods. That agreement is itself a check on the work.

### Two results that did not match

**Total charges, at +0.57**, said that customers who have paid more over their lifetime are *more* likely to leave. This directly contradicts the tenure result, which says the opposite. Both cannot be right.

**Fibre optic, at −0.27**, said that fibre customers leave *less* often, when fibre customers are known to be the group with the highest departure rate in this dataset.

### The cause

**Two of the measures overlapped with others already there.**

Total charges is roughly the monthly charge multiplied by the number of months the customer has held an account. It brings nothing new: it is two measures already in the model, multiplied together.

Where two measures carry the same underlying information, the model splits the effect between them more or less at random. **The predictions themselves stay sound**, which is why the figure of 0.840 is real, but the individual numbers stop being reliable.

Since those numbers are the whole reason for choosing this model, the situation could not be left as it was.

---

## 6. Removing the repeated measure and training again

Total charges was removed and the model trained again.

**The figure moved from 0.840 to 0.838.** Effectively unchanged, which confirms the measure added nothing but confusion. Removing it is therefore a decision that can be defended, rather than a loss that needs explaining.

**More importantly, the tenure result corrected itself**, moving from −1.22 to −0.74. That movement is the evidence. Its value had been thrown off by the repeated measure and settled down once the repetition was removed.

### The fibre result, read correctly

The fibre result stayed negative. Looking into it showed this was not a fault.

**A number of this kind always describes the effect of one thing while everything else is held the same.** A value of −0.28 therefore does not mean fibre customers leave less often. It means that comparing a fibre customer and a DSL customer *paying the same amount each month*, the fibre customer is slightly less likely to leave.

This was checked directly against the data:

| Internet service | Customers | Proportion departed |
| ---------------- | --------- | ------------------- |
| Fibre optic      | 3,096     | **41.9%**     |
| DSL              | 2,421     | 19.0%               |
| None             | 1,526     | 7.4%                |

Fibre customers do leave at more than twice the DSL rate. They also pay a good deal more, and the monthly charge has already taken care of that. **The model has separated the effect of price from the effect of the product itself.**

---

## 7. Building the comparison model

The gradient boosting model was then trained on the same nine measures.

No scaling was applied. Models of this kind split the data at cut-off points rather than measuring distances between values, so differences in units do not affect them.

### The first comparison was not fair

The first attempt gave a figure of 0.829 and recall of 48.6 percent, which looked a lot worse than the logistic regression.

**The comparison was, however, tilted in favour of the preferred model.** The logistic regression had been given the imbalance correction described in Section 3. The gradient boosting model had not.

It was therefore chasing overall accuracy, which on data like this means leaning toward predicting that customers will stay. That fully explains its low recall. The comparison was measuring a difference in settings, not a difference in method.

**The unfair comparison is kept in the notebook rather than deleted**, because the correction teaches more than a clean result would have.

---

## 8. The comparison done on equal terms

The gradient boosting model was trained again with the same imbalance correction.

| Measure                      | Logistic regression | Gradient boosting |
| ---------------------------- | ------------------- | ----------------- |
| ROC AUC                      | **0.838**     | 0.833             |
| Departures found             | **79.2%**     | 76.2%             |
| Precision                    | 50.5%               | 50.7%             |
| Reasoning open to inspection | **Yes**       | No                |

**The simpler model came out slightly ahead on both headline measures, and it is the model whose decisions can be explained.**

This is an unusually lucky outcome. The usual argument is that a small drop in performance is a fair trade for being able to explain the model. Here there is no drop to defend.

**One qualification is needed.** The two results are close enough that a different random split of the data could swap their order. The claim that can be defended is therefore not that the logistic regression is better, but that **the extra complexity of gradient boosting brings no measurable benefit on this dataset**, and where complexity brings no benefit, the model that can be explained is the right choice.

---

## Findings from the model

### Finding 1: Price is the single strongest influence on leaving

The monthly charge carries the largest value of any measure, larger than contract type, larger than tenure, and larger than the number of services held.

**What this means commercially.** A retention conversation that does not deal with the customer's bill is dealing with a side issue. Contract type and length of relationship both matter, but the amount a customer pays each month affects their decision more than anything else measured here.

It also sets a limit on what the business can fix. Part of this risk cannot be managed through better service or more contact. A customer leaving because their bill is too high is leaving for a reason that only a pricing decision can settle.

### Finding 2: Fibre has a pricing problem, not a product problem

Fibre customers leave at 41.9 percent, more than twice the DSL rate of 19.0 percent. On that figure alone, the natural conclusion is that something is wrong with the fibre service, and the natural response is to investigate service quality.

The model shows otherwise. Once price is held the same, fibre customers are slightly *less* likely to leave than DSL customers paying a similar amount. The higher departure rate is explained by fibre customers paying more, not by the product itself.

**What this means commercially.** The right response is a pricing review, not a service investigation. These are very different pieces of work with very different costs, and the raw departure figure points to the wrong one.

This is the clearest example in the project of why a model that can be explained earns its place. A model producing only a probability would have marked fibre customers as high risk and stopped there. The individual numbers show *why*, and the reason decides what the business should actually do.

### Finding 3: About half of any retention spend will reach customers who were not leaving

The model finds 79.2 percent of leaving customers. It also flags roughly one extra customer for every real departure it finds.

**This is not a fault to be fixed. It is how the model works**, and it holds for any model built on data of this kind. Leaving cannot be predicted with certainty from a customer profile, because the decision depends on things the business cannot see: a competitor's offer, a house move, a change in household income.

**What this means commercially.** The decision to act cannot rest on the model's answer alone. Contacting a flagged customer costs the same whether or not that customer meant to leave. The question is therefore always whether the value protected covers the total spend, including the share that will be wasted.

**The model shows who is at risk. It cannot show who is worth keeping.** That is a separate question, and it is exactly why customer value was kept out of the model and worked out on its own.

### Finding 4: The extra complexity brought no benefit

The usual argument for choosing a model that can be explained is that a small drop in performance is a fair trade. On this dataset there is no drop to weigh: 0.838 against 0.833.

**What this means commercially.** In a regulated industry the explainable model would have been the right choice even at a small disadvantage, because a decision that cannot be explained cannot be defended to a customer or a regulator. Here the choice costs nothing at all.

One wider point is worth making. **The real gains in this project came from understanding the data** rather than from the choice of method: correcting the recording issue at Stage Two, removing the repeated measure at this stage, and keeping value and risk apart throughout.

---

## Summary of findings

| Work undertaken                                                   | Outcome                                                               |
| ----------------------------------------------------------------- | --------------------------------------------------------------------- |
| Nine measures chosen, all value information deliberately left out | Risk and worth kept as two separate questions                         |
| Data split into training and test groups, proportions kept        | Both groups at 26.5% departed                                         |
| Logistic regression trained with the imbalance corrected          | Figure of 0.840, with 79.2% of departures found                       |
| The model's reasoning examined                                    | Two results did not match and were investigated                       |
| Repeated measure removed                                          | Performance unchanged; a distorted result corrected itself            |
| Fibre result investigated rather than accepted                    | Found to be correct once read properly; price identified as the cause |
| Gradient boosting built and compared                              | First comparison found to be unfair, and corrected                    |
| Final comparison done on equal terms                              | 0.838 against 0.833, so the extra complexity brings no benefit        |

**Model selected:** the logistic regression, because its decisions can be explained, a choice which on this dataset costs nothing in performance.

**Next stage:** work out which customers are worth the cost of contacting.

---

## Limits of the dataset

The limit recorded at Stage One matters directly for the model built here. The dataset is a single snapshot taken at one moment, with no dates and no record of how customer behaviour changed over time. The model therefore cannot say which customers will leave within a set future period. A claim like that needs customers to be followed over time, and there is no time information in the data.

What the model can fairly say is narrower: whether a customer's profile today looks like the profiles of customers who have already left. Every probability produced at this stage, and every figure built on those probabilities at Stage Four, means that and nothing more.

---

## Concluding principle

Two parts of this stage were wrong at first: a result which contradicted a finding already established, and a model comparison tilted toward the preferred answer.

Both were found, corrected, and left visible in the record rather than removed.

A model reporting a good result is common. A model whose author can show what was checked, what turned out to be wrong, and how the mistake was found is the one that can be trusted.
