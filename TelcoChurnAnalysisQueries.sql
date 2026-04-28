-- Creating a View --
CREATE VIEW telecom_churn_base AS
SELECT
    -- Core Dimensions
    CustomerID,Gender,Age,Under30,SeniorCitizen,Married,Dependents,NumberofDependents,Country,State,City,Contract,
    InternetType,PaymentMethod,CustomerStatus,ChurnCategory,ChurnReason,PremiumTechSupport,OnlineSecurity,OnlineBackup,
    -- Raw Metrics
    TenureinMonths,MonthlyCharge,SatisfactionScore,CLTV,TotalRevenue,
    -- Tenure Segments
    CASE
        WHEN TenureinMonths <= 6 THEN '1-6 months'
        WHEN TenureinMonths <= 12 THEN '7-12 months'
        WHEN TenureinMonths <= 36 THEN '1-3 years'
        ELSE '3+ years'
    END AS Tenure_grp,
    -- Monthly Charge Segments
    CASE
        WHEN MonthlyCharge <= 50 THEN 'Low'
        WHEN MonthlyCharge <= 75 THEN 'Medium'
        ELSE 'High'
    END AS MonthlyCharges_grp,
    -- Satisfaction Segments
    CASE
        WHEN SatisfactionScore < 3 THEN 'Low Score'
        WHEN SatisfactionScore = 3 THEN 'Neutral Score'
        ELSE 'High Score'
    END AS satisfaction_score_grp,
    -- Add-ons Count
    (
        CASE WHEN OnlineSecurity = 'Yes' THEN 1 ELSE 0 END +
        CASE WHEN OnlineBackup = 'Yes' THEN 1 ELSE 0 END +
        CASE WHEN PremiumTechSupport = 'Yes' THEN 1 ELSE 0 END
    ) AS add_ons_count,
    -- Customer Flags
    CASE
        WHEN CustomerStatus IN ('Stayed','Churned') THEN 1
        ELSE 0
    END AS total_flag,
    CASE
        WHEN CustomerStatus = 'Churned' THEN 1
        ELSE 0
    END AS churn_flag,
    -- Revenue Metrics
    CASE
        WHEN CustomerStatus = 'Churned' THEN CLTV
        ELSE 0
    END AS churned_cltv,
    CASE
        WHEN CustomerStatus = 'Churned' THEN TotalRevenue
        ELSE 0
    END AS realized_revenue,
    CASE
        WHEN CustomerStatus = 'Churned'
         AND CLTV > TotalRevenue
        THEN CLTV - TotalRevenue
        ELSE 0
    END AS potential_revenue_loss
FROM telecom_customer_churn;

-- Overall Churn Rate --
select
SUM(total_flag) as total_customers,
Sum(churn_flag) as churned,
round(SUM(churn_flag)*100/
SUM(total_flag),2) as churn_rate_pct
from telecom_churn_base;

-- By Demographics --
SELECT 
Gender,
SUM(total_flag) as total_customers,
Sum(churn_flag) as churned,
round(SUM(churn_flag)*100/
SUM(total_flag),2) as churn_rate_pct
from telecom_churn_base
Group by Gender;

SELECT 
SeniorCitizen,
SUM(total_flag) as total_customers,
Sum(churn_flag) as churned,
round(SUM(churn_flag)*100/
SUM(total_flag),2) as churn_rate_pct
from telecom_churn_base
Group by SeniorCitizen;

SELECT 
Married,
SUM(total_flag) as total_customers,
Sum(churn_flag) as churned,
round(SUM(churn_flag)*100/
SUM(total_flag),2) as churn_rate_pct
from telecom_churn_base
Group by Married;

SELECT 
Dependents,
SUM(total_flag) as total_customers,
Sum(churn_flag) as churned,
round(SUM(churn_flag)*100/
SUM(total_flag),2) as churn_rate_pct
from telecom_churn_base
Group by Dependents;

SELECT 
City,
SUM(total_flag) as total_customers,
Sum(churn_flag) as churned,
round(SUM(churn_flag)*100/
SUM(total_flag),2) as churn_rate_pct
from telecom_churn_base
Group by City
order by churned desc,churn_rate_pct desc;

-- Contract x Tenure Segment --
SELECT
    Contract,
    Tenure_grp,
    SUM(total_flag) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND(100.0 * SUM(churn_flag) / NULLIF(SUM(total_flag),0),2) AS churn_rate,
    SUM(churned_cltv) AS churned_cltv,
    SUM(realized_revenue) AS realized_revenue,
    SUM(potential_revenue_loss) AS potential_revenue_loss,
     ROUND(
        100.0 * SUM(potential_revenue_loss) /
        NULLIF(SUM(churned_cltv),0),2
    ) AS potential_revenue_loss_pct
FROM telecom_churn_base
GROUP BY Contract, Tenure_grp
ORDER BY Contract, Tenure_grp;

-- Contract Type × Monthly Charges --
SELECT
    Contract,
    Tenure_grp,
    MonthlyCharges_grp,
    SUM(total_flag) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND(100.0 * SUM(churn_flag) / NULLIF(SUM(total_flag),0),2) AS churn_rate,
    SUM(churned_cltv) AS churned_cltv,
    SUM(realized_revenue) AS realized_revenue,
    SUM(potential_revenue_loss) AS potential_revenue_loss,
     ROUND(
        100.0 * SUM(potential_revenue_loss) /
        NULLIF(SUM(churned_cltv),0),2
    ) AS potential_revenue_loss_pct
FROM telecom_churn_base
GROUP BY Contract, Tenure_grp,MonthlyCharges_grp
ORDER BY Contract, Tenure_grp,MonthlyCharges_grp;

-- Contract x Tenure x Add ons Adoption Level --
SELECT
    Contract,
    Tenure_grp,
    add_ons_count,
    SUM(total_flag) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND(100.0 * SUM(churn_flag) / NULLIF(SUM(total_flag),0),2) AS churn_rate,
    SUM(churned_cltv) AS churned_cltv,
    SUM(realized_revenue) AS realized_revenue,
    SUM(potential_revenue_loss) AS potential_revenue_loss,
     ROUND(
        100.0 * SUM(potential_revenue_loss) /
        NULLIF(SUM(churned_cltv),0),2
    ) AS potential_revenue_loss_pct
FROM telecom_churn_base
GROUP BY Contract, Tenure_grp,add_ons_count
ORDER BY Contract, Tenure_grp,add_ons_count;

-- Contract x Tenure x Premium Tech Support --
SELECT
    Contract,
    Tenure_grp,
    PremiumTechSupport,
    SUM(total_flag) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND(100.0 * SUM(churn_flag) / NULLIF(SUM(total_flag),0),2) AS churn_rate,
    SUM(churned_cltv) AS churned_cltv,
    SUM(realized_revenue) AS realized_revenue,
    SUM(potential_revenue_loss) AS potential_revenue_loss,
     ROUND(
        100.0 * SUM(potential_revenue_loss) /
        NULLIF(SUM(churned_cltv),0),2
    ) AS potential_revenue_loss_pct
FROM telecom_churn_base
GROUP BY Contract, Tenure_grp,PremiumTechSupport
ORDER BY Contract, Tenure_grp,PremiumTechSupport;

-- Contract x Tenure x Internet Type --
SELECT
    Contract,
    Tenure_grp,
    InternetType,
    SUM(total_flag) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND(100.0 * SUM(churn_flag) / NULLIF(SUM(total_flag),0),2) AS churn_rate,
    SUM(churned_cltv) AS churned_cltv,
    SUM(realized_revenue) AS realized_revenue,
    SUM(potential_revenue_loss) AS potential_revenue_loss,
     ROUND(
        100.0 * SUM(potential_revenue_loss) /
        NULLIF(SUM(churned_cltv),0),2
    ) AS potential_revenue_loss_pct
FROM telecom_churn_base
GROUP BY Contract, Tenure_grp,InternetType
ORDER BY Contract, Tenure_grp,InternetType;

-- Contract x Tenure x PaymnetMethod --
SELECT
    Contract,
    Tenure_grp,
	PaymentMethod,
    SUM(total_flag) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND(100.0 * SUM(churn_flag) / NULLIF(SUM(total_flag),0),2) AS churn_rate,
    SUM(churned_cltv) AS churned_cltv,
    SUM(realized_revenue) AS realized_revenue,
    SUM(potential_revenue_loss) AS potential_revenue_loss,
     ROUND(
        100.0 * SUM(potential_revenue_loss) /
        NULLIF(SUM(churned_cltv),0),2
    ) AS potential_revenue_loss_pct
FROM telecom_churn_base
GROUP BY Contract, Tenure_grp,PaymentMethod
ORDER BY Contract, Tenure_grp,PaymentMethod;

-- Contract x Tenure x SatisfactionScore --
SELECT
    Contract,
    Tenure_grp,
	satisfaction_score_grp,
    SUM(total_flag) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND(100.0 * SUM(churn_flag) / NULLIF(SUM(total_flag),0),2) AS churn_rate,
    SUM(churned_cltv) AS churned_cltv,
    SUM(realized_revenue) AS realized_revenue,
    SUM(potential_revenue_loss) AS potential_revenue_loss,
     ROUND(
        100.0 * SUM(potential_revenue_loss) /
        NULLIF(SUM(churned_cltv),0),2
    ) AS potential_revenue_loss_pct
FROM telecom_churn_base
GROUP BY Contract, Tenure_grp,satisfaction_score_grp
ORDER BY Contract, Tenure_grp,satisfaction_score_grp;

-- Contract x Churn Category x Churn Reason  --
SELECT 
    Contract,
    ChurnCategory,
    ChurnReason
    ,count(*) AS churned
FROM telecom_customer_churn
group by Contract,ChurnCategory,ChurnReason
order by churned desc;