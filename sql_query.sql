/*
*Business Case: Target SQL
*Case study by Mayank Singh mayanksingholive@gmail.com
*
For this project you play the role of a data analyst for Target company.
Target is a globally renowned brand and a prominent retailer in the United States. Target makes itself a preferred 
shopping destination by offering outstanding value, inspiration, innovation and an exceptional guest experience
that no other retailer can deliver.

This particular business case focuses on the operations of Target in Brazil and provides insightful information 
about 100,000 orders placed between 2016 and 2018. The dataset offers a comprehensive view of various dimensions 
including the order status, price, payment and freight performance, customer location, product attributes 
and customer reviews.

By analyzing this extensive dataset, it becomes possible to gain valuable insights into Target's operations in Brazil. 
The information can shed light on various aspects of the business, such as order processing, 
pricing strategies, payment and shipping efficiency, customer demographics, product characteristics 
and customer satisfaction levels.

Let's go for it!

*/

-- Data type of all columns in the "customers" table.

SELECT table_name, column_name, data_type
FROM target_business_case.INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'customers'

-- Result:

| table_name | column_name              | data_type |
|------------|--------------------------|-----------|
| customers  | customer_id              | STRING    |
| customers  | customer_unique_id       | STRING    |
| customers  | customer_zip_code_prefix | INT64     |
| customers  | customer_city            | STRING    |
| customers  | customer_state           | STRING    |

-- Get the time range between which the orders were placed.

SELECT 
    MIN(EXTRACT(DATE FROM order_purchase_timestamp)) AS first_date,
    MAX(EXTRACT(DATE FROM order_purchase_timestamp)) AS last_date
FROM `target_business_case.orders`;

-- Result: 

| first_date | last_date  |
|------------|------------|
| 2016-09-04 | 2018-10-17 |

-- Count the Cities & States of customers who ordered during the given period.

SELECT
    COUNT(DISTINCT c.customer_city) AS city_count,
    COUNT(DISTINCT c.customer_state) AS state_count
FROM
    `target_business_case.customers` c
INNER JOIN
    `target_business_case.orders` o ON c.customer_id = o.customer_id;

-- Result: 

| city_count | state_count |
|------------|-------------|
| 4119       | 27          |

-- Is there a growing trend in the no. of orders placed over the past years?

SELECT
    EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
    COUNT(order_id) AS count_orders
FROM
    `target_business_case.orders`
GROUP BY
    1
ORDER BY
    1 ASC;

-- Results: 

| year | count_orders |
|------|--------------|
| 2016 | 329          |
| 2017 | 45101        |
| 2018 | 54011        |

-- Can we see some kind of monthly seasonality in terms of the no. of orders being placed?

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

-- Result:

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

-- During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)
  -- 0-6 hrs : Dawn
  -- 7-12 hrs : Mornings
  -- 13-18 hrs : Afternoon
  -- 19-23 hrs : Night

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

-- Result:

| day_time  | number_of_orders |
|-----------|------------------|
| Mornings  | 22240            |
| Dawn      | 4740             |
| Afternoon | 38361            |
| Night     | 34100            |

-- Get the month on month no. of orders placed in each state.

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

-- Result: 

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


-- How are the customers distributed across all the states ?

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

--Result:

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


-- Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only). You can use the "payment_value" column in the payments table to get the cost of orders.

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

-- Result:

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

-- Calculate the Total & Average value of order price for each state.

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

-- Result:

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

-- Calculate the Total & Average value of order freight for each state. 

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

-- Result:

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


/* Find the no. of days taken to deliver each order from the order’s purchase date as delivery time. 
Also, calculate the difference (in days) between the estimated & actual delivery date of an order.
Do this in a single query.
You can calculate the delivery time and the difference between the estimated & actual delivery date using the given formula:
  time_to_deliver = order_delivered_customer_date - order_purchase_timestamp
  diff_estimated_delivery = order_estimated_delivery_date - order_delivered_customer_date
*/

SELECT DISTINCT
    order_id,
    DATE_DIFF(order_delivered_customer_date, order_purchase_timestamp, DAY) AS time_to_deliver,
    DATE_DIFF(order_estimated_delivery_date, order_delivered_customer_date, DAY) AS diff_estimated_delivery
FROM `target_business_case.orders`
WHERE DATE_DIFF(order_delivered_customer_date, order_purchase_timestamp, DAY) IS NOT NULL
    AND DATE_DIFF(order_estimated_delivery_date, order_delivered_customer_date, DAY) IS NOT NULL
LIMIT 10;

-- Result:

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


-- Find out the top 5 states with the highest & lowest average freight value.

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

-- Result:

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

-- Find out the top 5 states with the highest & lowest average delivery time.

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

-- Result: 

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


/*Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.
You can use the difference between the averages of actual & estimated delivery date to figure out how fast the 
delivery was for each state.*/

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

-- Result: 

| customer_state | difference |
|----------------|------------|
| AL             | 8.0        |
| MA             | 9.0        |
| SE             | 9.0        |
| ES             | 10.0       |
| SP             | 10.0       |


-- Find the month on month no. of orders placed using different payment types.

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

-- Result:

| payment_type	months	num_orders |               |       |       |     |      |      |        |           |         |          |                 |      |      |      |      |      |      |      |      |      |      |       |
|--------------------------------|---------------|-------|-------|-----|------|------|--------|-----------|---------|----------|-----------------|------|------|------|------|------|------|------|------|------|------|-------|
| UPI	"January                   | February      | March | April | May | June | July | August | September | October | November | December"	"1715 | 1723 | 1942 | 1783 | 2035 | 1807 | 2074 | 2077 | 903  | 1056 | 1509 | 1160" |
| credit_card	"January           | February      | March | April | May | June | July | August | September | October | November | December"	"6093 | 6582 | 7682 | 7276 | 8308 | 7248 | 7810 | 8235 | 3277 | 3763 | 5867 | 4364" |
| debit_card	"January            | February      | March | April | May | June | July | August | September | October | November | December"	"118  | 82   | 109  | 124  | 81   | 208  | 264  | 311  | 43   | 54   | 70   | 64"   |
| not_defined	"August            | September"	"2 | 1"    |       |     |      |      |        |           |         |          |                 |      |      |      |      |      |      |      |      |      |      |       |
| voucher	"January               | February      | March | April | May | June | July | August | September | October | November | December"	"337  | 288  | 395  | 353  | 374  | 373  | 417  | 430  | 189  | 223  | 267  | 220"  |


-- Find the no. of orders placed on the basis of the payment installments that have been paid.

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

-- Result:

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

