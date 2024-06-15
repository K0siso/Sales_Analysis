-- 0. View Data
Select *
From sales_info;

-- 1. I WANT TO CREATE A COPY OF THE MAIN TABLE

-- 1.1 Copying the columns
Create Table sales_copy
Like sales_info;

-- 1.2 Copying the rows
Insert sales_copy
Select *
From sales_info;

												-- DATA CLEANING!

-- 2. I CHECK FOR DUPLICATE ROWS

-- 2.1 Creating a CTE to identify unique rows
With numbered_rows as (
	Select *,
	Row_number() Over(Partition by `Date`, Customer_Age, Age_Group, Customer_Gender, Country, State, 
    Product_Category, Sub_Category, Product, Order_Quantity, Cost) as row_num
    From sales_copy)
Select *
From numbered_rows
Where row_num > 1;

-- 2.2 I created another table with the new column, "row_num", to be able to perform delete
CREATE TABLE `sales_copy2` (
  `Date` text,
  `Day` int DEFAULT NULL,
  `Month` text,
  `Year` int DEFAULT NULL,
  `Customer_Age` int DEFAULT NULL,
  `Age_Group` text,
  `Customer_Gender` text,
  `Country` text,
  `State` text,
  `Product_Category` text,
  `Sub_Category` text,
  `Product` text,
  `Order_Quantity` int DEFAULT NULL,
  `Unit_Cost` int DEFAULT NULL,
  `Unit_Price` int DEFAULT NULL,
  `Profit` int DEFAULT NULL,
  `Cost` int DEFAULT NULL,
  `Revenue` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 2.3 Copy the data into my new table
Insert Into sales_copy2
Select *,
	Row_number() Over(partition by `Date`, Customer_Age, Age_Group, Customer_Gender, Country, State, 
    Product_Category, Sub_Category, Product, Order_Quantity, Cost) as row_num
From sales_copy;

-- 2.4 I view and delete the repeated rows. Total = 1000
Select count(*)
From sales_copy2
Where row_num > 1;

Delete
From sales_copy2
Where row_num > 1;

-- 3. STANDARDIZE DATA

-- 3.1 Changing the date format from 'text' to 'date'
Alter Table sales_copy2
Modify Column `Date` Date;

-- 3.2 Drop the 'row_num' column
Alter Table sales_copy2
Drop Column row_num;

											-- DATA EXPLORATION!
-- CONTENTS:
	-- 1. SALES TRENDS OVER TIME
    -- 2. CUSTOMER DEMOGRAPHICS AND SALES
    -- 3. GEOGRAPHICAL SALES ANALYSIS
    -- 4. PRODUCT PERFORMANCE
    -- 5. COST ANALYSIS

-- 1 SALES TREND OVER TIME

	-- 1.1 What are the monthly and yearly trends in sales volume?

		-- Monthly sales volume across years
Select Year, Month, Sum(Order_Quantity) Total_sales_volume
From sales_copy2
Group By Year, Month
Order By Year,
	FIELD(Month, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');
    
		-- Yearly sales volume
Select Year, Sum(Order_Quantity)
From sales_copy2
Group By Year;

	-- 1.2 How do sales fluctuate seasonally across different years?
Select Month, Avg(Total_sales_volume) as Average_monthly_sales
From (
	Select Year, Month, Sum(Order_Quantity) as Total_sales_volume
	From sales_copy2
	Group By Year, Month) Monthly_sales
Group By Month;

	-- 1.3 Are there any noticeable trends in customer demographics (age, gender) over time?

		-- Sales Volume by Customer Age Group and Year
Select Year, Age_Group, Sum(Order_Quantity) as Total_sales_volume
From sales_copy2
Group By Year, Age_Group
Order By Year, Total_sales_volume Desc;

		-- Sales Volume by Customer Gender and Year
Select Year, Customer_Gender, Sum(Order_Quantity) as Total_sales_volume
From sales_copy2
Group By Year, Customer_Gender
Order By Year, Total_sales_volume Desc;

		-- Combine Demographic Trends
Select Year, Age_Group, Customer_Gender, Sum(Order_Quantity) as Total_sales_volume
From sales_copy2
Group By Year, Customer_Gender, Age_Group
Order By Year, Total_sales_volume Desc;


-- 2. CUSTOMER DEMOGRAPHICS AND SALES

	-- 2.1 Which age groups generate the highest sales revenue?
    
		-- Total Revenue by age group
Select Age_Group, Sum(Revenue) as Total_Revenue
From sales_copy2
Group By Age_Group
Order By Total_Revenue Desc;

		-- Average Revenue by age group
Select Age_Group, Avg(Revenue) as Average_Revenue
From sales_copy2
Group By Age_Group
Order By Average_Revenue Desc;

    -- 2.2 How do sales differ between male and female customers?
    
		-- Total sales volume by Gender
Select Customer_Gender, Sum(Order_Quantity) as Total_sales_volume
From sales_copy2
Group By Customer_Gender;
		
        -- Average Order quantity by Gender
Select Customer_Gender, Avg(Order_Quantity) as Average_sales_volume
From sales_copy2
Group By Customer_Gender;

		-- Total revenue by Gender
Select Customer_Gender, Sum(Revenue) as Total_revenue
From sales_copy2
Group By Customer_Gender;

    -- 2.3 Which age groups and genders have the highest profit margins?
    
		-- Total profit by age group and Gender
Select Age_Group, Customer_Gender, Sum(Profit) as Total_profit
From sales_copy2
Group By Age_Group, Customer_Gender
Order By 3 Desc;

		-- Average profit margin by age group and gender
Select Age_Group, Customer_Gender, Avg(Profit/Revenue)*100 as Average_profit_margin
From sales_copy2
Group By Age_Group, Customer_Gender
Order By 3 Desc;


-- 3. GEOGRAPHICAL SALES ANALYSIS

	-- 3.1 Which countries and states contribute most to the total sales?
		
        -- Total sales volume by Country
Select Country, Sum(Order_Quantity) Total_sales_volume
From sales_copy2
Group By Country
Order By 2 Desc;

        -- Total revenue by Country
Select Country, Sum(Revenue) Total_revenue
From sales_copy2
Group By Country
Order By 2 Desc;

        -- Total sales volume by State
Select State, Sum(Order_Quantity) Total_sales_volume
From sales_copy2
Group By State
Order By 2 Desc;

        -- Total revenue by State
Select State, Sum(Revenue) Total_revenue
From sales_copy2
Group By State
Order By 2 Desc;

	-- 3.2 How do sales in different regions change over time?

		-- Monthly Sales volume by Country and Year
Select Country, Year, Month, Sum(Order_Quantity) Total_sales_volume
From sales_copy2
Group By Month, Year, Country;

		-- Monthly revenue by Country and Year
Select Country, Year, Month, Sum(Revenue) Total_Revenue
From sales_copy2
Group By Month, Year, Country;

	-- 3.3 Are there any regions with consistent growth or decline in sales?

		-- Yearly Revenue Growth by Country
Select Year, Country, Total_revenue,
	Lag(Total_revenue, 1, 0) Over(Partition By Country Order By Year) as Previous_year_revenue,
    (Total_revenue - Lag(Total_revenue) Over(Partition By Country Order By Year))/Lag(Total_revenue) Over(Partition By Country Order By Year)*100 as Yearly_growth_percentage
From
(Select Year, Country, Sum(Revenue) as Total_revenue
From sales_copy2
Group By Year, Country) as Country_yearly_revenue;

		-- Years of Growth and Decline
Select Country,
	Count(Case When Yearly_growth_percentage > 0 Then 1 End) as Years_of_growth,
    Count(Case When Yearly_growth_percentage < 0 Then 1 End) as Years_of_decline
From
(Select Year, Country, Total_revenue,
	Lag(Total_revenue) Over(Partition By Country Order By Year) as Previous_yer_revenue,
    (Total_revenue - Lag(Total_revenue) Over(Partition By Country Order By Year))/Lag(Total_revenue) Over(Partition By Country Order By Year)*100 as Yearly_growth_percentage
From
(Select Year, Country, Sum(Revenue) as Total_revenue
From sales_copy2
Group By Year, Country) as Country_yearly_revenue) as Country_revenue_growth
Group By Country;


-- 4. PRODUCT PERFORMANCE
	
    -- 4.1 Which products generate the highest revenue?
Select Product, Sum(Revenue) as Total_revenue
From sales_copy2
Group By Product
Order By 2 Desc;

	-- 4.2 What are the profit margins of different products?
Select Product, Sum(Profit) as Total_profit, Sum(Revenue) as Total_revenue, Sum(Profit)/Sum(Revenue)*100 as Profit_margin_percentage
From sales_copy2
Group By Product
Order By 4 Desc;

	-- 4.3 How do sales of different product categories compare?

		-- Total Sales Volume by Product Category
Select Product_Category, Sum(Order_Quantity) Total_sales_volume
From sales_copy2
Group By Product_Category;

		--  Total Revenue by product Category
Select Product_Category, Sum(Revenue) Total_revenue
From sales_copy2
Group By Product_Category;

		-- Average Order Quantity by Product Category
Select Product_Category, Avg(Order_Quantity) Average_order_quantity
From sales_copy2
Group By Product_Category;

	-- 4.4 What is the sales trend of each product over time?
    
		-- Monthly sales volume by product
Select Year, Month, Product, Sum(Order_Quantity) Total_sales_volume
From sales_copy2
Group By Year, Month, Product;

		-- Monthly revenue by Product
Select Year, Month, Product, Sum(Revenue) as Total_revenue
From sales_copy2
Group By Year, Month, Product;

	-- 4.5 Are there any products with consistent growth or decline in sales?

		-- Yearly Revenue Growth by Product
Select Year, Product, Total_revenue,
	Lag(Total_revenue, 1, 0) Over(Partition By Product Order By Year) as Previous_year_revenue,
    (Total_revenue - Lag(Total_revenue) Over(Partition By Product Order By Year))/Lag(Total_revenue) Over(Partition By Product Order By Year)*100 Yearly_growth_percentage
From
	(Select Year, Product, Sum(Revenue) as Total_revenue
    From sales_copy2
    Group By Year, Product) as Product_yearly_revenue
Group By Year, Product;

		-- Years of Growth and Decline
Select Product,
	Count(Case When Yearly_growth_percentage > 0 Then 1 End) Years_of_growth,
    Count(Case When Yearly_growth_percentage < 0 Then 1 End) Years_of_decline
From
(Select Year, Product, Total_revenue,
	Lag(Total_revenue) Over(partition by Product Order By Year),
    (Total_revenue - Lag(Total_revenue) Over(partition by Product Order By Year))/Lag(Total_revenue) Over(partition by Product Order By Year)*100 as Yearly_growth_percentage
From
(Select Year, Product, Sum(Revenue) as Total_revenue
From sales_copy2
Group By Year, Product) as Product_yearly_revenue) as Product_revenue_growth
Group By Product;

-- 5. COST ANALYSIS

	-- 5.1 What are the trends in cost over the years?
Select Year, Sum(Cost) as Total_cost
From sales_copy2
Group By Year;

		-- Average cost per year
Select Year, Avg(Cost) as Average_cost
From sales_copy2
Group By Year;

	-- 5.2 How do costs vary by product and region?
Select Product, Country, State, Sum(Cost) Total_cost
From sales_copy2
Group By Product, Country, State
Order By 1,2,3;

		-- Average cost per year
Select Product, Country, State, Avg(Cost) Average_cost
From sales_copy2
Group By Product, Country, State
Order By 1,2,3;

	-- 5.3 Is there a correlation between cost and customer demographics?

		-- Average Cost by Age Group and Gender
Select Age_Group, Customer_Gender, Avg(Cost) as Average_cost
From sales_copy2
Group By Age_Group, Customer_Gender;

        -- Average Cost by Country and Age Group
Select Country, Age_Group, Avg(Cost) as Average_cost
From sales_copy2
Group By Country, Age_Group;

        -- Average Cost by Country and Gender
Select Country, Customer_Gender, Avg(Cost) as Average_cost
From sales_copy2
Group By Country, Customer_Gender;


-- END