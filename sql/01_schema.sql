/*
===============================================================================
 InsightFlow — Star Schema DDL
===============================================================================
 Source: Brazilian E-Commerce Public Dataset by Olist
 Grain : one row per order item (fact_order_items), joined to
         one row per order (dim_order), customer, product, seller and date.

 Relationships
 -------------
 dim_order.customer_unique_id  -> dim_customer.customer_unique_id
 dim_order.order_purchase_date -> dim_date.date
 fact_order_items.order_id     -> dim_order.order_id
 fact_order_items.product_id   -> dim_product.product_id
 fact_order_items.seller_id    -> dim_seller.seller_id
 fact_payments.order_id        -> dim_order.order_id
 fact_reviews.order_id         -> dim_order.order_id
===============================================================================
*/

-- ============================
-- DIMENSION TABLES
-- ============================

CREATE TABLE dim_customer (
    customer_unique_id  TEXT PRIMARY KEY,
    customer_city       TEXT,
    customer_state      TEXT
);

CREATE TABLE dim_date (
    date              TEXT PRIMARY KEY,   -- YYYY-MM-DD
    year              INTEGER,
    quarter           TEXT,
    month_number      INTEGER,
    month_name        TEXT,
    month_short       TEXT,
    year_month        TEXT,               -- YYYY-MM
    week_number       INTEGER,
    day               INTEGER,
    day_name          TEXT,
    day_of_week       INTEGER,
    is_weekend        BOOLEAN,
    month_year_sort   INTEGER
);

CREATE TABLE dim_product (
    product_id                  TEXT PRIMARY KEY,
    product_category_name       TEXT,
    product_name_lenght         REAL,
    product_description_lenght  REAL,
    product_photos_qty          REAL,
    product_weight_g            REAL,
    product_length_cm           REAL,
    product_height_cm           REAL,
    product_width_cm            REAL
);

CREATE TABLE dim_seller (
    seller_id      TEXT PRIMARY KEY,
    seller_city    TEXT,
    seller_state   TEXT
);

CREATE TABLE dim_order (
    order_id                        TEXT PRIMARY KEY,
    customer_id                     TEXT,
    order_status                    TEXT,
    order_purchase_timestamp        TEXT,
    order_approved_at               TEXT,
    order_delivered_carrier_date    TEXT,
    order_delivered_customer_date   TEXT,
    order_estimated_delivery_date   TEXT,
    customer_unique_id              TEXT REFERENCES dim_customer(customer_unique_id),
    order_purchase_date             TEXT REFERENCES dim_date(date)
);

-- ============================
-- FACT TABLES
-- ============================

CREATE TABLE fact_order_items (
    order_id             TEXT REFERENCES dim_order(order_id),
    order_item_id        INTEGER,
    product_id           TEXT REFERENCES dim_product(product_id),
    seller_id            TEXT REFERENCES dim_seller(seller_id),
    shipping_limit_date  TEXT,
    price                REAL,
    freight_value        REAL
);

CREATE TABLE fact_payments (
    order_id              TEXT REFERENCES dim_order(order_id),
    payment_sequential    INTEGER,
    payment_type          TEXT,
    payment_installments  INTEGER,
    payment_value         REAL
);

CREATE TABLE fact_reviews (
    review_id               TEXT PRIMARY KEY,
    order_id                TEXT REFERENCES dim_order(order_id),
    review_score            INTEGER,
    review_creation_date    TEXT,
    review_answer_timestamp TEXT,
    review_response_time    TEXT,
    response_time_hours     REAL,
    response_time_group     TEXT,
    review_category         TEXT,
    comment_length          INTEGER,
    comment_word_count      INTEGER,
    has_comment              BOOLEAN,
    has_title                BOOLEAN
);

-- ============================
-- HELPFUL INDEXES
-- ============================
CREATE INDEX idx_order_items_order_id   ON fact_order_items(order_id);
CREATE INDEX idx_order_items_product_id ON fact_order_items(product_id);
CREATE INDEX idx_order_items_seller_id  ON fact_order_items(seller_id);
CREATE INDEX idx_payments_order_id      ON fact_payments(order_id);
CREATE INDEX idx_reviews_order_id       ON fact_reviews(order_id);
CREATE INDEX idx_order_customer         ON dim_order(customer_unique_id);
CREATE INDEX idx_order_purchase_date    ON dim_order(order_purchase_date);
