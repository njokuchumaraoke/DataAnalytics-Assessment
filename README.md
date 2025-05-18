![image](https://github.com/user-attachments/assets/c46dba7a-6626-4d52-94b0-f4b39cfbdfd6) 
<h1 align="center">Cowrywise Data Analytics Assessment</h1>

## Overview

This assessment contains SQL-based solutions to data-related questions designed to evaluate data extraction, transformation, and analysis capabilities. Below are my per-question explanations, followed by the challenges I encountered during the process.

## Report By

- [@njokuchumaraoke](https://www.github.com/njokuchumaraoke)


## Per-Question Explanations

### Question 1: High-Value Customers with Multiple Products

**Objective:**  
The goal here is to identify customers who have shown strong engagement with the platform by having at least one **funded savings plan** and one **funded investment plan**. These are users with potential for cross-selling and long-term value, so I was tasked with finding them and ranking by total deposit volume.

**How I approached it:**  
To keep the logic clean and maintainable, I used two Common Table Expressions (CTEs): one for savings plan and one for investments plan. I filtered only for **confirmed (i.e., funded)** deposits, since those are the ones that matter for engagement. Then, I grouped each by `owner_id` to get both count and sum of deposits per user.

Once I had those two sets, I joined them together to isolate users who appear in both categories (meaning that they’ve funded at least one savings and one investment plan). After that, I brought in user details and computed the total deposits by summing savings and investment deposits.

Finally, I sorted the result in descending order so that the highest value customers (by total deposit volume) appear at the top.

**SQL Concepts I used:**
- **CTEs (`WITH`)** – to break the query into logical, readable parts
- **INNER JOINs** – to combine savings and investment data meaningfully
- **Aggregations** – `SUM`, `COUNT`, and `GROUP BY` to summarize user-level data
- **Filtering** – to focus only on funded plans using conditions like `confirmed_amount > 0`
- **String manipulation** – to cleanly display user full names using `CONCAT`

**WWhy this approach?**  
I prioritized readability and modularity. If this logic ever needs to be adjusted; for example, to include only users who funded in the last 6 months it would be easy to modify within the current structure. This setup is also performant since filtering happens before joins, reducing the data volume early on.


---

### Question 2: Transaction Frequency Analysis

**Objective:**  
The finance team wants to segment customers based on how often they transact monthly. The goal is to classify users as **High**, **Medium**, or **Low Frequency** based on their average monthly transaction rate.

**How I approached it:**  
I started by calculating the **total number of transactions per user**, as well as their **first and last transaction dates**. These two points allowed me to determine how long (in months) each customer has been active.

To avoid any divide-by-zero issues for instance, if someone transacted only in one month I used `GREATEST(..., 1)` to ensure each user had at least one month counted. Then I calculated the average number of transactions per month by dividing total transactions by months active.

With that average, I applied a simple `CASE` statement to classify users into:
- **High Frequency**: 10+ transactions/month
- **Medium Frequency**: 3–9 transactions/month
- **Low Frequency**: 2 or fewer transactions/month

Lastly, I grouped these categories to show how many users fell into each segment and what their average monthly transaction count looked like.

**SQL Concepts I used:**
- **CTEs (`WITH`)** – to structure the logic into readable stages
- **Aggregation** – `COUNT`, `MIN`, `MAX`, `AVG`, `ROUND`
- **Date calculations** – `TIMESTAMPDIFF(MONTH, ...)` to calculate activity span
- **Conditional logic** – using `CASE WHEN` for user categorization
- **Defensive programming** – using `GREATEST(..., 1)` to avoid division by zero

**Why this approach?**  
Splitting the logic into multiple CTEs helped make the query more readable and easier to troubleshoot. Also, building in edge-case protection (like minimum month count) ensures that the query is robust across a wide variety of data conditions. This setup can easily scale or be extended; for example, by adding time filters or segmenting by account type later on.

---
### Question 3: Account Inactivity Alert

**Objective:**  
The operations team wanted to identify accounts—either savings or investment—that have not received any inflow transactions in the past 365 days. These dormant accounts are critical for flagging potential churn and reactivation campaigns.

**How I approached it:**  
I broke the solution into three clear steps using CTEs for better readability and logic separation:

1. **Latest Transactions:**  
   I extracted the most recent successful inflow transaction for each plan using `MAX(transaction_date)` with conditions to ensure the transaction was successful (`transaction_status = 'success'`) and had a confirmed amount greater than zero.

2. **Plan Classification and Inactivity Calculation:**  
   I joined the `plans_plan` table with the latest transactions to:
   - Classify each plan as either **Savings** (`is_regular_savings = 1`) or **Investment** (`is_a_fund = 1`).
   - Ensure these plans had an amount greater than zero.
   - Compute the number of inactive days using `DATEDIFF(CURDATE(), last_transaction_date)`.

3. **Filtering Inactive Accounts:**  
   I filtered the result to include only those plans where the inactivity duration exceeds **365 days** and ordered them in descending order to prioritize the most dormant plans.

**SQL Concepts I used:**
- **CTEs (`WITH`)** – to break the logic into steps: latest transactions → plan details → final filter
- **Date calculations** – `DATEDIFF()` to compute inactivity period
- **Filtering** – only selecting successful inflows with confirmed amounts
- **Joins** – to combine transaction history with account metadata
- **Conditional logic** – `CASE WHEN` to classify accounts as Savings or Investment

**Why this approach?**  
By structuring the logic in modular CTEs, it’s easy to understand, test, and extend. Each CTE has a clear purpose, which improves maintainability. For example, if the definition of inactivity changes (e.g., to 180 days), only one line needs to be updated. This makes the solution practical and production-ready for future ops team needs.

---

### Question 4: Customer Lifetime Value (CLV) Estimation

**Objective:**  
Marketing wants to estimate each customer's Lifetime Value using a simplified model that factors in how long they've been active and how frequently they transact. The idea is to quantify each customer’s potential annual value based on their past behavior.

**How I approached it:**  
I started by calculating two key inputs:
1. **Total Transactions**: Aggregated per user from the transaction table.
2. **Total Profit**: Estimated as 0.1% (`0.001`) of the transaction value, as specified.

In parallel, I calculated **account tenure** using `TIMESTAMPDIFF(MONTH, date_joined, CURDATE())` to get the number of months each user has been active on the platform.

Next, I joined these two data sets and applied the given CLV formula:

`CLV = (Total Transactions / Tenure in months) × 12 × Avg Profit per Transaction `

This assumes that past monthly behavior is a good predictor of future activity and scales it over a year.

To avoid any issues with new users (who might have 0 months of tenure or 0 transactions), I used `NULLIF` to prevent division by zero.

Finally, I sorted the output so that the highest-value customers appear at the top of the list which can be helpful for marketing prioritization or targeted retention efforts.

**SQL Concepts I used:**
- **CTEs (`WITH`)** – to isolate transaction and tenure logic
- **Date math** – `TIMESTAMPDIFF` to measure user lifetime
- **Aggregations** – `COUNT`, `SUM` to compute total transactions and profit
- **Defensive coding** – `NULLIF(..., 0)` to avoid division by zero
- **Calculated fields** – custom formula to derive estimated CLV

**Why this approach?**  
Separating transaction and tenure logic into different CTEs helped keep things clean and modular. This approach makes it easier to adjust the CLV formula in the future; for example, by including customer acquisition cost or churn rate. Also, precomputing profit and transaction totals before combining them reduced repeated logic in the final SELECT.

---

## Challenges

1. **Understanding Schema Relationships:**  
   Some questions required a deeper understanding of the schema. I used schema diagrams (if available) and carefully reviewed column names to ensure accurate joins.

2. **Data Cleaning in SQL:**  
   In some instances, data inconsistencies like nulls or duplicates required additional handling using `COALESCE`, `DISTINCT`, or `CASE WHEN` statements.

3. **Balancing Precision with Practical Assumptions**  
   In Question 4, calculating CLV with limited variables required careful assumptions (e.g., profit rate of 0.1%, static behavior across tenure). I used SQL constructs like `NULLIF(..., 0)` to prevent divide-by-zero issues and ensured that these assumptions were consistently applied — demonstrating attention to detail and data accuracy, two non-negotiables in financial analytics.

4. **Ensuring Query Efficiency While Preserving Clarity**  
   The need to work with potentially large user and transaction tables meant thinking not just about getting the right results, but doing so efficiently. I applied early filtering (e.g., `confirmed_amount > 0`), limited joins only to relevant data, and structured logic into CTEs to make queries readable and performant — a key skill when working with big data platforms like Google Cloud or in tools like Metabase or Looker.

These challenges not only tested my SQL and data modeling skills but also pushed me to think like an analyst who delivers insights with business impact — exactly the mindset this role calls for.

---

## Tools Used

- MySQL workbench
- Markdown for documentation

---

## Conclusion

This assessment helped reinforce my SQL problem-solving skills and data interpretation techniques. I ensured each query was not only functionally correct but also readable and optimized.

As someone passionate about using data to solve real problems, I see this role as a perfect opportunity to contribute meaningful insights while continuing to grow within a data-centric, impact-focused team.

