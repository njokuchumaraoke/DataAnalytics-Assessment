-- Step 1: Get the most recent transaction date per savings/investment plan
WITH latest_transactions AS (
    SELECT 
        s.plan_id,
        s.owner_id,
        MAX(CAST(s.transaction_date AS DATE)) AS last_transaction_date
    FROM savings_savingsaccount s
    WHERE s.transaction_date IS NOT NULL
    GROUP BY s.plan_id, s.owner_id
),

-- Step 2: Join with plans and determine inactivity period
plans_with_last_txn AS (
    SELECT 
        p.id AS plan_id,
        p.owner_id,
        p.status_id,
        -- Identify plan type using flags
        CASE 
            WHEN p.is_regular_savings = 1 THEN 'Savings'
            WHEN p.is_a_fund = 1 THEN 'Investment'
            ELSE 'Unknown'
        END AS type,
        lt.last_transaction_date,
        -- Calculate days since last transaction
        DATEDIFF(CURDATE(), lt.last_transaction_date) AS inactivity_days
    FROM plans_plan p
    LEFT JOIN latest_transactions lt ON p.id = lt.plan_id
)

-- Step 3: Filter for accounts with no inflows in the last 365 days
SELECT 
    plan_id,
    owner_id,
    status_id,
    type,
    last_transaction_date,
    inactivity_days
FROM plans_with_last_txn pt
JOIN users_customuser u ON pt.owner_id = u.id
WHERE inactivity_days > 365
ORDER BY inactivity_days DESC;
