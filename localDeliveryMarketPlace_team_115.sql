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
aaccount_status VARCHAR(20) NOT NULL DEFAULT 'Active'
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
    SET status = 'Reject'
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


    UPDATE C
    SET wallet_balance =
        wallet_balance + (P.amount - P.refunded_amount)
    FROM Customer C
    INNER JOIN Cart CT
        ON C.customer_id = CT.customer_id
    INNER JOIN Orders O
        ON CT.cart_id = O.cart_id
    INNER JOIN Payment P
        ON O.order_id = P.order_id
    WHERE C.customer_id = @customer_id
      AND O.status <> 'Cancelled'
      AND P.method <> 'Cash'

      AND NOT EXISTS (
          SELECT 1
          FROM SubOrder S
          WHERE S.order_id = O.order_id
            AND S.status IN ('Picked Up', 'Delivered')
      );
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
            FROM
            (
                SELECT
                    R2.rider_id,
                    COUNT(D2.delivery_id) AS delivery_count
                FROM Rider R2
                INNER JOIN Delivery D2
                    ON R2.rider_id = D2.rider_id
                WHERE D2.delivered_at IS NOT NULL
                  AND CAST(D2.delivered_at AS DATE)
                      BETWEEN @from_date AND @to_date
                GROUP BY R2.rider_id
            ) X

            WHERE X.delivery_count > T.completed_delivery_count

               OR (
                    X.delivery_count = T.completed_delivery_count
                    AND X.rider_id < T.rider_id
                  )

        ) AS rider_rank,

        T.rider_id,
        T.rider_name,
        T.completed_delivery_count

    FROM
    (
        SELECT
            R.rider_id,
            U.first_name + ' ' + U.last_name AS rider_name,
            COUNT(D.delivery_id) AS completed_delivery_count

        FROM Rider R

        INNER JOIN Users U
            ON R.rider_id = U.user_id

        INNER JOIN Delivery D
            ON R.rider_id = D.rider_id

        WHERE D.delivered_at IS NOT NULL
          AND CAST(D.delivered_at AS DATE)
              BETWEEN @from_date AND @to_date

        GROUP BY
            R.rider_id,
            U.first_name,
            U.last_name

    ) T

    ORDER BY
        T.completed_delivery_count DESC,
        T.rider_id ASC
);
GO