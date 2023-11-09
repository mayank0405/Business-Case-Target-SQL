# Business Case: Target SQL

## Context:

Target is a globally renowned brand and a prominent retailer in the United States. Target makes itself a preferred shopping destination by offering outstanding value, inspiration, innovation and an exceptional guest experience that no other retailer can deliver.

This particular business case focuses on the operations of Target in Brazil and provides insightful information about 100,000 orders placed between 2016 and 2018. The dataset offers a comprehensive view of various dimensions including the order status, price, payment and freight performance, customer location, product attributes, and customer reviews.

By analyzing this extensive dataset, it becomes possible to gain valuable insights into Target's operations in Brazil. The information can shed light on various aspects of the business, such as order processing, pricing strategies, payment and shipping efficiency, customer demographics, product characteristics, and customer satisfaction levels.

The data is available in 8 csv files:

1. customers.csv
2. sellers.csv
3. order_items.csv
4. geolocation.csv
5. payments.csv
6. reviews.csv
7. orders.csv
8. products.csv


**Database Schema:**

The following is the database schema of the tables used in the business case - 

![](https://lh7-us.googleusercontent.com/3UKzkf15dQE6o029g7-TfPyCwPrkig9oavCGn1--3XaupgPvSBnztX9LarXKjxgNuHPIa2kMSiNZb3jjuSct4FA-cOfE5GalEj1U6ieXeylSF4hr4WkFST2hxl2iP10ThTla9S1cpGZQ7aPUSSSCoj8)

**_Unfortunately, we cannot give the dataset for this project as it is confidential._**


## Problem Statement- 

Assuming you are a data analyst/ scientist at Target, you have been assigned the task of analyzing the given dataset to extract valuable insights and provide actionable recommendations.

### :pushpin: Import the dataset and do usual exploratory analysis steps like checking the structure & characteristics of the dataset:

#### :round_pushpin: Data type of all columns in the "customers" table.

````sql
SELECT table_name, column_name, data_type
FROM target_business_case.INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'customers'
````

**_Results_**

| table_name | column_name              | data_type |
|------------|--------------------------|-----------|
| customers  | customer_id              | STRING    |
| customers  | customer_unique_id       | STRING    |
| customers  | customer_zip_code_prefix | INT64     |
| customers  | customer_city            | STRING    |
| customers  | customer_state           | STRING    |

:exclamation: **Insight -** In the bigquery, we use **INFORMATION_SCHEMA** to find out the required information of a table. Here, just like a SQL query, we select columns rows from the **DATASET(in this case target_business_case)** and use **INFORMATION_SCHEMA.COLUMNS** where table_name is the required table, in this case **_customers_**.


#### :round_pushpin: Get the time range between which the orders were placed. 

````sql
SELECT 
    MIN(EXTRACT(DATE FROM order_purchase_timestamp)) AS first_date,
    MAX(EXTRACT(DATE FROM order_purchase_timestamp)) AS last_date
FROM `target_business_case.orders`;
````

**_Results_**

| first_date | last_date  |
|------------|------------|
| 2016-09-04 | 2018-10-17 |

:exclamation: **Insight -** From the above query, we find the first date when order was placed using **min()** function because min returns the lowest(in this case, earliest) date and **max()** function because it returns maximum(latest) date. So, these two dates give us the range between which all the orders were placed.


#### :round_pushpin: Count the Cities & States of customers who ordered during the given period.

````sql
SELECT
    COUNT(DISTINCT c.customer_city) AS city_count,
    COUNT(DISTINCT c.customer_state) AS state_count
FROM
    `target_business_case.customers` c
INNER JOIN
    `target_business_case.orders` o ON c.customer_id = o.customer_id;
````

**_Results_**

| city_count | state_count |
|------------|-------------|
| 4119       | 27          |

:exclamation: **Insight -** From the above query we get the count of total numbers of distinct cities and states from the customer_table who ordered within the given period in the orders table. That is why we have used the inner join with the orders table. This gives us the number of cities and states from which customers ordered.


### :pushpin: In-depth exploration:

#### :round_pushpin: Is there a growing trend in the no. of orders placed over the past years?

````sql
SELECT
    EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
    COUNT(order_id) AS count_orders
FROM
    `target_business_case.orders`
GROUP BY
    1
ORDER BY
    1 ASC;
````

**_Results_** 

| year | count_orders |
|------|--------------|
| 2016 | 329          |
| 2017 | 45101        |
| 2018 | 54011        |

:exclamation: **Insight -** We were asked to find out the trend of the no. of orders placed over the years. So, we use the orders table for it. We first find the years and use the aggregate function **count()** to count the number of users in each year using the **group by** function. Then, we order the rows based on the year column in **ascending order**. So, from the table we find out that the number of orders placed each year has gone up so we can say that the **trend has gone up**. However there is one thing to note here and that is that for 2016, we only have records of **September, October and December**. So, we can’t say much about the trend from 2016 to 2017.


#### :round_pushpin: Can we see some kind of monthly seasonality in terms of the no. of orders being placed?

````sql
WITH cte AS (
    SELECT
        EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
        EXTRACT(MONTH FROM order_purchase_timestamp) AS month_num,
        FORMAT_DATE("%B", order_purchase_timestamp) AS month,
        COUNT(order_id) AS count_orders
    FROM
        `target_business_case.orders`
    GROUP BY
        1, 2, 3
    ORDER BY
        1, 2
)

SELECT
    *,
    DENSE_RANK() OVER (PARTITION BY year ORDER BY count_orders) AS ranking
FROM
    cte
ORDER BY
    year, month_num ASC;
````

**_Results_** 

| year | month_num | month     | count_orders | ranking |
|------|-----------|-----------|--------------|---------|
| 2016 | 9         | September | 4            | 2       |
| 2016 | 10        | October   | 324          | 3       |
| 2016 | 12        | December  | 1            | 1       |
| 2017 | 1         | January   | 800          | 1       |
| 2017 | 2         | February  | 1780         | 2       |
| 2017 | 3         | March     | 2682         | 4       |
| 2017 | 4         | April     | 2404         | 3       |
| 2017 | 5         | May       | 3700         | 6       |
| 2017 | 6         | June      | 3245         | 5       |
| 2017 | 7         | July      | 4026         | 7       |
| 2017 | 8         | August    | 4331         | 9       |
| 2017 | 9         | September | 4285         | 8       |
| 2017 | 10        | October   | 4631         | 10      |
| 2017 | 11        | November  | 7544         | 12      |
| 2017 | 12        | December  | 5673         | 11      |
| 2018 | 1         | January   | 7269         | 10      |
| 2018 | 2         | February  | 6728         | 6       |
| 2018 | 3         | March     | 7211         | 9       |
| 2018 | 4         | April     | 6939         | 8       |
| 2018 | 5         | May       | 6873         | 7       |
| 2018 | 6         | June      | 6167         | 3       |
| 2018 | 7         | July      | 6292         | 4       |
| 2018 | 8         | August    | 6512         | 5       |
| 2018 | 9         | September | 16           | 2       |
| 2018 | 10        | October   | 4            | 1       |

:exclamation: **Insight -** In the above query, we have tried to ding out the total number of orders placed each month in every year. Then, we have used the **dense_rank()** function to rank them by the count_orders in increasing order which tells us at what rank each month stands w.r.t the orders. So, if we take the year **2016**, we see that **month 12** has rank one because it had the least number of orders, then **month 9** with 4 orders and then **month 10** with the highest number of orders. But this doesn’t give any monthly seasonality in 2016. In **2017**, we see that more or less the number of orders placed have gone up each month with a minor blip. So, the monthly trend has been positive in 2017. In the case of **2018**, there is no particular trend so we can’t say much about 2018.


#### :round_pushpin: During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)
- 0-6 hrs : Dawn
- 7-12 hrs : Mornings
- 13-18 hrs : Afternoon
- 19-23 hrs : Night

````sql
WITH cte AS (
    SELECT
        CAST(order_purchase_timestamp AS TIME) AS time,
        CASE
            WHEN CAST(order_purchase_timestamp AS TIME) BETWEEN '00:00:00' AND '05:59:59' THEN 'Dawn'
            WHEN CAST(order_purchase_timestamp AS TIME) BETWEEN '06:00:00' AND '11:59:59' THEN 'Mornings'
            WHEN CAST(order_purchase_timestamp AS TIME) BETWEEN '12:00:00' AND '17:59:59' THEN 'Afternoon'
            WHEN CAST(order_purchase_timestamp AS TIME) BETWEEN '18:00:00' AND '23:59:59' THEN 'Night'
        END AS day_time
    FROM
        `target_business_case.orders`
)

SELECT
    c.day_time,
    COUNT(DISTINCT o.order_id) AS number_of_orders
FROM
    cte c
INNER JOIN
    `target_business_case.orders` o
ON
    c.time = CAST(o.order_purchase_timestamp AS TIME)
GROUP BY
    c.day_time;
````

**_Results_**

| day_time  | number_of_orders |
|-----------|------------------|
| Mornings  | 22240            |
| Dawn      | 4740             |
| Afternoon | 38361            |
| Night     | 34100            |

:exclamation: **Insight -** In order to find out the number of orders according to the 4 day times given, first we find out the time of each order from the **order_purchase_timestamp** column. For that we simply use the **cast()** function. Then, we assign each time its period of the day, whether it is dawn, morning, afternoon or night. After that we join this table with the orders table using day_time and then group them by day_time. Next we use the **count()** function to count the number of orders in each period of the day. In case, there is a time that is at the border of the range of time, and falls into multiple categories, we use **distinct**. So, after doing the analysis, we find out that during the ***afternoon***, the maximum number of orders were placed i.e, between ‘13’ to ‘18’ hours.


### :pushpin: Evolution of E-commerce orders in the Brazil Region:

#### :round_pushpin: Get the month on month no. of orders placed in each state.

````sql
SELECT
    state,
    STRING_AGG(month, ' , ') AS months,
    STRING_AGG(CAST(num_orders_placed AS STRING), ' , ') AS orders_placed
FROM (
    SELECT
        c.customer_state AS state,
        FORMAT_DATE('%B', o.order_purchase_timestamp) AS month,
        EXTRACT(MONTH FROM o.order_purchase_timestamp) AS num_month,
        COUNT(o.order_id) AS num_orders_placed
    FROM
        `target_business_case.orders` o
    INNER JOIN
        `target_business_case.customers` c
    ON
        o.customer_id = c.customer_id
    GROUP BY
        1, 2, 3
    ORDER BY
        1, 3
) e
GROUP BY
    1;
````

**_Results_**

| state	months	orders_placed |          |       |       |     |      |      |           |           |              |          |                 |      |      |      |      |      |      |      |      |      |      |       |
|----------------------------|----------|-------|-------|-----|------|------|-----------|-----------|--------------|----------|-----------------|------|------|------|------|------|------|------|------|------|------|-------|
| AC	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"8    | 6    | 4    | 9    | 10   | 7    | 9    | 7    | 5    | 6    | 5    | 5"    |
| AL	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"39   | 39   | 40   | 51   | 46   | 34   | 40   | 34   | 20   | 30   | 26   | 14"   |
| AM	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"12   | 16   | 14   | 19   | 19   | 8    | 23   | 9    | 9    | 3    | 10   | 6"    |
| AP	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"11   | 4    | 8    | 5    | 11   | 4    | 7    | 5    | 2    | 3    | 4    | 4"    |
| BA	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"264  | 273  | 340  | 318  | 368  | 307  | 405  | 323  | 170  | 170  | 250  | 192"  |
| CE	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"99   | 101  | 126  | 143  | 136  | 121  | 140  | 130  | 77   | 74   | 108  | 81"   |
| DF	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"151  | 196  | 207  | 183  | 208  | 220  | 243  | 232  | 97   | 104  | 168  | 131"  |
| ES	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"159  | 186  | 182  | 188  | 228  | 204  | 206  | 200  | 93   | 104  | 170  | 113"  |
| GO	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"164  | 176  | 199  | 177  | 226  | 184  | 192  | 213  | 88   | 117  | 157  | 127"  |
| MA	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"66   | 67   | 77   | 73   | 65   | 59   | 79   | 70   | 42   | 52   | 56   | 41"   |
| MG	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"971  | 1063 | 1237 | 1061 | 1190 | 1080 | 1111 | 1177 | 511  | 600  | 943  | 691"  |
| MS	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"71   | 75   | 79   | 58   | 74   | 76   | 74   | 59   | 33   | 34   | 46   | 36"   |
| MT	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"96   | 84   | 71   | 92   | 104  | 83   | 85   | 78   | 35   | 55   | 74   | 50"   |
| PA	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"82   | 83   | 109  | 107  | 75   | 92   | 96   | 104  | 41   | 58   | 70   | 58"   |
| PB	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"33   | 47   | 55   | 51   | 47   | 51   | 79   | 46   | 29   | 31   | 30   | 37"   |
| PE	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"113  | 146  | 153  | 154  | 174  | 140  | 210  | 170  | 76   | 87   | 126  | 103"  |
| PI	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"55   | 46   | 48   | 50   | 56   | 43   | 52   | 43   | 23   | 25   | 31   | 23"   |
| PR	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"443  | 460  | 504  | 500  | 524  | 478  | 523  | 556  | 183  | 225  | 378  | 271"  |
| RJ	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"990  | 1176 | 1302 | 1172 | 1321 | 1128 | 1288 | 1307 | 612  | 725  | 1048 | 783"  |
| RN	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"51   | 31   | 52   | 42   | 39   | 49   | 56   | 40   | 24   | 27   | 44   | 30"   |
| RO	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"23   | 25   | 29   | 20   | 26   | 22   | 27   | 23   | 16   | 14   | 17   | 11"   |
| RR	"January                | February | March | April | May | June | July | September | October   | November"	"2 | 7        | 8               | 4    | 3    | 8    | 6    | 2    | 4    | 2"   |      |      |      |       |
| RS	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"427  | 473  | 569  | 488  | 559  | 526  | 565  | 599  | 279  | 276  | 422  | 283"  |
| SC	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"345  | 316  | 362  | 351  | 379  | 321  | 356  | 365  | 157  | 189  | 303  | 193"  |
| SE	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"24   | 27   | 43   | 27   | 19   | 37   | 42   | 43   | 16   | 25   | 27   | 20"   |
| SP	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"3351 | 3357 | 4047 | 3967 | 4632 | 4104 | 4381 | 4982 | 1648 | 1908 | 3012 | 2357" |
| TO	"January                | February | March | April | May | June | July | August    | September | October      | November | December"	"19   | 28   | 28   | 33   | 34   | 26   | 23   | 28   | 17   | 13   | 17   | 14"   |


:exclamation: **Insight -** We are asked to find out the number of orders placed in each state and in each month. So, we first find state, month, num_orders placed in the **inner subquery** by using **group by**  on state and month and joining orders and customers table. We also use the extract month in order to order the table by months in the year also. Then, in the *outer subquery* we use the **string_agg** function in order to group all the respective values of months and number of orders placed. The month and orders_placed columns are corresponding to each other. Meaning each value with the same index in the both columns are related to each other. If the 4th value in Month is **April** then the fourth value in orders_placed is the number of orders placed in the month of April.


#### :round_pushpin: How are the customers distributed across all the states ?

````sql
SELECT
    customer_state,
    COUNT(DISTINCT customer_id) AS number_of_customers
FROM
    `target_business_case.customers`
GROUP BY
    1
ORDER BY
    1
LIMIT 10;
````

**_Results_**

| customer_state | number_of_customers |
|----------------|---------------------|
| AC             | 81                  |
| AL             | 413                 |
| AM             | 148                 |
| AP             | 68                  |
| BA             | 3380                |
| CE             | 1336                |
| DF             | 2140                |
| ES             | 2033                |
| GO             | 2020                |
| MA             | 747                 |

:exclamation: **Insight -** The question asks us to find the number of customers in each state. So, we first find the states and use group by. Then, in order to find *unique* number of customers in each state we use count(distinct customer_id). And then we order by customer_state in ascending order. For simplicity, we just find 10 records. This shows us the number of customers distributed across states. We have only shows 10 of them in the result.


### :pushpin: Impact of Economy: Analyze the money movement by e-commerce by looking at order prices, freight and others.

#### :round_pushpin: Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only). You can use the "payment_value" column in the payments table to get the cost of orders.

````sql
WITH cte1 AS (
    SELECT
        month,
        cost,
        LAG(cost) OVER (ORDER BY month) AS next_month_revenue
    FROM (
        SELECT
            FORMAT_DATE('%Y-%m', o.order_purchase_timestamp) AS month,
            SUM(p.payment_value) AS cost
        FROM
            `target_business_case.orders` o
        INNER JOIN
            `target_business_case.payments` p
        ON
            o.order_id = p.order_id
        WHERE
            FORMAT_DATE('%Y-%m', o.order_purchase_timestamp) BETWEEN '2017-01' AND '2017-08'
            OR FORMAT_DATE('%Y-%m', o.order_purchase_timestamp) BETWEEN '2018-01' AND '2018-08'
        GROUP BY
            1
        ORDER BY
            1 ASC
    )
    ORDER BY
        1
)

SELECT
    month,
    ROUND(((next_month_revenue - cost) / cost), 2) * 100 AS percentage
FROM
    cte1;
````

**_Results_**

| month   | percentage          |
|---------|---------------------|
| 2017-01 |                     |
| 2017-02 | -53.0               |
| 2017-03 | -35.0               |
| 2017-04 | 8.0                 |
| 2017-05 | -30.0               |
| 2017-06 | 16.0                |
| 2017-07 | -14.000000000000002 |
| 2017-08 | -12.0               |
| 2018-01 | -40.0               |
| 2018-02 | 12.0                |
| 2018-03 | -14.000000000000002 |
| 2018-04 | -0.0                |
| 2018-05 | 1.0                 |
| 2018-06 | 13.0                |
| 2018-07 | -4.0                |
| 2018-08 | 4.0                 |

:exclamation: **Insight -** We understand from the statement that we want the percentage change month by month. We calculate the total of payment value in 1 month and then subtract the previous month’s total cost from next month’s total cost and then divide it by previous month’s total cost and then multiply by 100, we get a percentage value. We round the value to two decimal places for simplicity. We get the next month’s cost by **lag** function and then in the outer query we do the subtraction. From this, we get to know that in some month, the cost was lesser than the previous month so, we get -ve values for it. But for some months, the cost was more than the previous so we get a +ve value. In the end we order the table by year and month.


#### :round_pushpin: Calculate the Total & Average value of order price for each state.

````sql
SELECT
    customer_state AS state,
    ROUND(SUM(price), 2) AS total_value,
    ROUND(AVG(price), 2) AS average_value
FROM
    `target_business_case.customers` c
JOIN
    `target_business_case.orders` o
ON
    c.customer_id = o.customer_id
JOIN
    `target_business_case.order_items` o_i
ON
    o.order_id = o_i.order_id
GROUP BY
    1
ORDER BY
    1
LIMIT 10;
````

**_Results_**

| state | total_value | average_value |
|-------|-------------|---------------|
| AC    | 15982.95    | 173.73        |
| AL    | 80314.81    | 180.89        |
| AM    | 22356.84    | 135.5         |
| AP    | 13474.3     | 164.32        |
| BA    | 511349.99   | 134.6         |
| CE    | 227254.71   | 153.76        |
| DF    | 302603.94   | 125.77        |
| ES    | 275037.31   | 121.91        |
| GO    | 294591.95   | 126.27        |
| MA    | 119648.22   | 145.2         |

:exclamation: **Insight -** Here, we need to find out the average and total price of orders for each state. States are present in the customer table and price of each order is present in the order_items table. But there is no common column between them in order to do an inner join. But both have a common column with orders table. So, first we do an **inner join** between customers and orders table on **customer_id**. Then we do an **inner join** with the order_items table on the **order_id** column. Now, we can select the order price from the table and then do sum and average as required. Also because it is a Non-aggregated column with aggregated so, we will do **group by state**. Then we do order by state and *limit* 10 to make the table more readable and for simplicity. Lastly we also round the values to 2 decimal values so we can read the values clearly.


#### :round_pushpin: Calculate the Total & Average value of order freight for each state.

````sql
SELECT
    customer_state AS state,
    ROUND(SUM(freight_value), 2) AS total_value,
    ROUND(AVG(freight_value), 2) AS average_value
FROM
    `target_business_case.customers` c
JOIN
    `target_business_case.orders` o
ON
    c.customer_id = o.customer_id
JOIN
    `target_business_case.order_items` o_i
ON
    o.order_id = o_i.order_id
GROUP BY
    1
ORDER BY
    1
LIMIT 10;
````

**_Results_**

| state | total_value | average_value |
|-------|-------------|---------------|
| AC    | 3686.75     | 40.07         |
| AL    | 15914.59    | 35.84         |
| AM    | 5478.89     | 33.21         |
| AP    | 2788.5      | 34.01         |
| BA    | 100156.68   | 26.36         |
| CE    | 48351.59    | 32.71         |
| DF    | 50625.5     | 21.04         |
| ES    | 49764.6     | 22.06         |
| GO    | 53114.98    | 22.77         |
| MA    | 31523.77    | 38.26         |

:exclamation: **Insight -** Here, we need to find out the average and total freight value of orders for each state. States are present in the customer table and freight value is present in the order_items table. But there is no common column between them in order to do an inner join. But both have a common column with orders table. So, first we do an **inner join** between customers and orders table on **customer_id**. Then we do an **inner join** with the order_items table on the **order_id** column. Now, we can select the freight value from the table and then do sum and average as required. Also because it is a Non-aggregated column with aggregated so, we will do **group by state**. Then we do order by state and limit 10 to make the table more readable and for simplicity. Lastly we also round the values to 2 decimal values so we can read the values clearly.


### :pushpin: Analysis based on sales, freight and delivery time. 

#### :round_pushpin: Find the no. of days taken to deliver each order from the order’s purchase date as delivery time.
Also, calculate the difference (in days) between the estimated & actual delivery date of an order.
Do this in a single query.

You can calculate the delivery time and the difference between the estimated & actual delivery date using the given formula:


- time_to_deliver = order_delivered_customer_date - order_purchase_timestamp
- diff_estimated_delivery = order_estimated_delivery_date - order_delivered_customer_date


````sql
SELECT DISTINCT
    order_id,
    DATE_DIFF(order_delivered_customer_date, order_purchase_timestamp, DAY) AS time_to_deliver,
    DATE_DIFF(order_estimated_delivery_date, order_delivered_customer_date, DAY) AS diff_estimated_delivery
FROM `target_business_case.orders`
WHERE DATE_DIFF(order_delivered_customer_date, order_purchase_timestamp, DAY) IS NOT NULL
    AND DATE_DIFF(order_estimated_delivery_date, order_delivered_customer_date, DAY) IS NOT NULL
LIMIT 10;
````

**_Results_**

| order_id                         | time_to_deliver | diff_estimated_delivery |
|----------------------------------|-----------------|-------------------------|
| 770d331c84e5b214bd9dc70a10b829d0 | 7               | 45                      |
| 1950d777989f6a877539f53795b4c3c3 | 30              | -12                     |
| 2c45c33d2f9cb8ff8b1c86cc28c11c30 | 30              | 28                      |
| dabf2b0e35b423f94618bf965fcb7514 | 7               | 44                      |
| 8beb59392e21af5eb9547ae1a9938d06 | 10              | 41                      |
| 65d1e226dfaeb8cdc42f665422522d14 | 35              | 16                      |
| c158e9806f85a33877bdfd4f607b72e7 | 23              | 9                       |
| b60b53ad0bb7dacacf2989fe27ad567a | 12              | -5                      |
| c830f223aae08493ebecb52f29aa48ca | 12              | 12                      |
| a8aa2cd070eeac7e4368cae3d8222e2b | 7               | 1                       |

:exclamation: **Insight -** As given in the question already, in order to calculate the no. of days taken to deliver each order from the order’s purchase date, we use **date_diff()** function to subtract the two days (**order_purchase_timestamp from order_delivered_customer_date**) and the result is the number of difference in days between the two. The same is true for diff_estimated_delivery. The only thing to note here is that for some values, we were getting negative answers. This means that the order was delivered **before** the *estimated delivery date* and in some cases where it is **zero**, it means that order delivery date and estimated delivery date are the **same**. 

#### :round_pushpin: Find out the top 5 states with the highest & lowest average freight value.

````sql
(
    SELECT
        c.customer_state AS state,
        ROUND(AVG(o_i.freight_value), 2) AS average_freight_value, 
        'top 5 states' AS states
    FROM
        `target_business_case.customers` c
    JOIN
        `target_business_case.orders` o
    ON
        c.customer_id = o.customer_id
    JOIN
        `target_business_case.order_items` o_i
    ON
        o.order_id = o_i.order_id
    GROUP BY
        1
    ORDER BY
        2 DESC
    LIMIT 5
)
UNION DISTINCT
(
    SELECT
        c.customer_state AS state,
        ROUND(AVG(o_i.freight_value), 2) AS average_freight_value,
        'bottom 5 states' AS states
    FROM
        `target_business_case.customers` c
    JOIN
        `target_business_case.orders` o
    ON
        c.customer_id = o.customer_id
    JOIN
        `target_business_case.order_items` o_i
    ON
        o.order_id = o_i.order_id
    GROUP BY
        1
    ORDER BY
        2 ASC
    LIMIT 5
);
````

**_Results_**

| state | average_freight_value | states          |
|-------|-----------------------|-----------------|
| RR    | 42.98                 | top 5 states    |
| PB    | 42.72                 | top 5 states    |
| RO    | 41.07                 | top 5 states    |
| AC    | 40.07                 | top 5 states    |
| PI    | 39.15                 | top 5 states    |
| SP    | 15.15                 | bottom 5 states |
| PR    | 20.53                 | bottom 5 states |
| MG    | 20.63                 | bottom 5 states |
| RJ    | 20.96                 | bottom 5 states |
| DF    | 21.04                 | bottom 5 states |

:exclamation: **Insight -** As requested in the question we want top 5 states with the highest and the lowest average delivery time. So, for that first we will find out the states and their average_delivery_time using **avg()**, **datediff()** and group by functions. We have calculated the average delivery time **in days** for each state. Then in the highest top 5 case, we order by average_delivery_time in **descending(DESC)** order and then limit 5 in order to get the top 5 highest average delivery time states. Then in the lowest top 5 case, we order by average_delivery_time in **ascending(ASC)** order and then limit 5 in order to get the top 5 states with the lowest average delivery_time values. 

#### :round_pushpin: Find out the top 5 states with the highest & lowest average delivery time.

````sql
(
    SELECT
        c.customer_state AS state,
        ROUND(AVG(DATE_DIFF(o.order_delivered_customer_date, o.order_purchase_timestamp, DAY)), 2) AS avg_delivery_time_in_days,
        'top 5 states' AS states
    FROM
        `target_business_case.customers` c
    JOIN
        `target_business_case.orders` o
    ON
        c.customer_id = o.customer_id
    GROUP BY
        1
    ORDER BY
        2 DESC
    LIMIT 5
)
UNION DISTINCT
(
    SELECT
        c.customer_state AS state,
        ROUND(AVG(DATE_DIFF(o.order_delivered_customer_date, o.order_purchase_timestamp, DAY)), 2) AS avg_delivery_time_in_days,
        'bottom 5 states' AS states
    FROM
        `target_business_case.customers` c
    JOIN
        `target_business_case.orders` o
    ON
        c.customer_id = o.customer_id
    GROUP BY
        1
    ORDER BY
        2 ASC
    LIMIT 5
);
````

**_Results_** 

| state | avg_delivery_time_in_days | states          |
|-------|---------------------------|-----------------|
| RR    | 28.98                     | top 5 states    |
| AP    | 26.73                     | top 5 states    |
| AM    | 25.99                     | top 5 states    |
| AL    | 24.04                     | top 5 states    |
| PA    | 23.32                     | top 5 states    |
| SP    | 8.3                       | bottom 5 states |
| PR    | 11.53                     | bottom 5 states |
| MG    | 11.54                     | bottom 5 states |
| DF    | 12.51                     | bottom 5 states |
| SC    | 14.48                     | bottom 5 states |

:exclamation: **Insight -** As requested in the question we want top 5 states with the highest and the lowest average delivery time. So, for that first we will find out the states and their average_delivery_time using **avg()**, **datediff()** and **group by** functions. We have calculated the average delivery time in days for each state. Then in the highest top 5 case, we order by average_delivery_time in **descending(DESC)** order and then limit 5 in order to get the top 5 highest average delivery time states. Then in the lowest top 5 case, we order by average_delivery_time in **ascending(ASC)** order and then **limit 5** in order to get the top 5 states with the lowest average delivery_time values.

#### :round_pushpin: Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.You can use the difference between the averages of actual & estimated delivery date to figure out how fast the delivery was for each state.

````sql
SELECT
    c.customer_state,
    ROUND(AVG(DATE_DIFF(o.order_estimated_delivery_date, o.order_delivered_customer_date, DAY))) AS difference
FROM
    `target_business_case.customers` c
INNER JOIN
    `target_business_case.orders` o
ON
    c.customer_id = o.customer_id
GROUP BY
    1
ORDER BY
    2 ASC
LIMIT 5;
````

**_Results_**

| customer_state | difference |
|----------------|------------|
| AL             | 8.0        |
| MA             | 9.0        |
| SE             | 9.0        |
| ES             | 10.0       |
| SP             | 10.0       |

:exclamation: **Insight -** We have to find 5 states where order delivery is fast as compared to estimated date of delivery. The states are in the customer table and the dates are in the orders table. So, first we need to do an inner join between these tables on customer_id. Then, we use the **date_diff()** function to find the difference between **order_estimated_delivery_date** and **order_delivered_customer_date** in number of days. Then we do an **average** over it to find out the difference of each **state**(using group by state). For convenience we round off the difference using the round function. Now, the fastest delivery is where the **_difference _** between estimated delivery date and the actual delivery date is **least**. For eg, for first order, the estimated delivery date is 1st Oct and actual delivery date is 5th Oct then the difference is of 4 days. For another order the estimated delivery date is 1st Oct and actual delivery date is 8th Oct then the difference is of 7 days. So, the one with the lesser difference is faster. So we order by difference **_asc_**. And in order to get top 5 we use **_limit 5_**.


### :pushpin: Analysis based on the payments.

#### :round_pushpin: Find the month on month no. of orders placed using different payment types.

````sql
SELECT
    payment_type,
    STRING_AGG(month, ' , ') AS months,
    STRING_AGG(CAST(num_orders AS STRING), ' , ') AS num_orders
FROM
(
    SELECT
        p.payment_type,
        FORMAT_DATE('%B', o.order_purchase_timestamp) AS month,
        EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month_number,
        COUNT(DISTINCT o.order_id) AS num_orders
    FROM
        `target_business_case.customers` c
    INNER JOIN
        `target_business_case.orders` o
    ON
        c.customer_id = o.customer_id
    INNER JOIN
        `target_business_case.payments` p
    ON
        o.order_id = p.order_id
    GROUP BY
        1, 2, 3
    ORDER BY
        1, 3 ASC
) subquery
GROUP BY
    1;
````

**_Results_**

| payment_type	months	num_orders |               |       |       |     |      |      |        |           |         |          |                 |      |      |      |      |      |      |      |      |      |      |       |
|--------------------------------|---------------|-------|-------|-----|------|------|--------|-----------|---------|----------|-----------------|------|------|------|------|------|------|------|------|------|------|-------|
| UPI	"January                   | February      | March | April | May | June | July | August | September | October | November | December"	"1715 | 1723 | 1942 | 1783 | 2035 | 1807 | 2074 | 2077 | 903  | 1056 | 1509 | 1160" |
| credit_card	"January           | February      | March | April | May | June | July | August | September | October | November | December"	"6093 | 6582 | 7682 | 7276 | 8308 | 7248 | 7810 | 8235 | 3277 | 3763 | 5867 | 4364" |
| debit_card	"January            | February      | March | April | May | June | July | August | September | October | November | December"	"118  | 82   | 109  | 124  | 81   | 208  | 264  | 311  | 43   | 54   | 70   | 64"   |
| not_defined	"August            | September"	"2 | 1"    |       |     |      |      |        |           |         |          |                 |      |      |      |      |      |      |      |      |      |      |       |
| voucher	"January               | February      | March | April | May | June | July | August | September | October | November | December"	"337  | 288  | 395  | 353  | 374  | 373  | 417  | 430  | 189  | 223  | 267  | 220"  |


:exclamation: **Insight -** Here we are required to calculate no. of orders placed on a monthly basis for each state. So we first join customers, orders and payments table. We have to use the orders table as a link here because there is no direct connection between them in the schema. Then we select payments type, extract month and month number(for ordering) and use count() function for counting the number of orders. Because we use NA columns with A column, we do group by payment type, month and month number. And then order by month number to order them monthly. Then in the outer column we extract payment type, months and number of orders and use string function to group them for each payment type. The values in months and num_orders are corresponding to each other. Meaning they have the same index. If at 4th Position it is April then in the num_orders column the 4th position is the number of orders in the month of April. If April does not exist for that payment type then May comes at 4th position and in the num_orders column 4th position is for May.


#### :round_pushpin: Find the no. of orders placed on the basis of the payment installments that have been paid.

````sql
SELECT
    p.payment_installments,
    COUNT(DISTINCT o.order_id) AS num_of_orders
FROM
    `target_business_case.customers` c
INNER JOIN
    `target_business_case.orders` o
ON
    c.customer_id = o.customer_id
INNER JOIN
    `target_business_case.payments` p
ON
    o.order_id = p.order_id
GROUP BY
    1
ORDER BY
    1;
````

**_Results_**

| payment_installments | num_of_orders |
|----------------------|---------------|
| 0                    | 2             |
| 1                    | 49060         |
| 2                    | 12389         |
| 3                    | 10443         |
| 4                    | 7088          |
| 5                    | 5234          |
| 6                    | 3916          |
| 7                    | 1623          |
| 8                    | 4253          |
| 9                    | 644           |
| 10                   | 5315          |
| 11                   | 23            |
| 12                   | 133           |
| 13                   | 16            |
| 14                   | 15            |
| 15                   | 74            |
| 16                   | 5             |
| 17                   | 8             |
| 18                   | 27            |
| 20                   | 17            |
| 21                   | 3             |
| 22                   | 1             |
| 23                   | 1             |
| 24                   | 18            |

:exclamation: **Insight -** We have to find out the number of orders placed on the basis of payments installations. So, first we need to join the tables that have number of orders and payment  installments. We do that using the **inner join** on the **order_id** column. Then, using *group by* we group all the installments values and to get the number of orders for each installment we use **count(distinct order_id)**. Henceforth, we get payment_installment value and the total number of orders placed in that installment.
