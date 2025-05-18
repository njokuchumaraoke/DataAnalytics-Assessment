/* OBJECTIVE: Calculate the average number of transactions per customer per month 
and categorize them: "High Frequency" (≥10 transactions/month) , "Medium Frequency" 
 (3-9 transactions/month), "Low Frequency" (≤2 transactions/month)
*/


-- Step 1: Calculate total transactions per user and their first & last transaction dates
WITH user_transactions AS (
    SELECT 
        s.owner_id,  -- User ID
        COUNT(s.id) AS total_transactions,  -- Total number of transactions per user
        MIN(s.transaction_date) AS first_transaction_date,  -- Earliest transaction date per user
        MAX(s.transaction_date) AS last_transaction_date  -- Latest transaction date per user
    FROM savings_savingsaccount s 
    JOIN users_customuser u ON s.owner_id = u.id -- join based on customer id
    WHERE s.transaction_date IS NOT NULL  -- Exclude records with null transaction dates
    GROUP BY s.owner_id  -- Group results by user
),

-- Step 2: Calculate the number of months a user has been active and avoid division by zero
transactions_per_month AS (
    SELECT 
        owner_id,
        total_transactions,
        -- Calculate the number of months between first and last transaction dates
        -- +1 ensures that even if transactions happened in the same month, months_active is at least 1
        -- GREATEST guarantees a minimum of 1 month to avoid division by zero errors later
        GREATEST(
            TIMESTAMPDIFF(MONTH, first_transaction_date, last_transaction_date) + 1,
            1
        ) AS months_active
    FROM user_transactions -- Table expression created in step 1
),

-- Step 3: Calculate average transactions per month and classify users by transaction frequency
categorized_users AS (
    SELECT
        owner_id,
        total_transactions,
        months_active,
        -- Calculate average transactions per month rounded to 2 decimal places
        ROUND(total_transactions / months_active, 2) AS avg_transactions_per_month,
        -- Categorize users based on their average transaction frequency per month
        CASE
            WHEN total_transactions / months_active >= 10 THEN 'High Frequency'  -- 10 or more transactions per month
            WHEN total_transactions / months_active >= 3 THEN 'Medium Frequency'  -- Between 3 and 9.99 transactions per month
            ELSE 'Low Frequency'                                                  -- Less than 3 transactions per month
        END AS frequency_category
    FROM transactions_per_month -- Table expression created in step 2
)

-- Step 4: Aggregate results by frequency category to get user counts and average transactions per category
SELECT 
    frequency_category,  -- Frequency category label
    COUNT(*) AS customer_count,  -- Number of users in each frequency category
    ROUND(AVG(avg_transactions_per_month), 2) AS avg_transactions_per_month  -- Average transactions per month per category
FROM categorized_users -- Table expression created in step 3
GROUP BY frequency_category
ORDER BY 
    -- Order results so that High Frequency users come first, then Medium, then Low
    CASE frequency_category
        WHEN 'High Frequency' THEN 1
        WHEN 'Medium Frequency' THEN 2
        ELSE 3
    END;
