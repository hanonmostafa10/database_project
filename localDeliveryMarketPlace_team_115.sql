CREATE DATABASE localDeliveryMarketPlace_team_115;
GO
USE localDeliveryMarketPlace_team_115;
GO
CREATE PROCEDURE createAllTables 
AS
BEGIN 

CREATE TABLE ZONE(
zone_id  INT IDENTITY(1,1) PRIMARY KEY,
zone_name VARCHAR(50) NOT NULL UNIQUE ,
delivery_fee DECIMAL(10,2) NOT NULL CHECK(delivery_fee>=0));

CREATE TABLE Users (
user_id INT IDENTITY(1,10) PRIMARY KEY ,
fisrt_name VARCHAR(30) NOT NULL ,
middle_name VARCHAR(30),
last_name VARCHAR(30) NOT NULL,
username VARCHA(30) NOT NULL UNIQUE,
password  VARCHAR(30) NOT NULL ,
email VARCHAR(100) NOT NULL UNIQUE ,
dob DATE ,
account VARCHAR(20) NOT NULL DEFAULT 'Active')

CREATE TABLE User_Phone (
    user_id     INT      NOT NULL,
    phone       CHAR(11) NOT NULL,
    PRIMARY KEY (user_id, phone),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
 

CREATE TABLE Admin (
    admin_id    INT PRIMARY KEY,
    role        VARCHAR(20) NOT NULL DEFAULT 'Super Admin',
    zone_id     INT NULL,
    FOREIGN KEY (admin_id) REFERENCES Users(user_id),
    FOREIGN KEY (zone_id)  REFERENCES Zone(zone_id),
    CHECK (role <> 'Super Admin' OR zone_id IS NULL)   
);
 

CREATE TABLE Partner (
    partner_id  INT PRIMARY KEY,
    FOREIGN KEY (partner_id) REFERENCES Users(user_id)
);
 

CREATE TABLE Rider (
    rider_id        INT PRIMARY KEY,
    vehicle_type    VARCHAR(30) NOT NULL,
    plate_no        VARCHAR(15) NOT NULL UNIQUE,
    license_no      VARCHAR(20) NOT NULL UNIQUE,
    is_available    BIT NOT NULL DEFAULT 1,
    zone_id         INT NOT NULL,
    FOREIGN KEY (rider_id) REFERENCES Users(user_id),
    FOREIGN KEY (zone_id)  REFERENCES Zone(zone_id)
);
 

CREATE TABLE Customer (
    customer_id     INT PRIMARY KEY,
    wallet_balance  DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (wallet_balance >= 0),
    FOREIGN KEY (customer_id) REFERENCES Users(user_id)
);
 

CREATE TABLE Address (
    address_id      INT IDENTITY(1,1) PRIMARY KEY,
    description     VARCHAR(150) NOT NULL,
    is_active       BIT NOT NULL DEFAULT 1,
    customer_id     INT NOT NULL,
    zone_id         INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    FOREIGN KEY (zone_id)     REFERENCES Zone(zone_id)
);
 

CREATE TABLE Card (
    card_id             INT IDENTITY(1,1) PRIMARY KEY,
    card_no             CHAR(16)     NOT NULL,
    card_holder_name    VARCHAR(100) NOT NULL,
    expiration_date     DATE         NOT NULL,
    customer_id         INT          NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    UNIQUE (customer_id, card_no)
);
 

CREATE TABLE Business (
    business_id             INT IDENTITY(1,1) PRIMARY KEY,
    name                    VARCHAR(100) NOT NULL,
    description             VARCHAR(255),
    link_website            VARCHAR(255),
    opening_hour            TIME NOT NULL,
    closing_hour            TIME NOT NULL,
    expected_delivery_time  INT  NOT NULL CHECK (expected_delivery_time > 0), 
    status                  VARCHAR(20) NOT NULL DEFAULT 'Pending',
    suspension_reason       VARCHAR(255),
    partner_id              INT NOT NULL UNIQUE,
    zone_id                 INT NOT NULL,
    FOREIGN KEY (partner_id) REFERENCES Partner(partner_id),
    FOREIGN KEY (zone_id)    REFERENCES Zone(zone_id),
    CHECK (status = 'Suspended' OR suspension_reason IS NULL) ); 
 
CREATE TABLE Business_Phone (
    business_id INT      NOT NULL,
    phone       CHAR(11) NOT NULL,
    PRIMARY KEY (business_id, phone),
    FOREIGN KEY (business_id) REFERENCES Business(business_id)
);
 

CREATE TABLE Restaurant (
    business_id     INT PRIMARY KEY,
    cuisine_type    VARCHAR(50) NOT NULL,
    food_category   VARCHAR(50) NOT NULL,
    FOREIGN KEY (business_id) REFERENCES Business(business_id)
);
 

CREATE TABLE Pharmacy (
    business_id     INT PRIMARY KEY,
    pharmacy_type   VARCHAR(50) NOT NULL,
    FOREIGN KEY (business_id) REFERENCES Business(business_id)
);
 

CREATE TABLE Blacklist (
    customer_id INT PRIMARY KEY,
    admin_id    INT NOT NULL,
    reason      VARCHAR(255) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    FOREIGN KEY (admin_id)    REFERENCES Admin(admin_id)
);
CREATE TABLE Product (
    product_id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    category VARCHAR(50) NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price > 0),
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    is_available BIT NOT NULL DEFAULT 1,
    business_id INT NOT NULL,

    FOREIGN KEY (business_id) REFERENCES Business(business_id),
    CHECK (discount_amount >= 0 AND discount_amount <= 0.5 * price)
);


CREATE TABLE Favorite_Business (
    customer_id INT,
    business_id INT,

    PRIMARY KEY (customer_id, business_id),
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    FOREIGN KEY (business_id) REFERENCES Business(business_id)
);


CREATE TABLE Favorite_Product (
    customer_id INT,
    product_id INT,

    PRIMARY KEY (customer_id, product_id),
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

CREATE TABLE Voucher (
    voucher_id INT IDENTITY(1,1) PRIMARY KEY,
    promo_code VARCHAR(30) NOT NULL UNIQUE,
    is_percentage BIT NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    expiry_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Unused',
    customer_id INT NOT NULL,

    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);

CREATE TABLE Cart (
    cart_id INT IDENTITY(1,1) PRIMARY KEY,
    status VARCHAR(20) NOT NULL DEFAULT 'Active',
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    customer_id INT NOT NULL,
    address_id INT NOT NULL,

    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    FOREIGN KEY (address_id) REFERENCES Address(address_id)
);

CREATE TABLE CartItem (
    cart_id INT,
    product_id INT,
    quantity INT NOT NULL CHECK (quantity BETWEEN 1 AND 10),
    notes VARCHAR(255),
    unit_price DECIMAL(10,2),

    PRIMARY KEY (cart_id, product_id),
    FOREIGN KEY (cart_id) REFERENCES Cart(cart_id),
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

CREATE TABLE Orders (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    order_date DATETIME NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Placed',
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(10,2) NOT NULL,
    cart_id INT NOT NULL UNIQUE,
    zone_id INT NOT NULL,
    voucher_id INT,

    FOREIGN KEY (cart_id) REFERENCES Cart(cart_id),
    FOREIGN KEY (zone_id) REFERENCES Zone(zone_id),
    FOREIGN KEY (voucher_id) REFERENCES Voucher(voucher_id)
);

CREATE TABLE SubOrder (
    suborder_id INT IDENTITY(1,1) PRIMARY KEY,
    status VARCHAR(20) NOT NULL DEFAULT 'Placed',
    total_price DECIMAL(10,2) NOT NULL,
    delivery_fee DECIMAL(10,2) NOT NULL,
    order_id INT NOT NULL,
    business_id INT NOT NULL,

    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (business_id) REFERENCES Business(business_id),
    UNIQUE (order_id, business_id)
);

CREATE TABLE Payment (
    payment_id INT IDENTITY(1,1) PRIMARY KEY,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'EGP',
    method VARCHAR(20) NOT NULL,
    transaction_date DATETIME NOT NULL,
    refunded_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    order_id INT NOT NULL UNIQUE,
    card_id INT,

    CHECK (refunded_amount <= amount),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (card_id) REFERENCES Card(card_id)
);

CREATE TABLE Feedback (
    feedback_id INT IDENTITY(1,1) PRIMARY KEY,
    headline VARCHAR(100) NOT NULL,
    description VARCHAR(500),
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    feedback_date DATETIME NOT NULL DEFAULT GETDATE(),
    suborder_id INT NOT NULL UNIQUE,

    FOREIGN KEY (suborder_id) REFERENCES SubOrder(suborder_id)
);
END ;
GO

CREATE PROCEDURE dropALLTables 
AS 
BEGIN 
  DROP TABLE Feedback;
    DROP TABLE Payment;
    DROP TABLE SubOrder;
    DROP TABLE Orders;
    DROP TABLE CartItem;
    DROP TABLE Cart;
    DROP TABLE Voucher;
    DROP TABLE Favorite_Product;
    DROP TABLE Favorite_Business;
    DROP TABLE Product;
    DROP TABLE Blacklist;
    DROP TABLE Restaurant;
    DROP TABLE Pharmacy;
    DROP TABLE Business_Phone;
    DROP TABLE Business;
    DROP TABLE Card;
    DROP TABLE Address;
    DROP TABLE Customer;
    DROP TABLE Rider;
    DROP TABLE Partner;
    DROP TABLE Admin;
    DROP TABLE User_Phone;
    DROP TABLE Users;
    DROP TABLE Zone;
END;
GO

CREATE PROCEDURE dropAllProceduresFunctionsViews
AS
BEGIN
    DROP VIEW IF EXISTS allBusinessProfiles;
    DROP VIEW IF EXISTS BusinessesPerZone;
    DROP VIEW IF EXISTS BusinessRatingsSummary;
    DROP VIEW IF EXISTS ActiveVouchers;
    DROP VIEW IF EXISTS PendingBusinessApprovals;
    DROP VIEW IF EXISTS RiderPerformanceSummary;
    DROP VIEW IF EXISTS TopSellingProducts;
    DROP VIEW IF EXISTS ZoneDeliveryPerformance;

    DROP PROCEDURE IF EXISTS createAllTables;
    DROP PROCEDURE IF EXISTS dropAllTables;
    DROP PROCEDURE IF EXISTS clearAllTables;
    -- Functions
    -- DROP FUNCTION IF EXISTS functionName;
END;
GO

CREATE PROCEDURE clearAllTables 
AS 
BEGIN 
 EXEC dropAllTables;
 EXEC createAllTables;
END;
GO

EXEC createAllTables;
GO

CREATE VIEW allBusinessProfiles
AS
SELECT
    B.business_id,
    B.name AS business_name,
    B.business_type,
    Z.zone_name,
    U.fisrt_name + ' ' + U.last_name AS partner_name,
    B.status,
    B.opening_hour,
    B.closing_hour
FROM Business B
INNER JOIN Partner P
    ON B.partner_id = P.partner_id
INNER JOIN USRERS U
    ON P.partner_id = U.user_id
INNER JOIN Zone Z
    ON B.zone_id = Z.zone_id;
GO

CREATE VIEW BusinessesPerZone 
AS
SELECT z.zone_id , z.zone_name, COUNT(b.business_id) AS business_count
FROM zone z
LEFT JOIN business b ON z.zone_id = b.zone_id  AND B.status = 'Active'
GROUP BY z.zone_id , z.zone_name;
GO

CREATE VIEW BusinessRatingsSummary
AS
SELECT b.business_id, b.name AS business_name, AVG(CAST(f.rating AS DECIMAL(3,2))) AS avg_rating, COUNT(f.feedbak_id) AS ratings_count
FROM Business B
LEFT JOIN SubOrder S
    ON B.business_id = S.business_id
LEFT JOIN Feedback F
    ON S.suborder_id = F.suborder_id
GROUP BY B.business_id, B.name;
GO

CREATE VIEW ActiveVouchers
AS
SELECT
    voucher_id,
    promo_code,
    customer_id,
    is_percentage,
    amount,
    expiry_date
FROM Voucher
WHERE status = 'Unused'
  AND expiry_date >= CAST(GETDATE() AS DATE);
  GO

  CREATE VIEW PendingBusinessApprovals
AS
SELECT
    B.business_id,
    B.name AS business_name,
    T.business_type,
    Z.zone_name,
    U.first_name + ' ' + U.last_name AS partner_name
FROM Business B
INNER JOIN Users U
ON B.partner_id = U.user_id
INNER JOIN Zone Z 
ON B.zone_id = Z.zone_id
LEFT JOIN (
    SELECT business_id, 'Restaurant' AS business_type FROM Restaurant
    UNION ALL
    SELECT business_id, 'Pharmacy' FROM Pharmacy) T
ON B.business_id = T.business_id
WHERE B.status = 'Pending';
GO

CREATE VIEW RiderPerformanceSummary
AS
SELECT  R.rider_id,
    u.first_name + ' ' + u.last_name AS rider_name,
    Z.zone_name, COUNT(d.delivery_id) AS completed_deliveries,
    AVG(CAST(D.rider_rating AS DECIMAL(3,2))) AS avg_rating
    FROM Rider R
    INNER JOIN Users u ON R.rider_id = u.user_id
    INNER JOIN Zone z ON R.zone_id = z.zone_id
    LEFT JOIN Delivery D  ON R.rider_id = D.rider_id
    LEFT JOIN SubOrder S  ON D.suborder_id = S.suborder_id AND S.status = 'Delivered'
    GROUP BY R.rider_id, U.first_name, U.last_name, Z.zone_name;
GO

CREATE VIEW TopSellingProducts
AS 
SELECT TOP 10 p.product_id, p.name AS product_name, b.name AS business_name,
T.business_type, SUM(ci.quantity) AS units_sold, SUM(ci.quantity * ci.unit_price) AS total_revenue
FROM Product P
INNER JOIN Business B  ON P.business_id = B.business_id
INNER JOIN CartItem CI ON P.product_id = CI.product_id
INNER JOIN Orders O    ON CI.cart_id = O.cart_id
INNER JOIN SubOrder S  ON S.order_id = O.order_id
                      AND S.business_id = P.business_id
LEFT JOIN (
    SELECT business_id, 'Restaurant' AS business_type FROM Restaurant
    UNION ALL
    SELECT business_id, 'Pharmacy' FROM Pharmacy
) T ON B.business_id = T.business_id
WHERE S.status <> 'Cancelled'
GROUP BY P.product_id, P.name, B.name, T.business_type
ORDER BY units_sold DESC, P.product_id ASC;
GO


CREATE VIEW ZoneDeliveryPerformance
AS 
SELECT z.zone_id, z.zone_name, count(d.delivery_id) AS delivery_count, AVG(CAST(d.tracking_time AS DECIMAL(10,2))) AS avg_tracking_time
FROM zone z 
LEFT JOIN orders o ON z.zone_id = o.zone_id
LEFT JOIN suborder s ON o.order_id = s.order_id
LEFT JOIN delivery d ON s.suborder_id = d.suborder_id AND D.delivered_at IS NOT NULL
GROUP BY z.zone_id, z.zone_name
GO






