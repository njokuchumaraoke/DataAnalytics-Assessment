/* OBJECTIVE: Estimate the Customer Lifetime Value (CLV) for each user 
based on their historical transaction data and 
how long they've been a customer.
*/

-- Step 1: Aggregate transaction data per user
WITH user_transactions AS (
  SELECT
    s.owner_id,  -- User ID
    COUNT(*) AS total_transactions,  -- Total number of transactions made by the user
    SUM(s.amount * 0.001) AS total_profit  -- Assume each transaction yields 0.1% profit (as CLV contribution)
  FROM savings_savingsaccount s
  GROUP BY s.owner_id
),

-- Step 2: Calculate user tenure in months since they signed up
user_tenure AS (
  SELECT
    u.id AS customer_id,  -- User ID
    CONCAT(u.first_name, ' ', u.last_name) AS name,  -- concatentaion of the first name and last name of the user
    TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()) AS tenure_months  -- Duration (in months) since account creation
  FROM users_customuser u
)

-- Step 3: Join both CTEs and calculate estimated Customer Lifetime Value (CLV)
SELECT
  t.owner_id AS customer_id,         -- User ID
  ut.name,                           -- Full name of the user
  ut.tenure_months,                  -- Tenure in months
  t.total_transactions,              -- Number of transactions the user has made

  -- Estimated CLV formula:
  -- CLV = (average transactions per month) * 12 * (average profit per transaction)
  -- This estimates yearly value based on past activity
  ROUND(
    (t.total_transactions / NULLIF(ut.tenure_months, 0))  -- Avoid division by zero for new users
    * 12                                                  -- Project monthly behavior across a year
    * (t.total_profit / NULLIF(t.total_transactions, 0)), -- Average profit per transaction
    2                                                     -- Round the result to 2 decimal places
  ) AS estimated_clv

FROM user_transactions t -- Common Table Expression created in step 1
JOIN user_tenure ut -- Common Table Expression created in step 2
ON ut.customer_id = t.owner_id  -- Join to combine transaction and user tenure data

-- Rank customers by their estimated value from highest to lowest
ORDER BY estimated_clv DESC;
