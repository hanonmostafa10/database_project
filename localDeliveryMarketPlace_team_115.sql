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
user_id INT IDENTITY(1,1) PRIMARY KEY ,
first_name VARCHAR(30) NOT NULL ,
middle_name VARCHAR(30),
last_name VARCHAR(30) NOT NULL,
username VARCHAR(30) NOT NULL UNIQUE,
password  VARCHAR(30) NOT NULL ,
email VARCHAR(100) NOT NULL UNIQUE ,
dob DATE ,
account_status VARCHAR(20) NOT NULL DEFAULT 'Active'
    CHECK (account_status IN ('Active', 'Blacklisted')))

CREATE TABLE User_Phone (
    user_id     INT      NOT NULL,
    phone       CHAR(11) NOT NULL,
    PRIMARY KEY (user_id, phone),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
 

CREATE TABLE Admin (
    admin_id    INT PRIMARY KEY,
    role        VARCHAR(20) NOT NULL DEFAULT 'Super Admin'
                CHECK (role IN ('Super Admin', 'Zone Admin')),
    zone_id     INT NULL,
    FOREIGN KEY (admin_id) REFERENCES Users(user_id),
    FOREIGN KEY (zone_id)  REFERENCES Zone(zone_id),
    CHECK (role <> 'Super Admin' OR zone_id IS NULL),
    CHECK (role <> 'Zone Admin' OR zone_id IS NOT NULL)
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
    status VARCHAR(20) NOT NULL DEFAULT 'Pending'
    CHECK (status IN ('Pending', 'Active', 'Suspended', 'Rejected')),
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
    status VARCHAR(20) NOT NULL DEFAULT 'Unused'
    CHECK (status IN ('Unused', 'Used')),
    customer_id INT NOT NULL,

    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);

CREATE TABLE Cart (
    cart_id INT IDENTITY(1,1) PRIMARY KEY,
    status VARCHAR(20) NOT NULL DEFAULT 'Active'
    CHECK (status IN ('Active', 'Checked Out')),
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
    status VARCHAR(20) NOT NULL DEFAULT 'Placed'
    CHECK (status IN ('Placed', 'In Progress', 'Delivered', 'Cancelled')),
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
   status VARCHAR(20) NOT NULL DEFAULT 'Placed'
    CHECK (status IN ('Placed', 'Assigned', 'Picked Up', 'Delivered', 'Cancelled')),
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
   method VARCHAR(20) NOT NULL
    CHECK (method IN ('Cash', 'Card', 'Wallet')),
    transaction_date DATETIME NOT NULL,
    refunded_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    order_id INT NOT NULL UNIQUE,
    card_id INT,

    CHECK (refunded_amount <= amount),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (card_id) REFERENCES Card(card_id)
);

CREATE TABLE Delivery (
    delivery_id INT IDENTITY(1,1) PRIMARY KEY,
    assigned_at DATETIME NOT NULL,
    picked_up_at DATETIME,
    delivered_at DATETIME,
    tracking_time INT,
    rider_rating INT
        CHECK (rider_rating BETWEEN 1 AND 5),
    suborder_id INT NOT NULL UNIQUE,
    rider_id INT NOT NULL,

    FOREIGN KEY (suborder_id) REFERENCES SubOrder(suborder_id),
    FOREIGN KEY (rider_id) REFERENCES Rider(rider_id)
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
    DROP PROCEDURE IF EXISTS clearAllTables
    -- to be returedn to later lms nekteb el functions 
    -- Functions
    DROP FUNCTION IF EXISTS CustomerLoginValidation;
    DROP FUNCTION IF EXISTS PartnerLoginValidation;
    DROP FUNCTION IF EXISTS RiderLoginValidation;
    DROP FUNCTION IF EXISTS AdminLoginValidation;
    DROP FUNCTION IF EXISTS ZoneOrderReport;
    DROP FUNCTION IF EXISTS Daily_Revenue_Report ; 
    DROP FUNCTION IF EXISTS TopRiders ;
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
    T.business_type,
    Z.zone_name,
    U.first_name + ' ' + U.last_name AS partner_name,
    B.status,
    B.opening_hour,
    B.closing_hour
FROM Business B
INNER JOIN Users U ON B.partner_id = U.user_id
INNER JOIN Zone Z  ON B.zone_id = Z.zone_id
LEFT JOIN (
    SELECT business_id, 'Restaurant' AS business_type FROM Restaurant
    UNION ALL
    SELECT business_id, 'Pharmacy' FROM Pharmacy
) T ON B.business_id = T.business_id;
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
SELECT b.business_id, b.name AS business_name, AVG(CAST(f.rating AS DECIMAL(3,2))) AS avg_rating, COUNT(f.feedback_id) AS ratings_count
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
    Z.zone_name, COUNT(S.suborder_id) AS completed_deliveries,
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





CREATE PROCEDURE Customer_Register
    @first_name VARCHAR(30),
    @middle_name VARCHAR(30),
    @last_name VARCHAR(30),
    @username VARCHAR(30),
    @password VARCHAR(30),
    @email VARCHAR(100),
    @phone CHAR(11),
    @dob DATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Users
        WHERE username = @username OR email = @email)
        RETURN -2;

    IF EXISTS (
        SELECT 1
        FROM User_Phone
        WHERE phone = @phone)
        RETURN -2;

    INSERT INTO Users(first_name, middle_name, last_name, username, password, email, dob)
    VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob);
    
    DECLARE @user_id INT;
    SET @user_id = SCOPE_IDENTITY();

    INSERT INTO Customer (customer_id, wallet_balance)
    VALUES (@user_id, 0);

    INSERT INTO User_Phone (user_id, phone)
    VALUES (@user_id, @phone);

    RETURN 0;
END;
GO

CREATE PROCEDURE Partner_Register
    @first_name VARCHAR(30),
    @middle_name VARCHAR(30),
    @last_name VARCHAR(30),
    @username VARCHAR(30),
    @password VARCHAR(30),
    @email VARCHAR(100),
    @phone CHAR(11),
    @dob DATE
AS
BEGIN
IF EXISTS (
        SELECT 1
        FROM Users
        WHERE username = @username OR email = @email)
        RETURN -2;

    IF EXISTS (
        SELECT 1
        FROM User_Phone
        WHERE phone = @phone)
        RETURN -2;

    INSERT INTO Users(first_name, middle_name, last_name, username, password, email, dob)
    VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob);
    
    DECLARE @user_id INT;
    SET @user_id = SCOPE_IDENTITY();

    INSERT INTO Partner (partner_id)
    VALUES (@user_id);

    INSERT INTO User_Phone (user_id, phone)
    VALUES (@user_id, @phone);

    RETURN 0;
END;
GO

CREATE PROCEDURE Rider_Register 
    @first_name VARCHAR(30),
    @middle_name VARCHAR(30),
    @last_name VARCHAR(30),
    @username VARCHAR(30),
    @password VARCHAR(30),
    @email VARCHAR(100),
    @phone CHAR(11),
    @dob DATE,
    @vehicle_type VARCHAR(30),
    @plate_no VARCHAR(15), 
    @license_no VARCHAR(20), 
    @zone_id INT
    AS 
    BEGIN 
    IF EXISTS (
        SELECT 1
        FROM Users
        WHERE username = @username OR email = @email)
        RETURN -2;

    IF EXISTS (
        SELECT 1
        FROM User_Phone
        WHERE phone = @phone)
        RETURN -2;

    IF EXISTS (
        SELECT 1 
        FROM Rider
        WHERE plate_no = @plate_no OR License_no = @license_no)
        RETURN -2;

    IF  NOT EXISTS (
        SELECT 1 
        FROM Zone 
        WHERE zone_id = @zone_id)
        RETURN -1;

    INSERT INTO Users(first_name, middle_name, last_name, username, password, email, dob)
    VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob);
    
    DECLARE @user_id INT;
    SET @user_id = SCOPE_IDENTITY();

    INSERT INTO Rider (rider_id, vehicle_type, plate_no, license_no, is_available, zone_id)
    VALUES (@user_id, @vehicle_type, @plate_no, @license_no, 1, @zone_id);

    INSERT INTO User_Phone (user_id, phone)
    VALUES (@user_id, @phone);


    RETURN 0;
END;
GO

CREATE FUNCTION CustomerLoginValidation
    (@username VARCHAR(30),@password VARCHAR(30))
    RETURNS BIT
    AS
    BEGIN
    DECLARE @success BIT = 0;
    IF EXISTS ( 
        SELECT 1 
        FROM users U
        INNER JOIN Customer C ON U.user_id = C.Customer_id 
        WHERE U.username = @username AND U.password = @password AND U.account_status ='Active')
    SET @success = 1;
    RETURN @success;
    END;
    GO

    CREATE FUNCTION PartnerLoginValidation
    (@username VARCHAR(30),@password VARCHAR(30))
    RETURNS BIT
    AS
    BEGIN
    DECLARE @success BIT = 0;
    IF EXISTS ( 
        SELECT 1 
        FROM users U
        INNER JOIN partner P ON U.user_id = P.partner_id 
        WHERE U.username = @username AND U.password = @password AND U.account_status ='Active')
    SET @success = 1;
    RETURN @success;
    END;
    GO

    CREATE FUNCTION RiderLoginValidation
    (@username VARCHAR(30),@password VARCHAR(30))
    RETURNS BIT
    AS
    BEGIN
    DECLARE @success BIT = 0;
    IF EXISTS ( 
        SELECT 1 
        FROM users U
        INNER JOIN Rider R ON U.user_id = R.Rider_id 
        WHERE U.username = @username AND U.password = @password AND U.account_status ='Active')
    SET @success = 1;
    RETURN @success;
    END;
    GO

    CREATE FUNCTION AdminLoginValidation
    (@username VARCHAR(30),@password VARCHAR(30))
    RETURNS BIT
    AS
    BEGIN
    DECLARE @success BIT = 0;
    IF EXISTS ( 
        SELECT 1 
        FROM users U
        INNER JOIN Admin A ON U.user_id = A.Admin_id 
        WHERE U.username = @username AND U.password = @password AND U.account_status ='Active')
    SET @success = 1;
    RETURN @success;
    END;
    GO

CREATE PROCEDURE Change_Password
    @user_id INT,
    @old_password VARCHAR(30),
    @new_password VARCHAR(30),
    @new_password_repeat VARCHAR(30),
    @success BIT OUTPUT
AS
BEGIN

    SET @success = 0;

    IF EXISTS (
        SELECT 1
        FROM Users
        WHERE user_id = @user_id
          AND password = @old_password
    )
    AND @new_password = @new_password_repeat
    AND @new_password <> @old_password
    BEGIN
        UPDATE Users
        SET password = @new_password
        WHERE user_id = @user_id;

        SET @success = 1;
        RETURN 0;
    END
    RETURN -1;
END;
GO

CREATE PROCEDURE Create_Admin
    @first_name VARCHAR(30),
    @middle_name VARCHAR(30),
    @last_name VARCHAR(30),
    @username VARCHAR(30),
    @password VARCHAR(30),
    @email VARCHAR(100),
    @phone CHAR(11),
    @dob DATE,
    @role VARCHAR(20),
    @zone_id INT,
    @super_admin_id INT
    AS
    BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Admin
        WHERE admin_id = @super_admin_id
          AND role = 'Super Admin'
    )
        RETURN -3;

    IF @role IS NULL
        SET @role = 'Super Admin';

    IF @first_name IS NULL OR @last_name IS NULL OR @username IS NULL
       OR @password IS NULL OR @email IS NULL OR @phone IS NULL
        RETURN -1;

    IF @role <> 'Super Admin' AND @role <> 'Zone Admin'
        RETURN -1;

    IF @role = 'Super Admin' AND @zone_id IS NOT NULL
        RETURN -1;

    IF @role = 'Zone Admin' AND NOT EXISTS (
        SELECT 1
        FROM Zone
        WHERE zone_id = @zone_id
    )
        RETURN -1;

    IF EXISTS (
        SELECT 1
        FROM Users
        WHERE username = @username
           OR email = @email
    )
        RETURN -2;

    IF EXISTS (
        SELECT 1
        FROM User_Phone
        WHERE phone = @phone
    )
        RETURN -2;

    INSERT INTO Users
        (first_name, middle_name, last_name,
         username, password, email, dob)
    VALUES
        (@first_name, @middle_name, @last_name,
         @username, @password, @email, @dob);

    DECLARE @user_id INT;
    SET @user_id = SCOPE_IDENTITY();

    INSERT INTO Admin (admin_id, role, zone_id)
    VALUES (@user_id, @role, @zone_id);

    INSERT INTO User_Phone (user_id, phone)
    VALUES (@user_id, @phone);

    RETURN 0;
END;
GO

CREATE PROCEDURE Approve_Business
    @business_id INT,
    @admin_id INT
AS
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM Admin
        WHERE admin_id = @admin_id
    )
        RETURN -3;

    IF NOT EXISTS (
        SELECT 1
        FROM Business
        WHERE business_id = @business_id
    )
        RETURN -1;

    IF EXISTS (
        SELECT 1
        FROM Admin A
        INNER JOIN Business B
            ON A.zone_id <> B.zone_id
        WHERE A.admin_id = @admin_id
          AND B.business_id = @business_id
          AND A.role = 'Zone Admin'
    )
        RETURN -3;

    IF NOT EXISTS (
        SELECT 1
        FROM Business
        WHERE business_id = @business_id
          AND status = 'Pending'
    )
        RETURN -4;

    UPDATE Business
    SET status = 'Active'
    WHERE business_id = @business_id;
    RETURN 0;
END;
GO

CREATE PROCEDURE Reject_Business
    @business_id INT,
    @admin_id INT
AS
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM Admin
        WHERE admin_id = @admin_id
    )
        RETURN -3;

    IF NOT EXISTS (
        SELECT 1
        FROM Business
        WHERE business_id = @business_id
    )
        RETURN -1;

    IF EXISTS (
        SELECT 1
        FROM Admin A
        INNER JOIN Business B
            ON A.zone_id <> B.zone_id
        WHERE A.admin_id = @admin_id
          AND B.business_id = @business_id
          AND A.role = 'Zone Admin'
    )
        RETURN -3;

    IF NOT EXISTS (
        SELECT 1
        FROM Business
        WHERE business_id = @business_id
          AND status = 'Pending'
    )
        RETURN -4;

    UPDATE Business
    SET status = 'Rejected'
    WHERE business_id = @business_id;
    RETURN 0;
END;
GO



CREATE PROCEDURE Suspend_Business
    @business_id INT,
    @admin_id INT,
    @reason VARCHAR(255)
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Business
        WHERE business_id = @business_id
    )
        RETURN -1;

    IF NOT EXISTS (
        SELECT 1
        FROM Business
        WHERE business_id = @business_id
          AND status = 'Active'
    )
        RETURN -4;

    IF NOT EXISTS (
        SELECT 1
        FROM Admin
        WHERE admin_id = @admin_id
    )
        RETURN -3;

    IF EXISTS (
        SELECT 1
        FROM Admin A
        INNER JOIN Business B
            ON A.zone_id <> B.zone_id
        WHERE A.admin_id = @admin_id
          AND B.business_id = @business_id
          AND A.role = 'Zone Admin'
    )
        RETURN -3;

    IF @reason IS NULL
        RETURN -1;

    UPDATE Business
    SET status = 'Suspended' , suspension_reason = @reason
    WHERE business_id = @business_id;

    UPDATE Product
    SET is_available = 0
    WHERE business_id = @business_id;



    UPDATE V
    SET status = 'Unused'
    FROM Voucher V
    INNER JOIN Orders O
        ON V.voucher_id = O.voucher_id
    WHERE EXISTS (
        SELECT 1
        FROM SubOrder S
        WHERE S.order_id = O.order_id
          AND S.business_id = @business_id
          AND S.status IN ('Placed', 'Assigned')
    )
    AND NOT EXISTS (
        SELECT 1
        FROM SubOrder S
        WHERE S.order_id = O.order_id
          AND S.business_id <> @business_id
          AND S.status <> 'Cancelled'
    );



    UPDATE C
    SET wallet_balance = wallet_balance + R.total_refund
    FROM Customer C
    INNER JOIN
    (
        SELECT
            CT.customer_id,
            SUM(
                CASE
                    WHEN P.refunded_amount + X.refund <= P.amount
                        THEN X.refund
                    ELSE P.amount - P.refunded_amount
                END
            ) AS total_refund
        FROM Payment P
        INNER JOIN Orders O
            ON P.order_id = O.order_id
        INNER JOIN Cart CT
            ON O.cart_id = CT.cart_id
        INNER JOIN
        (
            SELECT
                S.order_id,
                SUM(S.total_price + S.delivery_fee) AS refund
            FROM SubOrder S
            WHERE S.business_id = @business_id
              AND S.status IN ('Placed', 'Assigned')
            GROUP BY S.order_id
        ) X
            ON O.order_id = X.order_id
        WHERE P.method <> 'Cash'
        GROUP BY CT.customer_id
    ) R
        ON C.customer_id = R.customer_id;



    UPDATE P
    SET refunded_amount =
        refunded_amount +
        CASE
            WHEN refunded_amount + X.refund <= P.amount
                THEN X.refund
            ELSE P.amount - refunded_amount
        END
    FROM Payment P
    INNER JOIN
    (
        SELECT
            S.order_id,
            SUM(S.total_price + S.delivery_fee) AS refund
        FROM SubOrder S
        WHERE S.business_id = @business_id
          AND S.status IN ('Placed', 'Assigned')
        GROUP BY S.order_id
    ) X
        ON P.order_id = X.order_id;


    UPDATE SubOrder
    SET status = 'Cancelled'
    WHERE business_id = @business_id
      AND status IN ('Placed', 'Assigned');



    UPDATE O
    SET status =
        CASE
            WHEN NOT EXISTS (
                SELECT 1
                FROM SubOrder S
                WHERE S.order_id = O.order_id
                  AND S.status <> 'Cancelled'
            )
            THEN 'Cancelled'

            WHEN NOT EXISTS (
                SELECT 1
                FROM SubOrder S
                WHERE S.order_id = O.order_id
                  AND S.status NOT IN ('Cancelled', 'Delivered')
            )
            THEN 'Delivered'

            WHEN EXISTS (
                SELECT 1
                FROM SubOrder S
                WHERE S.order_id = O.order_id
                  AND S.status IN ('Picked Up', 'Delivered')
            )
            THEN 'In Progress'

            ELSE 'Placed'

        END
    FROM Orders O
    WHERE EXISTS (
        SELECT 1
        FROM SubOrder S
        WHERE S.order_id = O.order_id
          AND S.business_id = @business_id
    );

    RETURN 0;

END;
GO

CREATE PROCEDURE Reinstate_Business
    @business_id INT,
    @super_admin_id INT
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Admin
        WHERE admin_id = @super_admin_id
          AND role = 'Super Admin'
    )
        RETURN -3;
 
    IF NOT EXISTS (
        SELECT 1
        FROM Business
        WHERE business_id = @business_id
    )
        RETURN -1;

    IF NOT EXISTS (
        SELECT 1
        FROM Business
        WHERE business_id = @business_id
          AND status = 'Suspended'
    )
        RETURN -4;

    UPDATE Business
    SET status = 'Active',
        suspension_reason = NULL
    WHERE business_id = @business_id;

    RETURN 0;
END;
GO

CREATE PROCEDURE Create_Zone
    @zone_name VARCHAR(50),
    @delivery_fee DECIMAL(10,2),
    @super_admin_id INT
AS
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM Admin
        WHERE admin_id = @super_admin_id
          AND role = 'Super Admin'
    )
        RETURN -3;

    IF @zone_name IS NULL OR @delivery_fee IS NULL OR @delivery_fee < 0
        RETURN -1;

    IF EXISTS (
        SELECT 1
        FROM Zone
        WHERE zone_name = @zone_name
    )
        RETURN -2;

    INSERT INTO Zone (zone_name, delivery_fee)
    VALUES (@zone_name, @delivery_fee);

    RETURN 0;
END;
GO

CREATE PROCEDURE Update_Zone_Fee
    @zone_id INT,
    @new_fee DECIMAL(10,2),
    @super_admin_id INT
AS
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM Admin
        WHERE admin_id = @super_admin_id
          AND role = 'Super Admin'
    )
        RETURN -3;

    IF @zone_id IS NULL OR @new_fee IS NULL OR @new_fee < 0
        RETURN -1;

    IF NOT EXISTS (
        SELECT 1
        FROM Zone
        WHERE zone_id = @zone_id
    )
        RETURN -1;

    UPDATE Zone
    SET delivery_fee = @new_fee
    WHERE zone_id = @zone_id;
    RETURN 0;
END;
GO

CREATE PROCEDURE Assign_Admin_Zone
    @admin_id INT,
    @zone_id INT,
    @super_admin_id INT
AS
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM Admin
        WHERE admin_id = @super_admin_id
          AND role = 'Super Admin'
    )
        RETURN -3;

    IF @admin_id IS NULL OR @zone_id IS NULL
        RETURN -1;

    IF NOT EXISTS (
        SELECT 1
        FROM Admin
        WHERE admin_id = @admin_id
    )
        RETURN -1;

    IF NOT EXISTS (
        SELECT 1
        FROM Admin
        WHERE admin_id = @admin_id
          AND role = 'Zone Admin'
    )
        RETURN -3;

    IF NOT EXISTS (
        SELECT 1
        FROM Zone
        WHERE zone_id = @zone_id
    )
        RETURN -1;

    UPDATE Admin
    SET zone_id = @zone_id
    WHERE admin_id = @admin_id;

    RETURN 0;
END;
GO

CREATE PROCEDURE Issue_Voucher
    @customer_id INT,
    @promo_code VARCHAR(30),
    @is_percentage BIT,
    @amount DECIMAL(10,2),
    @expiry_date DATE,
    @admin_id INT
AS
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM Admin
        WHERE admin_id = @admin_id
    )
        RETURN -3;

    IF @customer_id IS NULL OR @promo_code IS NULL OR @is_percentage IS NULL
       OR @amount IS NULL OR @expiry_date IS NULL
        RETURN -1;

    IF NOT EXISTS (
        SELECT 1
        FROM Customer
        WHERE customer_id = @customer_id
    )
        RETURN -1;

    IF EXISTS (
        SELECT 1
        FROM Users
        WHERE user_id = @customer_id
          AND account_status = 'Blacklisted'
    )
        RETURN -3;

    IF EXISTS (
        SELECT 1
        FROM Admin
        WHERE admin_id = @admin_id
          AND role = 'Zone Admin'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM Address AD
        INNER JOIN Admin A
            ON AD.zone_id = A.zone_id
        WHERE A.admin_id = @admin_id
          AND AD.customer_id = @customer_id
    )
        RETURN -3;

    IF @amount <= 0
        RETURN -1;

    IF @is_percentage = 1 AND @amount > 100
        RETURN -1;

    IF @expiry_date < CAST(GETDATE() AS DATE)
        RETURN -1;

    IF EXISTS (
        SELECT 1
        FROM Voucher
        WHERE promo_code = @promo_code
    )
        RETURN -2;

    INSERT INTO Voucher
        (promo_code, is_percentage, amount, expiry_date, customer_id)
    VALUES
        (@promo_code, @is_percentage, @amount, @expiry_date, @customer_id);

    RETURN 0;
END;
GO


CREATE PROCEDURE Blacklist_Customer
    @customer_id INT,
    @admin_id INT,
    @reason VARCHAR(255)
AS
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM Customer
        WHERE customer_id = @customer_id
    )
        RETURN -1;



    IF EXISTS (
        SELECT 1
        FROM Users
        WHERE user_id = @customer_id
          AND account_status = 'Blacklisted'
    )
        RETURN -4;


    IF NOT EXISTS (
        SELECT 1
        FROM Admin
        WHERE admin_id = @admin_id
    )
        RETURN -3;


    IF EXISTS (
        SELECT 1
        FROM Admin
        WHERE admin_id = @admin_id
          AND role = 'Zone Admin'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM Admin A
        INNER JOIN Address AD
            ON A.zone_id = AD.zone_id
        WHERE A.admin_id = @admin_id
          AND AD.customer_id = @customer_id
    )
        RETURN -3;



    IF @reason IS NULL
        RETURN -1;


    UPDATE Users
    SET account_status = 'Blacklisted'
    WHERE user_id = @customer_id;

    INSERT INTO Blacklist
        (customer_id, admin_id, reason)
    VALUES
        (@customer_id, @admin_id, @reason);


    DECLARE @total_refund DECIMAL(10,2);

SELECT @total_refund = SUM(P.amount - P.refunded_amount)
FROM Cart CT
INNER JOIN Orders O  ON CT.cart_id = O.cart_id
INNER JOIN Payment P ON O.order_id = P.order_id
WHERE CT.customer_id = @customer_id
  AND O.status <> 'Cancelled'
  AND P.method <> 'Cash'
  AND NOT EXISTS (
      SELECT 1
      FROM SubOrder S
      WHERE S.order_id = O.order_id
        AND S.status IN ('Picked Up', 'Delivered')
  );

IF @total_refund > 0
    UPDATE Customer
    SET wallet_balance = wallet_balance + @total_refund
    WHERE customer_id = @customer_id;


    UPDATE P
    SET refunded_amount = P.amount
    FROM Payment P
    INNER JOIN Orders O
        ON P.order_id = O.order_id
    INNER JOIN Cart CT
        ON O.cart_id = CT.cart_id
    WHERE CT.customer_id = @customer_id
      AND O.status <> 'Cancelled'

      AND NOT EXISTS (
          SELECT 1
          FROM SubOrder S
          WHERE S.order_id = O.order_id
            AND S.status IN ('Picked Up', 'Delivered')
      );

    UPDATE V
    SET status = 'Unused'
    FROM Voucher V
    INNER JOIN Orders O
        ON V.voucher_id = O.voucher_id
    INNER JOIN Cart CT
        ON O.cart_id = CT.cart_id
    WHERE CT.customer_id = @customer_id
      AND O.status <> 'Cancelled'

      AND NOT EXISTS (
          SELECT 1
          FROM SubOrder S
          WHERE S.order_id = O.order_id
            AND S.status IN ('Picked Up', 'Delivered')
      );



    UPDATE O
    SET voucher_id = NULL
    FROM Orders O
    INNER JOIN Cart CT
        ON O.cart_id = CT.cart_id
    WHERE CT.customer_id = @customer_id
      AND O.status <> 'Cancelled'

      AND NOT EXISTS (
          SELECT 1
          FROM SubOrder S
          WHERE S.order_id = O.order_id
            AND S.status IN ('Picked Up', 'Delivered')
      );


    UPDATE S
    SET status = 'Cancelled'
    FROM SubOrder S
    INNER JOIN Orders O
        ON S.order_id = O.order_id
    INNER JOIN Cart CT
        ON O.cart_id = CT.cart_id
    WHERE CT.customer_id = @customer_id
      AND O.status <> 'Cancelled'

      AND NOT EXISTS (
          SELECT 1
          FROM SubOrder S2
          WHERE S2.order_id = O.order_id
            AND S2.status IN ('Picked Up', 'Delivered')
      );

    UPDATE O
    SET status = 'Cancelled'
    FROM Orders O
    INNER JOIN Cart CT
        ON O.cart_id = CT.cart_id
    WHERE CT.customer_id = @customer_id
      AND O.status <> 'Cancelled'

      AND NOT EXISTS (
          SELECT 1
          FROM SubOrder S
          WHERE S.order_id = O.order_id
            AND S.status IN ('Picked Up', 'Delivered')
      );

    DELETE FROM Voucher
    WHERE customer_id = @customer_id
      AND status = 'Unused';


    RETURN 0;

END;
GO


CREATE PROCEDURE Lift_Customer_Blacklist
    @customer_id INT,
    @admin_id INT
AS
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM Blacklist
        WHERE customer_id = @customer_id
    )
        RETURN -4;

    IF NOT EXISTS (
        SELECT 1
        FROM Blacklist
        WHERE customer_id = @customer_id
          AND admin_id = @admin_id
    )
        RETURN -3;


    UPDATE Users
    SET account_status = 'Active'
    WHERE user_id = @customer_id;

    DELETE FROM Blacklist
    WHERE customer_id = @customer_id;


    RETURN 0;

END;
GO

--functions to be dropped:


CREATE FUNCTION ZoneOrderReport
(
    @zone_id INT,
    @from_date DATE,
    @to_date DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        Z.zone_id,
        Z.zone_name,

        COUNT(O.order_id) AS number_of_orders,

        AVG(O.total_amount) AS avg_order_total,

        SUM(C.commission) AS platform_commission

    FROM Zone Z

    LEFT JOIN Orders O
        ON Z.zone_id = O.zone_id
       AND O.status <> 'Cancelled'
       AND CAST(O.order_date AS DATE)
            BETWEEN @from_date AND @to_date

    LEFT JOIN
    (
        SELECT
            S.order_id,
            SUM(S.total_price) * 0.10 AS commission
        FROM SubOrder S
        WHERE S.status <> 'Cancelled'
        GROUP BY S.order_id
    ) C
        ON O.order_id = C.order_id

    WHERE Z.zone_id = @zone_id
      AND @from_date IS NOT NULL
      AND @to_date IS NOT NULL
      AND @from_date <= @to_date

    GROUP BY
        Z.zone_id,
        Z.zone_name
);
GO


CREATE FUNCTION TopRiders
(
    @from_date DATE,
    @to_date DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP 5

        1 + (
            SELECT COUNT(*)
            FROM (
                SELECT
                    R2.rider_id,
                    COUNT(D2.delivery_id) AS delivery_count
                FROM Rider R2
                INNER JOIN Delivery D2
                    ON R2.rider_id = D2.rider_id
                WHERE D2.delivered_at IS NOT NULL
                  AND CAST(D2.delivered_at AS DATE)
                      BETWEEN @from_date AND @to_date
                GROUP BY R2.rider_id ) X
            WHERE X.delivery_count > T.completed_delivery_count
             OR (X.delivery_count = T.completed_delivery_count AND X.rider_id < T.rider_id) ) AS rider_rank,
        
        T.rider_id,
        T.rider_name,
        T.completed_delivery_count

    FROM (
        SELECT
            R.rider_id,
            U.first_name + ' ' + U.last_name AS rider_name,
            COUNT(D.delivery_id) AS completed_delivery_count
        FROM Rider R
        INNER JOIN Users U ON R.rider_id = U.user_id
        INNER JOIN Delivery D ON R.rider_id = D.rider_id
        WHERE D.delivered_at IS NOT NULL AND CAST(D.delivered_at AS DATE) BETWEEN @from_date AND @to_date
        GROUP BY
            R.rider_id,
            U.first_name,
            U.last_name ) T


    ORDER BY
        T.completed_delivery_count DESC,
        T.rider_id ASC
);
GO

CREATE FUNCTION Daily_Revenue_Report 
(
    @report_date DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        Z.zone_name,
        T.business_type,
        COUNT(S.suborder_id) AS number_of_suborders,
        SUM(S.total_price) AS gross_sales,
        SUM(S.delivery_fee) AS delivery_fees,
        SUM(S.total_price) * 0.10 AS platform_commission

    FROM SubOrder S
    INNER JOIN Orders O ON S.order_id = O.order_id
    INNER JOIN Business B ON S.business_id = B.business_id
    INNER JOIN Zone Z ON O.zone_id = Z.zone_id
    LEFT JOIN (
        SELECT business_id, 'Restaurant' AS business_type
        FROM Restaurant

        UNION ALL

        SELECT business_id, 'Pharmacy' AS business_type
        FROM Pharmacy ) T  ON B.business_id = T.business_id
       
    WHERE S.status <> 'Cancelled' AND CAST(O.order_date AS DATE) = @report_date

    GROUP BY Z.zone_name,T.business_type
);
GO

CREATE PROCEDURE Register_Business
    @partner_id INT,
    @name VARCHAR(100),
    @description VARCHAR(255),
    @link_website VARCHAR(255),
    @zone_id INT,
    @opening_hour TIME,
    @closing_hour TIME,
    @expected_delivery_time INT,
    @phone CHAR(11),
    @business_type VARCHAR(20),
    @cuisine_type VARCHAR(50),
    @food_category VARCHAR(50),
    @pharmacy_type VARCHAR(50)
AS
BEGIN


    IF NOT EXISTS (
        SELECT 1
        FROM Partner
        WHERE partner_id = @partner_id
    )
        RETURN -3;


    IF NOT EXISTS (
        SELECT 1
        FROM Zone
        WHERE zone_id = @zone_id
    )
        RETURN -1;


    IF @expected_delivery_time <= 0
        RETURN -1;


    IF @business_type NOT IN ('Restaurant', 'Pharmacy')
        RETURN -1;


    IF @business_type = 'Restaurant'
       AND (
            @cuisine_type IS NULL
            OR @food_category IS NULL
            OR @pharmacy_type IS NOT NULL
       )
        RETURN -1;


    IF @business_type = 'Pharmacy'
       AND (
            @pharmacy_type IS NULL
            OR @cuisine_type IS NOT NULL
            OR @food_category IS NOT NULL
       )
        RETURN -1;


    IF EXISTS (
        SELECT 1
        FROM Business
        WHERE partner_id = @partner_id
          AND status <> 'Rejected'
    )
        RETURN -2;

   
   DECLARE @business_id INT;

    IF EXISTS (
        SELECT 1
        FROM Business
        WHERE partner_id = @partner_id
          AND status = 'Rejected'
    )
    BEGIN

        SELECT @business_id = business_id
        FROM Business
        WHERE partner_id = @partner_id;


        UPDATE Business
        SET name = @name,
            description = @description,
            link_website = @link_website,
            opening_hour = @opening_hour,
            closing_hour = @closing_hour,
            expected_delivery_time = @expected_delivery_time,
            status = 'Pending',
            suspension_reason = NULL,
            zone_id = @zone_id
        WHERE business_id = @business_id;


        DELETE FROM Business_Phone
        WHERE business_id = @business_id;

        INSERT INTO Business_Phone
            (business_id, phone)
        VALUES
            (@business_id, @phone);


        DELETE FROM Restaurant
        WHERE business_id = @business_id;

        DELETE FROM Pharmacy
        WHERE business_id = @business_id;


        IF @business_type = 'Restaurant'
        BEGIN
            INSERT INTO Restaurant
                (business_id, cuisine_type, food_category)
            VALUES
                (@business_id, @cuisine_type, @food_category);
        END

        ELSE
        BEGIN
            INSERT INTO Pharmacy
                (business_id, pharmacy_type)
            VALUES
                (@business_id, @pharmacy_type);
        END

    END




    ELSE
    BEGIN

        INSERT INTO Business
            (
                name,
                description,
                link_website,
                opening_hour,
                closing_hour,
                expected_delivery_time,
                partner_id,
                zone_id
            )
        VALUES
            (
                @name,
                @description,
                @link_website,
                @opening_hour,
                @closing_hour,
                @expected_delivery_time,
                @partner_id,
                @zone_id
            );


        SET @business_id = SCOPE_IDENTITY();


        INSERT INTO Business_Phone
            (business_id, phone)
        VALUES
            (@business_id, @phone);


        IF @business_type = 'Restaurant'
        BEGIN

            INSERT INTO Restaurant
                (business_id, cuisine_type, food_category)
            VALUES
                (@business_id, @cuisine_type, @food_category);

        END

        ELSE
        BEGIN

            INSERT INTO Pharmacy
                (business_id, pharmacy_type)
            VALUES
                (@business_id, @pharmacy_type);

        END

    END;


    RETURN 0;

END;
GO


CREATE PROCEDURE Update_Business_Info
    @business_id INT,
    @opening_hour TIME,
    @closing_hour TIME,
    @phone CHAR(11),
    @link_website VARCHAR(255)
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Business
        WHERE business_id = @business_id
    )
        RETURN -1;


    UPDATE Business
    SET opening_hour = @opening_hour,
        closing_hour = @closing_hour,
        link_website = @link_website
    WHERE business_id = @business_id;

    IF EXISTS (
        SELECT 1
        FROM Business_Phone
        WHERE business_id = @business_id
          AND phone = @phone
    )
        RETURN -2;

    INSERT INTO Business_Phone
        (business_id, phone)
    VALUES
        (@business_id, @phone);


    RETURN 0;

END;
GO

CREATE PROCEDURE Upsert_Product
    @business_id INT,
    @product_id INT,
    @name VARCHAR(100),
    @description VARCHAR(255),
    @category VARCHAR(50),
    @price DECIMAL(10,2),
    @is_available BIT
AS
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM Business
        WHERE business_id = @business_id
    )
        RETURN -1;


    IF EXISTS (
        SELECT 1
        FROM Business
        WHERE business_id = @business_id
          AND status = 'Suspended'
    )
        RETURN -4;

    IF @price <= 0
        RETURN -1;


    IF @product_id IS NULL
    BEGIN

        INSERT INTO Product
            (
                name,
                description,
                category,
                price,
                is_available,
                business_id
            )
        VALUES
            (
                @name,
                @description,
                @category,
                @price,
                @is_available,
                @business_id
            );

    END



    ELSE
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM Product
            WHERE product_id = @product_id
        )
            RETURN -1;

        IF NOT EXISTS (
            SELECT 1
            FROM Product
            WHERE product_id = @product_id
              AND business_id = @business_id
        )
            RETURN -3;


        UPDATE Product
        SET name = @name,
            description = @description,
            category = @category,
            price = @price,
            is_available = @is_available
        WHERE product_id = @product_id;

    END;


    RETURN 0;

END;
GO


CREATE PROCEDURE Toggle_Product_Status
    @product_id INT,
    @is_available BIT
AS
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM Product
        WHERE product_id = @product_id
    )
        RETURN -1;


    IF @is_available = 1
       AND EXISTS (
            SELECT 1
            FROM Product P
            INNER JOIN Business B
                ON P.business_id = B.business_id
            WHERE P.product_id = @product_id
              AND B.status = 'Suspended'
       )
        RETURN -4;

    UPDATE Product
    SET is_available = @is_available
    WHERE product_id = @product_id;


    RETURN 0;

END;
GO

CREATE PROCEDURE Set_Product_Promotion
    @product_id INT,
    @discount_amount DECIMAL(10,2)
AS
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM Product
        WHERE product_id = @product_id
    )
        RETURN -1;


    IF @discount_amount < 0
        RETURN -1;
   
    IF EXISTS (
        SELECT 1
        FROM Product
        WHERE product_id = @product_id
          AND @discount_amount > price * 0.5
    )
        RETURN -1;


    UPDATE Product
    SET discount_amount = @discount_amount
    WHERE product_id = @product_id;


    RETURN 0;

END;
GO


--to be droped :
CREATE FUNCTION BusinessSalesReport
(
    @business_id INT,
    @from_date DATE,
    @to_date DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        P.product_id,
        P.name AS product_name,
        SUM(CI.quantity) AS units_sold,
        SUM(CI.quantity * CI.unit_price) AS revenue_per_product

    FROM Product P

    INNER JOIN CartItem CI
        ON P.product_id = CI.product_id

    INNER JOIN Orders O
        ON CI.cart_id = O.cart_id

    INNER JOIN SubOrder S
        ON O.order_id = S.order_id
       AND S.business_id = P.business_id

    WHERE P.business_id = @business_id
      AND S.status <> 'Cancelled'
      AND CAST(O.order_date AS DATE)
          BETWEEN @from_date AND @to_date

    GROUP BY
        P.product_id,
        P.name
);
GO


CREATE FUNCTION BusinessFeedbackOverview
(
    @business_id INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        AVG(CAST(F.rating AS DECIMAL(4,2))) AS avg_rating,
        COUNT(F.feedback_id) AS number_of_feedbacks,

        SUM(CASE WHEN F.rating = 5 THEN 1 ELSE 0 END) AS five_star,
        SUM(CASE WHEN F.rating = 4 THEN 1 ELSE 0 END) AS four_star,
        SUM(CASE WHEN F.rating = 3 THEN 1 ELSE 0 END) AS three_star,
        SUM(CASE WHEN F.rating = 2 THEN 1 ELSE 0 END) AS two_star,
        SUM(CASE WHEN F.rating = 1 THEN 1 ELSE 0 END) AS one_star

    FROM SubOrder S

    LEFT JOIN Feedback F
        ON S.suborder_id = F.suborder_id

    WHERE S.business_id = @business_id
);
GO

CREATE PROCEDURE Add_Customer_Address
    @customer_id INT,
    @description VARCHAR(150),
    @zone_id INT
AS
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM Customer
        WHERE customer_id = @customer_id
    )
        RETURN -1;

    IF NOT EXISTS (
        SELECT 1
        FROM Zone
        WHERE zone_id = @zone_id
    )
        RETURN -1;

    UPDATE Address
    SET is_active = 0
    WHERE customer_id = @customer_id;


    INSERT INTO Address
        (description, is_active, customer_id, zone_id)
    VALUES
        (@description, 1, @customer_id, @zone_id);


    RETURN 0;

END;
GO


CREATE PROCEDURE Update_Delete_Customer_Address
    @customer_id INT,
    @address_id INT,
    @description VARCHAR(150),
    @zone_id INT,
    @action VARCHAR(20)
AS
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM Address
        WHERE address_id = @address_id
          AND customer_id = @customer_id
    )
        RETURN -3;


    -- reject if this address belongs to a Placed or In Progress order
    IF EXISTS (
        SELECT 1
        FROM Cart C
        INNER JOIN Orders O
            ON C.cart_id = O.cart_id
        WHERE C.address_id = @address_id
          AND O.status IN ('Placed', 'In Progress')
    )
        RETURN -4;


    IF @action = 'Update'
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM Zone
            WHERE zone_id = @zone_id
        )
            RETURN -1;


        UPDATE Address
        SET description = @description,
            zone_id = @zone_id
        WHERE address_id = @address_id;

    END


    ELSE IF @action = 'Delete'
    BEGIN

        IF EXISTS (
            SELECT 1
            FROM Cart
            WHERE address_id = @address_id
        )
            RETURN -3;


        DELETE FROM Address
        WHERE address_id = @address_id;

    END


    ELSE
        RETURN -1;


    RETURN 0;

END;
GO


CREATE PROCEDURE Change_Active_Address
    @customer_id INT,
    @new_address_id INT
AS
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM Address
        WHERE address_id = @new_address_id
          AND customer_id = @customer_id
    )
        RETURN -3;


    UPDATE Address
    SET is_active = 0
    WHERE customer_id = @customer_id;


    UPDATE Address
    SET is_active = 1
    WHERE address_id = @new_address_id;


    RETURN 0;

END;
GO


CREATE PROCEDURE Add_Card
    @customer_id INT,
    @card_no CHAR(16),
    @card_holder_name VARCHAR(100),
    @expiration_date DATE
AS
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM Customer
        WHERE customer_id = @customer_id
    )
        RETURN -1;

    IF EXISTS (
        SELECT 1
        FROM Card
        WHERE customer_id = @customer_id
          AND card_no = @card_no
    )
        RETURN -2;


    INSERT INTO Card
        (
            card_no,
            card_holder_name,
            expiration_date,
            customer_id
        )
    VALUES
        (
            @card_no,
            @card_holder_name,
            @expiration_date,
            @customer_id
        );


    RETURN 0;

END;
GO


CREATE PROCEDURE Create_Cart
    @customer_id INT
AS
BEGIN

    DECLARE @address_id INT;

    IF NOT EXISTS (
        SELECT 1
        FROM Customer
        WHERE customer_id = @customer_id
    )
        RETURN -1;

    IF EXISTS (
        SELECT 1
        FROM Users U
        WHERE U.user_id = @customer_id
          AND U.account_status = 'Blacklisted'
    )
        RETURN -3;


    SELECT @address_id = address_id
    FROM Address
    WHERE customer_id = @customer_id
      AND is_active = 1;


    IF @address_id IS NULL
        RETURN -1;

    IF EXISTS (
        SELECT 1
        FROM Cart
        WHERE address_id = @address_id
          AND status = 'Active'
    )
        RETURN -2;
    INSERT INTO Cart
        (status, customer_id, address_id)
    VALUES
        ('Active', @customer_id, @address_id);


    RETURN 0;

END;
GO



CREATE PROCEDURE Add_To_Cart
    @cart_id INT,
    @product_id INT,
    @quantity INT,
    @notes VARCHAR(255)
AS
BEGIN

    DECLARE @customer_id INT;
    DECLARE @address_id INT;
    DECLARE @zone_id INT;
    DECLARE @old_quantity INT;


    IF NOT EXISTS (
        SELECT 1
        FROM Cart
        WHERE cart_id = @cart_id
          AND status = 'Active'
    )
        RETURN -1;

    IF NOT EXISTS (
        SELECT 1
        FROM Product
        WHERE product_id = @product_id
    )
        RETURN -1;


    IF @quantity <= 0
        RETURN -1;

    SELECT
        @customer_id = customer_id,
        @address_id = address_id
    FROM Cart
    WHERE cart_id = @cart_id;


    IF NOT EXISTS (
        SELECT 1
        FROM Address
        WHERE address_id = @address_id
          AND customer_id = @customer_id
          AND is_active = 1
    )
        RETURN -3;

    SELECT @zone_id = zone_id
    FROM Address
    WHERE address_id = @address_id;

    IF NOT EXISTS (
        SELECT 1
        FROM Product P
        INNER JOIN Business B
            ON P.business_id = B.business_id
        WHERE P.product_id = @product_id
          AND B.zone_id = @zone_id
    )
        RETURN -5;



    IF EXISTS (
        SELECT 1
        FROM CartItem
        WHERE cart_id = @cart_id
          AND product_id = @product_id
    )
    BEGIN

        SELECT @old_quantity = quantity
        FROM CartItem
        WHERE cart_id = @cart_id
          AND product_id = @product_id;
        IF @old_quantity + @quantity > 10
            RETURN -6;

        UPDATE CartItem
        SET quantity = quantity + @quantity
        WHERE cart_id = @cart_id
          AND product_id = @product_id;

        IF @notes IS NOT NULL
        BEGIN
            UPDATE CartItem
            SET notes = @notes
            WHERE cart_id = @cart_id
              AND product_id = @product_id;
        END

    END


    ELSE
    BEGIN

        IF @quantity > 10
            RETURN -6;


        INSERT INTO CartItem
            (cart_id, product_id, quantity, notes)
        VALUES
            (@cart_id, @product_id, @quantity, @notes);

    END


    RETURN 0;

END;
GO


CREATE PROCEDURE Remove_From_Cart
    @cart_id INT,
    @product_id INT
AS
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM Cart
        WHERE cart_id = @cart_id
          AND status = 'Active'
    )
        RETURN -1;

    IF NOT EXISTS (
        SELECT 1
        FROM CartItem
        WHERE cart_id = @cart_id
          AND product_id = @product_id
    )
        RETURN -1;


    DELETE FROM CartItem
    WHERE cart_id = @cart_id
      AND product_id = @product_id;


    RETURN 0;

END;
GO


--functionnnnnnnn to be dropped
CREATE FUNCTION Calculate_Voucher_Discount
(
    @voucher_id INT,
    @order_subtotal DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN

    DECLARE @discount DECIMAL(10,2);
    DECLARE @amount DECIMAL(10,2);
    DECLARE @is_percentage BIT;


    IF @voucher_id IS NULL
        RETURN 0;

    IF NOT EXISTS (
        SELECT 1
        FROM Voucher
        WHERE voucher_id = @voucher_id
          AND status = 'Unused'
          AND expiry_date >= CAST(GETDATE() AS DATE)
    )
        RETURN 0;


    SELECT
        @amount = amount,
        @is_percentage = is_percentage
    FROM Voucher
    WHERE voucher_id = @voucher_id;


    IF @is_percentage = 1
        SET @discount = @order_subtotal * @amount / 100;


    ELSE
        SET @discount = @amount;

    IF @discount > @order_subtotal
        SET @discount = @order_subtotal;


    RETURN @discount;

END;
GO

CREATE PROCEDURE Checkout_Cart
    @cart_id INT,
    @voucher_id INT,
    @payment_method VARCHAR(20),
    @card_id INT
AS
BEGIN

    DECLARE @customer_id INT;
    DECLARE @address_id INT;
    DECLARE @zone_id INT;

    DECLARE @subtotal DECIMAL(10,2);
    DECLARE @delivery_total DECIMAL(10,2);
    DECLARE @discount DECIMAL(10,2);
    DECLARE @total_amount DECIMAL(10,2);

    DECLARE @order_id INT;

    DECLARE @suborder_id INT;
    DECLARE @rider_id INT;

    DECLARE @now TIME;


    IF NOT EXISTS (
        SELECT 1
        FROM Cart
        WHERE cart_id = @cart_id
    )
        RETURN -1;


    IF NOT EXISTS (
        SELECT 1
        FROM Cart
        WHERE cart_id = @cart_id
          AND status = 'Active'
    )
        RETURN -4;



    IF NOT EXISTS (
        SELECT 1
        FROM CartItem
        WHERE cart_id = @cart_id
    )
        RETURN -9;

    SELECT
        @customer_id = customer_id,
        @address_id = address_id
    FROM Cart
    WHERE cart_id = @cart_id;


    IF EXISTS (
        SELECT 1
        FROM Users
        WHERE user_id = @customer_id
          AND account_status = 'Blacklisted'
    )
        RETURN -3;

    IF NOT EXISTS (
        SELECT 1
        FROM Address
        WHERE address_id = @address_id
          AND customer_id = @customer_id
          AND is_active = 1
    )
        RETURN -3;


    SELECT @zone_id = zone_id
    FROM Address
    WHERE address_id = @address_id;


    IF EXISTS (
        SELECT 1
        FROM CartItem CI
        INNER JOIN Product P
            ON CI.product_id = P.product_id
        WHERE CI.cart_id = @cart_id
          AND P.is_available = 0
    )
        RETURN -4;

    IF EXISTS (
        SELECT 1
        FROM CartItem CI
        INNER JOIN Product P
            ON CI.product_id = P.product_id
        INNER JOIN Business B
            ON P.business_id = B.business_id
        WHERE CI.cart_id = @cart_id
          AND B.status <> 'Active'
    )
        RETURN -4;


    IF EXISTS (
        SELECT 1
        FROM CartItem CI
        INNER JOIN Product P
            ON CI.product_id = P.product_id
        INNER JOIN Business B
            ON P.business_id = B.business_id
        WHERE CI.cart_id = @cart_id
          AND B.zone_id <> @zone_id
    )
        RETURN -5;
       

    SET @now = CAST(GETDATE() AS TIME);


    IF EXISTS (
        SELECT 1
        FROM CartItem CI
        INNER JOIN Product P
            ON CI.product_id = P.product_id
        INNER JOIN Business B
            ON P.business_id = B.business_id
        WHERE CI.cart_id = @cart_id
          AND
          (-- normal hours
          (   B.opening_hour < B.closing_hour
                  AND
                  (
                      @now < B.opening_hour
                      OR @now >= B.closing_hour
                  )
              )

              OR

              -- overnight hours
              (
                  B.opening_hour > B.closing_hour
                  AND
                  (
                      @now < B.opening_hour
                      AND @now >= B.closing_hour
                  )
              )
          )
    )
        RETURN -4;




    IF @voucher_id IS NOT NULL
       AND NOT EXISTS (
            SELECT 1
            FROM Voucher
            WHERE voucher_id = @voucher_id
              AND customer_id = @customer_id
              AND status = 'Unused'
              AND expiry_date >= CAST(GETDATE() AS DATE)
       )
        RETURN -1;



    IF @payment_method NOT IN ('Cash', 'Card', 'Wallet')
        RETURN -1;

    IF @payment_method = 'Card'
    BEGIN

        IF @card_id IS NULL
            RETURN -7;

        IF NOT EXISTS (
            SELECT 1
            FROM Card
            WHERE card_id = @card_id
              AND customer_id = @customer_id
              AND expiration_date >= CAST(GETDATE() AS DATE)
        )
            RETURN -7;

    END


    -- Cash should pay all in cash
    ELSE IF @card_id IS NOT NULL
        RETURN -7;


    --  CALCULATE PRICES BEFORE CHANGING ANYTHING
    SELECT @subtotal =
        SUM(CI.quantity * (P.price - P.discount_amount))
    FROM CartItem CI
    INNER JOIN Product P
        ON CI.product_id = P.product_id
    WHERE CI.cart_id = @cart_id;


    SELECT @delivery_total =
        COUNT(DISTINCT P.business_id) * Z.delivery_fee
    FROM CartItem CI
    INNER JOIN Product P
        ON CI.product_id = P.product_id
    INNER JOIN Zone Z
        ON Z.zone_id = @zone_id
    WHERE CI.cart_id = @cart_id
    GROUP BY Z.delivery_fee;


    SET @discount =
       dbo.Calculate_Voucher_Discount(
            @voucher_id,
            @subtotal
        );


    SET @total_amount =
        @subtotal
        + @delivery_total
        - @discount;


    IF @payment_method = 'Wallet'
       AND NOT EXISTS (
            SELECT 1
            FROM Customer
            WHERE customer_id = @customer_id
              AND wallet_balance >= @total_amount
       )
        RETURN -7;


    BEGIN TRANSACTION;

    UPDATE CI
    SET CI.unit_price =
        P.price - P.discount_amount
    FROM CartItem CI
    INNER JOIN Product P
        ON CI.product_id = P.product_id
    WHERE CI.cart_id = @cart_id;


    INSERT INTO Orders
    (
        order_date,
        status,
        discount_amount,
        total_amount,
        cart_id,
        zone_id,
        voucher_id
    )
    VALUES
    (
        GETDATE(),
        'Placed',
        @discount,
        @total_amount,
        @cart_id,
        @zone_id,
        @voucher_id
    );


    SET @order_id = SCOPE_IDENTITY();


    INSERT INTO SubOrder
    (
        status,
        total_price,
        delivery_fee,
        order_id,
        business_id
    )

    SELECT
        'Placed',
        SUM(CI.quantity * CI.unit_price),
        Z.delivery_fee,
        @order_id,
        P.business_id

    FROM CartItem CI

    INNER JOIN Product P
        ON CI.product_id = P.product_id

    INNER JOIN Zone Z
        ON Z.zone_id = @zone_id

    WHERE CI.cart_id = @cart_id

    GROUP BY
        P.business_id,
        Z.delivery_fee;



    WHILE EXISTS (
        SELECT 1
        FROM SubOrder S
        WHERE S.order_id = @order_id
          AND NOT EXISTS (
              SELECT 1
              FROM Delivery D
              WHERE D.suborder_id = S.suborder_id
          )
    )

    BEGIN

        SET @suborder_id = NULL;
        SET @rider_id = NULL;


        SELECT TOP 1
            @suborder_id = suborder_id
        FROM SubOrder
        WHERE order_id = @order_id
          AND NOT EXISTS (
              SELECT 1
              FROM Delivery
              WHERE Delivery.suborder_id =
                    SubOrder.suborder_id
          )
        ORDER BY suborder_id;


        SELECT TOP 1
            @rider_id = R.rider_id
        FROM Rider R

        INNER JOIN Users U
            ON R.rider_id = U.user_id

        LEFT JOIN Delivery D
            ON R.rider_id = D.rider_id

        LEFT JOIN SubOrder S
            ON D.suborder_id = S.suborder_id
           AND S.status IN ('Assigned', 'Picked Up')

        WHERE R.zone_id = @zone_id
          AND R.is_available = 1
          AND U.account_status = 'Active'

        GROUP BY R.rider_id

        ORDER BY
            COUNT(S.suborder_id),
            R.rider_id;

        IF @rider_id IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN -8;
        END;


        INSERT INTO Delivery
        (
            assigned_at,
            suborder_id,
            rider_id
        )
        VALUES
        (
            GETDATE(),
            @suborder_id,
            @rider_id
        );


        UPDATE SubOrder
        SET status = 'Assigned'
        WHERE suborder_id = @suborder_id;

    END

    IF @voucher_id IS NOT NULL
    BEGIN

        UPDATE Voucher
        SET status = 'Used'
        WHERE voucher_id = @voucher_id;

    END

    INSERT INTO Payment
    (
        amount,
        currency,
        method,
        transaction_date,
        refunded_amount,
        order_id,
        card_id
    )
    VALUES
    (
        @total_amount,
        'EGP',
        @payment_method,
        GETDATE(),
        0,
        @order_id,
        @card_id
    );

    IF @payment_method = 'Wallet'
    BEGIN

        UPDATE Customer
        SET wallet_balance =
            wallet_balance - @total_amount
        WHERE customer_id = @customer_id;

    END

    UPDATE Cart
    SET status = 'Checked Out'
    WHERE cart_id = @cart_id;


    COMMIT TRANSACTION;


    RETURN 0;

END;
GO

CREATE PROCEDURE Cancel_Order
    @order_id INT
AS
BEGIN

    DECLARE @customer_id INT;
    DECLARE @voucher_id INT;
    DECLARE @method VARCHAR(20);
    DECLARE @refund DECIMAL(10,2);


    IF NOT EXISTS (
        SELECT 1
        FROM Orders
        WHERE order_id = @order_id
    )
        RETURN -1;


    IF EXISTS (
        SELECT 1
        FROM Orders
        WHERE order_id = @order_id
          AND status = 'Cancelled'
    )
        RETURN -4;


    IF EXISTS (
        SELECT 1
        FROM SubOrder
        WHERE order_id = @order_id
          AND status IN ('Picked Up', 'Delivered')
    )
        RETURN -4;


    SELECT @customer_id = CT.customer_id,
           @voucher_id = O.voucher_id
    FROM Orders O
    INNER JOIN Cart CT
        ON O.cart_id = CT.cart_id
    WHERE O.order_id = @order_id;


    SELECT @refund = amount - refunded_amount,
           @method = method
    FROM Payment
    WHERE order_id = @order_id;


    IF @method <> 'Cash' AND @refund > 0
        UPDATE Customer
        SET wallet_balance = wallet_balance + @refund
        WHERE customer_id = @customer_id;


    UPDATE Payment
    SET refunded_amount = amount
    WHERE order_id = @order_id;


    UPDATE SubOrder
    SET status = 'Cancelled'
    WHERE order_id = @order_id
      AND status <> 'Cancelled';


    UPDATE Orders
    SET status = 'Cancelled',
        voucher_id = NULL
    WHERE order_id = @order_id;


    IF @voucher_id IS NOT NULL
        UPDATE Voucher
        SET status = 'Unused'
        WHERE voucher_id = @voucher_id;

    RETURN 0;
END;
GO

CREATE PROCEDURE Reorder
    @order_id INT,
    @address_id INT
AS
BEGIN

    DECLARE @customer_id INT;
    DECLARE @old_cart_id INT;
    DECLARE @order_zone INT;
    DECLARE @new_cart_id INT;

    IF NOT EXISTS (
        SELECT 1
        FROM Orders
        WHERE order_id = @order_id
    )
        RETURN -1;

    SELECT @customer_id = CT.customer_id,
           @old_cart_id = O.cart_id,
           @order_zone = O.zone_id
    FROM Orders O
    INNER JOIN Cart CT
        ON O.cart_id = CT.cart_id
    WHERE O.order_id = @order_id;

    IF EXISTS (
        SELECT 1
        FROM Users
        WHERE user_id = @customer_id
          AND account_status = 'Blacklisted'
    )
        RETURN -3;

    IF NOT EXISTS (
        SELECT 1
        FROM Address
        WHERE address_id = @address_id
          AND customer_id = @customer_id
    )
        RETURN -3;

    IF NOT EXISTS (
        SELECT 1
        FROM Address
        WHERE address_id = @address_id
          AND zone_id = @order_zone
    )
        RETURN -5;

    IF EXISTS (
        SELECT 1
        FROM Cart
        WHERE address_id = @address_id
          AND status = 'Active'
    )
        RETURN -2;


    IF NOT EXISTS (
        SELECT 1
        FROM CartItem CI
        INNER JOIN Product P
            ON CI.product_id = P.product_id
        INNER JOIN Business B
            ON P.business_id = B.business_id
        WHERE CI.cart_id = @old_cart_id
          AND P.is_available = 1
          AND B.status = 'Active'
    )
        RETURN -9;


    UPDATE Address
    SET is_active = 0
    WHERE customer_id = @customer_id;

    UPDATE Address
    SET is_active = 1
    WHERE address_id = @address_id;

    INSERT INTO Cart
        (status, customer_id, address_id)
    VALUES
        ('Active', @customer_id, @address_id);

    SET @new_cart_id = SCOPE_IDENTITY();


    INSERT INTO CartItem
        (cart_id, product_id, quantity, notes)
    SELECT
        @new_cart_id,
        CI.product_id,
        CI.quantity,
        CI.notes
    FROM CartItem CI
    INNER JOIN Product P
        ON CI.product_id = P.product_id
    INNER JOIN Business B
        ON P.business_id = B.business_id
    WHERE CI.cart_id = @old_cart_id
      AND P.is_available = 1
      AND B.status = 'Active';


    RETURN 0;
END;
GO

CREATE PROCEDURE Submit_Feedback
    @suborder_id INT,
    @headline VARCHAR(100),
    @description VARCHAR(500),
    @rating INT
AS
BEGIN

    IF @headline IS NULL OR @rating IS NULL
       OR @rating < 1 OR @rating > 5
        RETURN -1;

    IF NOT EXISTS (
        SELECT 1
        FROM SubOrder
        WHERE suborder_id = @suborder_id
    )
        RETURN -1;

    IF NOT EXISTS (
        SELECT 1
        FROM SubOrder
        WHERE suborder_id = @suborder_id
          AND status = 'Delivered'
    )
        RETURN -4;

    IF EXISTS (
        SELECT 1
        FROM Feedback
        WHERE suborder_id = @suborder_id
    )
        RETURN -2;


    INSERT INTO Feedback
        (headline, description, rating, suborder_id)
    VALUES
        (@headline, @description, @rating, @suborder_id);


    RETURN 0;
END;
GO

CREATE PROCEDURE Rate_Rider
    @suborder_id INT,
    @rider_rating INT
AS
BEGIN

    IF @rider_rating IS NULL
       OR @rider_rating < 1 OR @rider_rating > 5
        RETURN -1;

    IF NOT EXISTS (
        SELECT 1
        FROM SubOrder
        WHERE suborder_id = @suborder_id
    )
        RETURN -1;

    IF NOT EXISTS (
        SELECT 1
        FROM SubOrder
        WHERE suborder_id = @suborder_id
          AND status = 'Delivered'
    )
        RETURN -4;

    IF EXISTS (
        SELECT 1
        FROM Delivery
        WHERE suborder_id = @suborder_id
          AND rider_rating IS NOT NULL
    )
        RETURN -2;


    UPDATE Delivery
    SET rider_rating = @rider_rating
    WHERE suborder_id = @suborder_id;


    RETURN 0;
END;
GO

CREATE FUNCTION My_Order_History
(
    @customer_id INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        O.order_id,
        O.order_date,
        Z.zone_name,
        O.status,
        COUNT(S.suborder_id) AS number_of_suborders,
        O.discount_amount,
        O.total_amount,
        P.method AS payment_method,
        P.refunded_amount

    FROM Orders O

    INNER JOIN Cart CT
        ON O.cart_id = CT.cart_id

    INNER JOIN Zone Z
        ON O.zone_id = Z.zone_id

    LEFT JOIN Payment P
        ON O.order_id = P.order_id

    LEFT JOIN SubOrder S
        ON O.order_id = S.order_id

    WHERE CT.customer_id = @customer_id

    GROUP BY
        O.order_id,
        O.order_date,
        Z.zone_name,
        O.status,
        O.discount_amount,
        O.total_amount,
        P.method,
        P.refunded_amount
);
GO

CREATE PROCEDURE Toggle_Favorite
    @customer_id INT,
    @item_id INT,
    @item_type VARCHAR(20)
AS
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM Customer
        WHERE customer_id = @customer_id
    )
        RETURN -1;

    IF @item_type <> 'Business' AND @item_type <> 'Product'
        RETURN -1;


    IF @item_type = 'Business'
    BEGIN

        IF NOT EXISTS (
            SELECT 1
            FROM Business
            WHERE business_id = @item_id
        )
            RETURN -1;

        -- already a favorite so remove it
        IF EXISTS (
            SELECT 1
            FROM Favorite_Business
            WHERE customer_id = @customer_id
              AND business_id = @item_id
        )
            DELETE FROM Favorite_Business
            WHERE customer_id = @customer_id
              AND business_id = @item_id;

        -- not a favorite so add it
        ELSE
            INSERT INTO Favorite_Business (customer_id, business_id)
            VALUES (@customer_id, @item_id);

    END

    ELSE
    BEGIN

        IF NOT EXISTS (
            SELECT 1
            FROM Product
            WHERE product_id = @item_id
        )
            RETURN -1;

        -- already a favorite so remove it
        IF EXISTS (
            SELECT 1
            FROM Favorite_Product
            WHERE customer_id = @customer_id
              AND product_id = @item_id
        )
            DELETE FROM Favorite_Product
            WHERE customer_id = @customer_id
              AND product_id = @item_id;

        -- not a favorite so add it
        ELSE
            INSERT INTO Favorite_Product (customer_id, product_id)
            VALUES (@customer_id, @item_id);

    END


    RETURN 0;
END;
GO

CREATE FUNCTION My_Favorites
(
    @customer_id INT
)
RETURNS TABLE
AS
RETURN
(
    -- favorites that can be ordered
    SELECT
        P.product_id,
        P.name AS product_name,
        B.name AS business_name,
        1 AS is_orderable
    FROM Favorite_Product F
    INNER JOIN Product P
        ON F.product_id = P.product_id
    INNER JOIN Business B
        ON P.business_id = B.business_id
    WHERE F.customer_id = @customer_id
      AND P.is_available = 1
      AND B.status = 'Active'

    UNION ALL

    -- favorites that can't be ordered
    SELECT
        P.product_id,
        P.name,
        B.name,
        0
    FROM Favorite_Product F
    INNER JOIN Product P
        ON F.product_id = P.product_id
    INNER JOIN Business B
        ON P.business_id = B.business_id
    WHERE F.customer_id = @customer_id
      AND (P.is_available = 0 OR B.status <> 'Active')
);
GO

CREATE FUNCTION Recommended_Products ( @customer_id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP 10
        P.product_id,
        P.name AS product_name,
        B.name AS business_name,
        P.category,
        P.price - P.discount_amount AS final_price

    FROM Product P

    INNER JOIN Business B ON P.business_id = B.business_id
    INNER JOIN Address A ON B.zone_id = A.zone_id

    WHERE A.customer_id = @customer_id
      AND A.is_active = 1
      AND P.is_available = 1
      AND B.status = 'Active'
      AND EXISTS (
          SELECT 1
          FROM CartItem CI
          INNER JOIN Cart C ON CI.cart_id = C.cart_id
          INNER JOIN Orders O ON C.cart_id = O.cart_id
          INNER JOIN Product P2 ON CI.product_id = P2.product_id
          WHERE C.customer_id = @customer_id AND P2.category = P.category
      )
      AND NOT EXISTS (
          SELECT 1
          FROM CartItem CI
          INNER JOIN Cart C ON CI.cart_id = C.cart_id
          INNER JOIN Orders O ON C.cart_id = O.cart_id
          WHERE C.customer_id = @customer_id AND CI.product_id = P.product_id
      )

    ORDER BY
        (
            SELECT SUM(CI2.quantity)
            FROM CartItem CI2
            INNER JOIN Cart C2 ON CI2.cart_id = C2.cart_id
            INNER JOIN Orders O2 ON C2.cart_id = O2.cart_id
            INNER JOIN Product P2 ON CI2.product_id = P2.product_id
            WHERE C2.customer_id = @customer_id AND P2.category = P.category
        ) DESC,
        P.product_id ASC
);
GO

CREATE PROCEDURE Set_Rider_Availability
    @rider_id INT,
    @is_available BIT
AS
BEGIN
    IF @rider_id IS NULL OR @is_available IS NULL
        RETURN -1;

    IF NOT EXISTS (
        SELECT 1
        FROM Rider
        WHERE rider_id = @rider_id
    )
        RETURN -1;
    UPDATE Rider
    SET is_available = @is_available
    WHERE rider_id = @rider_id;


    RETURN 0;
END;
GO


CREATE FUNCTION My_Active_Deliveries ( @rider_id INT )
RETURNS TABLE
AS
RETURN
(
    SELECT
        D.delivery_id,
        S.order_id,
        S.suborder_id,
        B.name AS business_name,
        U.first_name + ' ' + U.last_name AS customer_name,
        A.description AS address_description,
        Z.zone_name,
        S.status,
        D.assigned_at

    FROM Delivery D
    INNER JOIN SubOrder S ON D.suborder_id = S.suborder_id
    INNER JOIN Business B ON S.business_id = B.business_id
    INNER JOIN Orders O ON S.order_id = O.order_id
    INNER JOIN Cart CT ON O.cart_id = CT.cart_id
    INNER JOIN Users U ON CT.customer_id = U.user_id
    INNER JOIN Address A ON CT.address_id = A.address_id
    INNER JOIN Zone Z ON O.zone_id = Z.zone_id
     WHERE D.rider_id = @rider_id AND S.status IN ('Assigned', 'Picked Up')
);
GO

CREATE PROCEDURE Mark_Picked_Up
    @delivery_id INT
AS
BEGIN

    DECLARE @suborder_id INT;
    DECLARE @order_id INT;

    IF NOT EXISTS (
        SELECT 1
        FROM Delivery
        WHERE delivery_id = @delivery_id
    )
        RETURN -1;

    SELECT @suborder_id = D.suborder_id,
           @order_id = S.order_id
    FROM Delivery D
    INNER JOIN SubOrder S
        ON D.suborder_id = S.suborder_id
    WHERE D.delivery_id = @delivery_id;

    IF NOT EXISTS (
        SELECT 1
        FROM SubOrder
        WHERE suborder_id = @suborder_id
          AND status = 'Assigned'
    )
        RETURN -4;

    UPDATE SubOrder
    SET status = 'Picked Up'
    WHERE suborder_id = @suborder_id;

    UPDATE Delivery
    SET picked_up_at = GETDATE()
    WHERE delivery_id = @delivery_id;

    UPDATE Orders
    SET status = 'In Progress'
    WHERE order_id = @order_id;

    RETURN 0;
END;
GO

