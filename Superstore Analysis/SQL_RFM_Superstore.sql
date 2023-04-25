

  //*Let`s group customers using RFM Analysis
  The “RFM” in RFM analysis stands for recency, frequency and monetary value. RFM analysis is a way to 
  use data based on existing customer behavior to predict how a new customer is likely to act in the future. 
  An RFM model is built using  three key factors: how recently a customer has transacted with a brand, 
  how frequently they’ve engaged with a brand how much money they’ve spent on a brand’s products and services *//


  DROP TABLE IF EXISTS #rfm 
  ;with rfm as
  (
	  SELECT Customer_name,
		  round(sum(sales),2) as monetary_value,
		  round(avg(sales),2) as average_monetary_value,
		  count(distinct order_id) as frequency,
		  max(order_date) as last_order_date,
		  (SELECT max(order_date) from [Superstore_more].[dbo].[SuperStoreOrders]) as last_customer_order_date,
		  DATEDIFF(DD,max(order_date),(SELECT max(order_date) from [Superstore_more].[dbo].[SuperStoreOrders])) as recency -- How many days have passed since the last order for a customer compared to the date of the company's last order
	  FROM [Superstore_more].[dbo].[SuperStoreOrders]
	  GROUP BY Customer_Name 
 ),
 rfm_rank as 
 (

	 SELECT *,
	    NTILE(4) OVER (order by recency DESC) rfm_recency,
	    NTILE(4) OVER (order by monetary_value) rfm_monetary,
		NTILE(4) OVER (order by frequency) rfm_frequency
	FROM rfm
)

SELECT *, rfm_monetary+rfm_frequency+rfm_recency as rfm_sum,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) as rfm_sum_string
into #rfm -- Lets`s create temp table so we don't have to run this whole query everytime
FROM rfm_rank 


-- Let`s group customers and finish our analysis
select customer_name,
rfm_recency,
rfm_frequency,
rfm_monetary,
rfm_sum_string,
	CASE
		WHEN rfm_sum_string in (111,112,113,114,121,122,123,124,131,132,141,142,211,212,213,214,221,222,231,232,241,242,223) then 'lost customer' -- lost customers
		WHEN rfm_sum_string in (133,134,143,144,233,234,243,224,244) then 'big customer, cannot lose' -- big customers that we can't lose
		WHEN rfm_sum_string in (311,411,412,413,414,312,313,314) then 'new customer'
		WHEN rfm_sum_string in (321,322,422,323,324,331,332,333,334,341,342,343,344,422,432,431,441,423,421) then 'active customer'
		When rfm_sum_string in (444,443,433,434,424,442) then 'loyal customer'
		end rfm_segment
from #rfm


  
