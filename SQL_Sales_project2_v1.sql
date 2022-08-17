-- Using Row_number to find and filter the first order date 
-- Using window function to find total quantity of items ordered by each Customer

WITH Min_Order_Cte
AS
(
SELECT CUSTOMERNAME Customer_Name
		, ROUND(PRICEEACH,2) Item_Price
		, ROUND(SALES, 2) Total_Sales
		, QUANTITYORDERED Quantity_Ordered
		, MIN(ORDERDATE) OVER (PARTITION BY CUSTOMERNAME) AS Min_Order_Date
		, SUM(QUANTITYORDERED) OVER(PARTITION BY CUSTOMERNAME) AS Total_Order_by_Customer
		, ROW_NUMBER() OVER(PARTITION BY CUSTOMERNAME ORDER BY ORDERDATE ASC) AS Row_Num
FROM [dbo].[sales]
),
Acquisition_cte 
AS
(
SELECT Customer_Name
		, Item_Price
		, Total_Sales
		, Quantity_Ordered
		, CONVERT(date, Min_Order_Date) Acquisition_Date
		, Total_Order_by_Customer
FROM Min_Order_Cte
WHERE Row_Num = 1
)
--SELECT * 
--FROM Acquisition_cte

--Finding the total number of new customers by date 
SELECT Acquisition_Date
	   , COUNT(*) as New_Customers
FROM Acquisition_cte 
GROUP BY Acquisition_Date
ORDER BY COUNT(*) DESC

-- Alternative way to find Customer first order date using GROUP BY
SELECT CUSTOMERNAME Customer_Name
	   , MIN(ORDERDATE) First_Order_Date
FROM [dbo].[sales]
GROUP BY CUSTOMERNAME
ORDER BY MIN(ORDERDATE) 

-- Using CASE to label New Buyers and Repeat Buyers
WITH Min_Order_Cte
AS
(
SELECT CUSTOMERNAME Customer_Name
		, ROUND(PRICEEACH,2) Item_Price
		, ROUND(SALES, 2) Total_Sales
		, QUANTITYORDERED Quantity_Ordered
		, MIN(ORDERDATE) OVER (PARTITION BY CUSTOMERNAME) AS Min_Order_Date
		, SUM(QUANTITYORDERED) OVER(PARTITION BY CUSTOMERNAME) AS Total_Order_by_Customer
		, ROW_NUMBER() OVER(PARTITION BY CUSTOMERNAME ORDER BY ORDERDATE ASC) AS Row_Num
FROM [dbo].[sales]
)
SELECT *,
CASE 
	WHEN Row_Num = 1 THEN 'New Buyer'
	ELSE 'Repeat Buyer'
	END AS Customer_Type
FROM Min_Order_Cte

-- Comparison between 1st Orders and 2nd Orders for Customers

WITH Min_Order_Cte
AS
(
SELECT CUSTOMERNAME Customer_Name
		, ROUND(PRICEEACH,2) Item_Price
		, ROUND(SALES, 2) Total_Sales
		, QUANTITYORDERED Quantity_Ordered
		, MIN(ORDERDATE) OVER (PARTITION BY CUSTOMERNAME) AS Min_Order_Date
		, SUM(QUANTITYORDERED) OVER(PARTITION BY CUSTOMERNAME) AS Total_Order_by_Customer
		, ROW_NUMBER() OVER(PARTITION BY CUSTOMERNAME ORDER BY ORDERDATE ASC) AS Row_Num
FROM [dbo].[sales]
),
Acquisition_cte 
AS
(
SELECT Customer_Name
		, Item_Price
		, Total_Sales
		, Quantity_Ordered
		, CONVERT(date, Min_Order_Date) Acquisition_Date
		, Total_Order_by_Customer
		, Row_Num Order_Number
FROM Min_Order_Cte
WHERE Row_Num <=2 
)
-- Calculating if more money is spent on 1st or 2nd Orders - Answer: More is spent on 2nd Orders
-- To calculate the difference between the two: could use Grand_Total - LAG(Grand_Total)
/*If the Total Customers is different from 1st and 2nd Orders - calculate an Average instead e.g
SUM(Total_Sales) / COUNT(*) GROUP BY Order_Number */ 

SELECT Order_Number
		, SUM(Total_Sales) Grand_Total
		, COUNT(*) Total_Customers 
FROM Acquisition_cte
GROUP BY Order_Number 
ORDER BY SUM(Total_Sales) DESC

-- creating a window function for prior order date 
-- LAG(Acquisition_Date) OVER(PARTITION BY Customer_Name ORDER BY Acquisition_Date) AS Prior_Order_Date

-- creating a window function for time since last order
-- Acquisition_Date - LAG(Acquisition_Date) OVER(PARTITION BY Customer_Name ORDER BY Acquisition_Date) AS Time_Between_Last_Order

/* Could calculate time between orders as minutes and rank by buyers with largest gap between orders. This could be useful
for targeting customers you want to make more frequent orders. 
(Could also segment using a CASE statements, followed by COUNT(*) to see total for each catergory.

DATEPART(minute, Min_Order_Date) function would need to be used on Min_Order_Date 
or example -

FLOOR(EXTRACT epoch FROM Min_Order_Date - LAG(Min_Order_Date) 
			OVER(PARTITION BY Customer_Name ORDER BY Min_Order_Date)/60) AS Mins_Since_Prior_Order 

epoch puts the date into seconds and needs to divided by 60 for total minutes */ 



