/* OBJECTIVE: Write a query to find customers with at least one funded savings plan AND
 one funded investment plan, sorted by total deposits.
*/

-- Step 1: Get savings plan details per user
WITH savings AS (
    SELECT 
        s.owner_id,  -- ID of the user who owns the savings plan
        COUNT(DISTINCT s.plan_id) AS savings_count,  -- Number of unique savings plans the user has
        SUM(s.confirmed_amount) AS savings_total  -- Total confirmed savings deposits
    FROM savings_savingsaccount s
    JOIN plans_plan p ON s.plan_id = p.id  -- Join based on plan id  to access plan type information
    WHERE 
        s.confirmed_amount > 0  -- a conditional to ensure savings that have received actual deposits
        AND p.is_regular_savings = 1  -- Filter to retrieve users with savings plans
    GROUP BY s.owner_id  -- Aggregate by user
),

-- Step 2: Get investment plan details per user
investments AS (
    SELECT 
        s.owner_id,  -- ID of the user who owns the investment plan
        COUNT(DISTINCT s.plan_id) AS investment_count,  -- Number of unique investment plans
        SUM(s.confirmed_amount) AS investment_total  -- Total confirmed (funded) investment deposits
    FROM savings_savingsaccount s
    JOIN plans_plan p ON s.plan_id = p.id  -- Join based on plan id  to access plan type information
    WHERE 
        s.confirmed_amount > 0  -- a conditional to ensure investments with actual deposits
        AND p.is_a_fund = 1  -- Filter to retrieve users with investment plans
    GROUP BY s.owner_id  -- Aggregate by user
)

-- Step 3: Combine savings and investment plan info with user details
SELECT 
    u.id AS owner_id,  -- User's ID
    CONCAT(u.first_name, ' ', u.last_name) AS name,  -- concatentaion of the first name and last name of the user
    s.savings_count,  -- Number of savings plans
    i.investment_count,  -- Number of investment plans
    ROUND((s.savings_total + i.investment_total) / 100.0, 2) AS total_deposits  -- Combined deposits from both savings and investments, divide by 100 to convert kobo to naira, rounded to 2 decimals
FROM users_customuser u
-- Ensure we only include users who have both savings and investments
INNER JOIN savings s ON u.id = s.owner_id
INNER JOIN investments i ON u.id = i.owner_id
-- Sort users by their total deposits descending to prioritize highest depositors
ORDER BY total_deposits DESC;
