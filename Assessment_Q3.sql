/* OBJECTIVE: Identify all savings and investment plans 
that have not received any successful inflow transaction 
in the past 365 days (i.e., inactive for at least a year).
*/

-- Step 1: Get the most recent successful inflow transaction per savings/investment plan
WITH latest_transactions AS (
    SELECT 
        s.plan_id,  -- Unique ID for the savings/investment plan
        s.owner_id,  -- User ID associated with the plan
        MAX(CAST(s.transaction_date AS DATE)) AS last_transaction_date  -- Latest successful inflow transaction date
    FROM savings_savingsaccount s
    WHERE s.transaction_date IS NOT NULL  -- Ensure transaction date is available
      AND s.transaction_status = 'success'  -- Only consider successful transactions
      AND s.confirmed_amount > 0  -- Only count transactions where funds were actually added
    GROUP BY s.plan_id, s.owner_id  -- Aggregate by plan and user
),

-- Step 2: Join with plans table and calculate inactivity duration
plans_with_last_txn AS (
    SELECT 
        p.id AS plan_id,  -- Unique ID for the plan
        p.owner_id,  -- User ID associated with the plan
        CASE 
            WHEN p.is_regular_savings = 1 THEN 'Savings'  -- Label as 'Savings' if it's a savings plan
            WHEN p.is_a_fund = 1 THEN 'Investment'  -- Label as 'Investment' if it's an investment plan
        END AS type,  
        lt.last_transaction_date,  -- Most recent inflow transaction date
        DATEDIFF(CURDATE(), lt.last_transaction_date) AS inactivity_days -- Days since last inflow; use a default fallback date if none
    FROM plans_plan p
    INNER JOIN latest_transactions lt ON p.id = lt.plan_id  -- Join with latest inflow transactions
    WHERE 
       (p.amount > 0)  -- Include plans with amount to check for active account
       AND (p.is_regular_savings = 1 OR p.is_a_fund = 1)  -- Filter to only include Savings or Investment plans
)

-- Step 3: Select only inactive plans (no inflow in the last 365 days)
SELECT 
    plan_id,  -- ID of the inactive plan
    owner_id,  -- User who owns the plan
    type,  -- Type of plan: Savings or Investment
    last_transaction_date,  -- Last inflow transaction date
    inactivity_days  -- Number of days since the last inflow
FROM plans_with_last_txn
WHERE inactivity_days > 365  -- Filter for plans inactive for over a year
ORDER BY inactivity_days DESC;  -- Sort by longest inactivity first
