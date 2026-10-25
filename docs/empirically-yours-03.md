# Cash in Hand, Debt on the Card
### Why people with savings say they'd keep more cash instead of paying down debt

*Household Finance Lab · Lena Gan & Sara Kay · October 2026*

---

A former client of mine had more than a million dollars in a portfolio.

They also had $25,000 on a credit card.

When I asked why they didn't just pay it off, they said: "We're thinking of putting a down payment on our vacation home."

It sounded reasonable. Financially, it wasn't.

So I asked: can your portfolio reliably return 22% a year?

They were surprised. That's about what credit cards charge on a balance. Paying off the card would have been a guaranteed 22% return.

They reconsidered.

This couple wasn't careless. They had simply labeled the money for the vacation home. The card was just the card.

## The question

Economists call this the co-holding puzzle: carrying expensive card debt while holding cash that could pay it off.

The Federal Reserve's 2025 Survey of Consumer Finances asked a brand-new question that let us look at it:

*Imagine you unexpectedly received an extra month of your normal income. What percent would you spend, save, and use to pay down debts?*

So we asked: **among families carrying a credit card balance, do the ones who already hold cash say they'd put less of that extra money toward debt?**

## What we did

We used the 2025 survey, released in October 2026. It's the most detailed picture of American family finances there is.

We focused on the 1,568 families carrying a credit card balance after their last payment.

We split them into two groups. Families with more than a month of income sitting in checking and savings. And families without that cushion.

Before running anything, we checked our numbers against the Fed's. Across all families, the answer averaged 22% spend, 47% save, 30% pay down debt. Ours matched.

One more thing about this survey. When a family skips a question, the Fed fills in the answer five plausible ways. So we ran everything five times and combined the results, using the Fed's own method for measuring uncertainty.

## What happened

Families without a cash cushion said they'd put about half the extra money toward debt.

Families with a cushion said just over a third.

After accounting for income, wealth, the size of the card balance, other debts, age, education, and family situation, the gap was still **12.5 percentage points.**

Where would the money go instead? Into savings.

People with cash said they'd add to the cash.

## Then we checked it from every angle

We changed what counts as "a cushion," from half a month of income to three months.

We dropped families who usually pay their card in full.

We dropped people on 0% promotional rates. We used different statistical models.

The gap held every time, somewhere between 9 and 13 points.

## One pattern that didn't hold up

Sara's prediction model pointed to something interesting: maybe higher-income families with savings answered differently.

It was tempting. It was also an idea that came from looking at the results, which is exactly when a pattern is most likely to be luck.

So we checked it once, and said so.

The gap barely changed across income levels. The pattern didn't hold up, and it didn't improve the predictions.

So we stopped looking.

Choosing not to chase the next pattern is part of the result too.

## What we don't know

**What families would actually do.** This was a hypothetical question.

**Why.** Saving for a goal, needing cash for bills a card can't pay, or just feeling safer: all plausible, none measured.

**Whether the interest rate matters.** We expected families with higher card rates to put more toward debt. The analysis couldn't tell either way.

**Whether the money would go to the card.** The question asked about debts of any kind.

And my client held investments, while the survey measures cash. The data tell a related story, not the same one.

One more honest note. A recent study at an Australian bank found that simply *telling* people what co-holding costs them changed little. My client changed their mind. Maybe a conversation with someone you trust works differently from a disclosure.

That's a question, not a finding.

## So what?

The usual advice assumes people compare interest rates.

Our results suggest many people compare *labels*.

A dollar labeled "safety" tends to stay where it is, even when paying down the debt would earn more.

## Where this goes next

If knowing the cost doesn't change our minds, what does?

## We didn't get here first

Economists have studied the co-holding puzzle for more than twenty years, and the Fed has already analyzed how families would *spend* this windfall. What was missing was how families with cash say they'd split extra money between debt and savings. The repository lists the papers that shaped our thinking, what each established, and what we think remains open.

## Want the machinery?

The data construction, validation checks, Stata models, Python predictions, robustness tests, and every analytical decision are in the GitHub repository, including the things that didn't work.

---

*Observational, cross-sectional survey data. Not peer reviewed. The hypotheses and analysis plan were fixed before results were seen. Across checks, the estimated gap ranged from about 9 to 13 percentage points (main estimate 12.5; 95% CI 8.9 to 16.0). Based on 1,568 families carrying a credit card balance in the 2025 Survey of Consumer Finances. Full methods, code, and results are in the repository.*
