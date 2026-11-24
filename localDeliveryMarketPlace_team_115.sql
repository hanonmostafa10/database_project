-- 4.1.a create database
CREATE DATABASE LocalDeliveryMarketplace_Team_00;
GO
USE LocalDeliveryMarketplace_Team_00;
GO

-- 4.1.b createAllTables
CREATE PROCEDURE createAllTables
AS
BEGIN

    CREATE TABLE Zone (
        zone_id INT IDENTITY(1,1) PRIMARY KEY,
        zone_name VARCHAR(50) NOT NULL UNIQUE,
        delivery_fee DECIMAL(10,2) NOT NULL CHECK (delivery_fee >= 0)
    );

    CREATE TABLE Users (
        user_id INT IDENTITY(1,1) PRIMARY KEY,
        first_name VARCHAR(30) NOT NULL,
        middle_name VARCHAR(30) NULL,
        last_name VARCHAR(30) NOT NULL,
        username VARCHAR(30) NOT NULL UNIQUE,
        password VARCHAR(30) NOT NULL,
        email VARCHAR(100) NOT NULL UNIQUE,
        dob DATE NULL,
        account_status VARCHAR(20) NOT NULL DEFAULT 'Active'
    );

    CREATE TABLE User_Phone (
        user_id INT NOT NULL REFERENCES Users(user_id),
        phone CHAR(11) NOT NULL,
        PRIMARY KEY (user_id, phone)
    );

    CREATE TABLE Admin (
        admin_id INT PRIMARY KEY REFERENCES Users(user_id),
        role VARCHAR(20) NOT NULL DEFAULT 'Super Admin',
        zone_id INT NULL REFERENCES Zone(zone_id)
    );

    CREATE TABLE Partner (
        partner_id INT PRIMARY KEY REFERENCES Users(user_id)
    );

    CREATE TABLE Rider (
        rider_id INT PRIMARY KEY REFERENCES Users(user_id),
        vehicle_type VARCHAR(30) NOT NULL,
        plate_no VARCHAR(15) NOT NULL UNIQUE,
        license_no VARCHAR(20) NOT NULL UNIQUE,
        is_available BIT NOT NULL DEFAULT 1,
        zone_id INT NOT NULL REFERENCES Zone(zone_id)
    );

    CREATE TABLE Customer (
        customer_id INT PRIMARY KEY REFERENCES Users(user_id),
        wallet_balance DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (wallet_balance >= 0)
    );

    CREATE TABLE Address (
        address_id INT IDENTITY(1,1) PRIMARY KEY,
        description VARCHAR(150) NOT NULL,
        is_active BIT NOT NULL DEFAULT 1,
        customer_id INT NOT NULL REFERENCES Customer(customer_id),
        zone_id INT NOT NULL REFERENCES Zone(zone_id)
    );

    CREATE TABLE Card (
        card_id INT IDENTITY(1,1) PRIMARY KEY,
        card_no CHAR(16) NOT NULL,
        card_holder_name VARCHAR(100) NOT NULL,
        expiration_date DATE NOT NULL,
        customer_id INT NOT NULL REFERENCES Customer(customer_id),
        UNIQUE (customer_id, card_no)
    );

    CREATE TABLE Business (
        business_id INT IDENTITY(1,1) PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        description VARCHAR(255) NULL,
        link_website VARCHAR(255) NULL,
        opening_hour TIME NOT NULL,
        closing_hour TIME NOT NULL,
        expected_delivery_time INT NOT NULL CHECK (expected_delivery_time > 0),
        status VARCHAR(20) NOT NULL DEFAULT 'Pending',
        suspension_reason VARCHAR(255) NULL,
        partner_id INT NOT NULL UNIQUE REFERENCES Partner(partner_id),
        zone_id INT NOT NULL REFERENCES Zone(zone_id)
    );

    CREATE TABLE Business_Phone (
        business_id INT NOT NULL REFERENCES Business(business_id),
        phone CHAR(11) NOT NULL,
        PRIMARY KEY (business_id, phone)
    );

    CREATE TABLE Restaurant (
        business_id INT PRIMARY KEY REFERENCES Business(business_id),
        cuisine_type VARCHAR(50) NOT NULL,
        food_category VARCHAR(50) NOT NULL
    );

    CREATE TABLE Pharmacy (
        business_id INT PRIMARY KEY REFERENCES Business(business_id),
        pharmacy_type VARCHAR(50) NOT NULL
    );

    CREATE TABLE Blacklist (
        customer_id INT PRIMARY KEY REFERENCES Customer(customer_id),
        admin_id INT NOT NULL REFERENCES Admin(admin_id),
        reason VARCHAR(255) NOT NULL
    );

    CREATE TABLE Product (
        product_id INT IDENTITY(1,1) PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        description VARCHAR(255) NULL,
        category VARCHAR(50) NOT NULL,
        price DECIMAL(10,2) NOT NULL CHECK (price > 0),
        discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
        is_available BIT NOT NULL DEFAULT 1,
        business_id INT NOT NULL REFERENCES Business(business_id),
        CHECK (discount_amount >= 0 AND discount_amount <= 0.5 * price)
    );

    CREATE TABLE Favorite_Business (
        customer_id INT NOT NULL REFERENCES Customer(customer_id),
        business_id INT NOT NULL REFERENCES Business(business_id),
        PRIMARY KEY (customer_id, business_id)
    );

    CREATE TABLE Favorite_Product (
        customer_id INT NOT NULL REFERENCES Customer(customer_id),
        product_id INT NOT NULL REFERENCES Product(product_id),
        PRIMARY KEY (customer_id, product_id)
    );

    CREATE TABLE Voucher (
        voucher_id INT IDENTITY(1,1) PRIMARY KEY,
        promo_code VARCHAR(30) NOT NULL UNIQUE,
        is_percentage BIT NOT NULL,
        amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
        expiry_date DATE NOT NULL,
        status VARCHAR(20) NOT NULL DEFAULT 'Unused',
        customer_id INT NOT NULL REFERENCES Customer(customer_id)
    );

    CREATE TABLE Cart (
        cart_id INT IDENTITY(1,1) PRIMARY KEY,
        status VARCHAR(20) NOT NULL DEFAULT 'Active',
        created_at DATETIME NOT NULL DEFAULT GETDATE(),
        customer_id INT NOT NULL REFERENCES Customer(customer_id),
        address_id INT NOT NULL REFERENCES Address(address_id)
    );

    CREATE TABLE CartItem (
        cart_id INT NOT NULL REFERENCES Cart(cart_id),
        product_id INT NOT NULL REFERENCES Product(product_id),
        quantity INT NOT NULL CHECK (quantity BETWEEN 1 AND 10),
        notes VARCHAR(255) NULL,
        unit_price DECIMAL(10,2) NULL,
        PRIMARY KEY (cart_id, product_id)
    );

    CREATE TABLE Orders (
        order_id INT IDENTITY(1,1) PRIMARY KEY,
        order_date DATETIME NOT NULL,
        status VARCHAR(20) NOT NULL DEFAULT 'Placed',
        discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
        total_amount DECIMAL(10,2) NOT NULL,
        cart_id INT NOT NULL UNIQUE REFERENCES Cart(cart_id),
        zone_id INT NOT NULL REFERENCES Zone(zone_id),
        voucher_id INT NULL REFERENCES Voucher(voucher_id)
    );

    CREATE TABLE SubOrder (
        suborder_id INT IDENTITY(1,1) PRIMARY KEY,
        status VARCHAR(20) NOT NULL DEFAULT 'Placed',
        total_price DECIMAL(10,2) NOT NULL,
        delivery_fee DECIMAL(10,2) NOT NULL,
        order_id INT NOT NULL REFERENCES Orders(order_id),
        business_id INT NOT NULL REFERENCES Business(business_id),
        UNIQUE (order_id, business_id)
    );

    CREATE TABLE Delivery (
        delivery_id INT IDENTITY(1,1) PRIMARY KEY,
        assigned_at DATETIME NOT NULL,
        picked_up_at DATETIME NULL,
        delivered_at DATETIME NULL,
        tracking_time INT NULL,
        rider_rating INT NULL CHECK (rider_rating BETWEEN 1 AND 5),
        suborder_id INT NOT NULL UNIQUE REFERENCES SubOrder(suborder_id),
        rider_id INT NOT NULL REFERENCES Rider(rider_id)
    );

    CREATE TABLE Payment (
        payment_id INT IDENTITY(1,1) PRIMARY KEY,
        amount DECIMAL(10,2) NOT NULL,
        currency VARCHAR(3) NOT NULL DEFAULT 'EGP',
        method VARCHAR(20) NOT NULL,
        transaction_date DATETIME NOT NULL,
        refunded_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
        order_id INT NOT NULL UNIQUE REFERENCES Orders(order_id),
        card_id INT NULL REFERENCES Card(card_id),
        CHECK (refunded_amount <= amount)
    );

    CREATE TABLE Feedback (
        feedback_id INT IDENTITY(1,1) PRIMARY KEY,
        headline VARCHAR(100) NOT NULL,
        description VARCHAR(500) NULL,
        rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
        feedback_date DATETIME NOT NULL DEFAULT GETDATE(),
        suborder_id INT NOT NULL UNIQUE REFERENCES SubOrder(suborder_id)
    );
END;
GO

-- 4.1.c dropAllTables
create procedure dropAllTables
as
begin
    drop table Feedback;
    drop table Payment;
    drop table Delivery;
    drop table SubOrder;
    drop table Orders;
    drop table CartItem;
    drop table Cart;
    drop table Voucher;
    drop table Favorite_Product;
    drop table Favorite_Business;
    drop table Product;
    drop table Blacklist;
    drop table Pharmacy;
    drop table Restaurant;
    drop table Business_Phone;
    drop table Business;
    drop table Card;
    drop table Address;
    drop table Customer;
    drop table Rider;
    drop table Partner;
    drop table Admin;
    drop table User_Phone;
    drop table Users;
    drop table Zone;
end;
GO

-- 4.1.d dropAllProceduresFunctionsViews
CREATE PROCEDURE dropAllProceduresFunctionsViews
AS
BEGIN

    DROP VIEW allBusinessProfiles;
    DROP VIEW BusinessesPerZone;
    DROP VIEW BusinessRatingsSummary;
    DROP VIEW ActiveVouchers;
    DROP VIEW PendingBusinessApprovals;
    DROP VIEW RiderPerformanceSummary;
    DROP VIEW TopSellingProducts;
    DROP VIEW ZoneDeliveryPerformance;
    DROP VIEW h_ZoneList;
    DROP VIEW h_AdminList;
    DROP VIEW h_CustomerList;
    DROP VIEW h_BlacklistedCustomers;
    DROP VIEW h_SuspendedBusinesses;

    DROP FUNCTION h_IsBusinessOpen;
    DROP FUNCTION h_IsSuperAdmin;
    DROP FUNCTION h_AdminCanManageBusiness;
    DROP FUNCTION h_AdminCanManageCustomer;
    DROP FUNCTION h_ActiveAddress;
    DROP FUNCTION h_LeastBusyRider;
    DROP FUNCTION CustomerLoginValidation;
    DROP FUNCTION PartnerLoginValidation;
    DROP FUNCTION RiderLoginValidation;
    DROP FUNCTION AdminLoginValidation;
    DROP FUNCTION ZoneOrderReport;
    DROP FUNCTION TopRiders;
    DROP FUNCTION Daily_Revenue_Report;
    DROP FUNCTION BusinessSalesReport;
    DROP FUNCTION BusinessFeedbackOverview;
    DROP FUNCTION Calculate_Voucher_Discount;
    DROP FUNCTION My_Order_History;
    DROP FUNCTION My_Favorites;
    DROP FUNCTION Recommended_Products;
    DROP FUNCTION My_Active_Deliveries;
    DROP FUNCTION My_Earnings;
    DROP FUNCTION My_Rating_Summary;
    DROP FUNCTION My_Delivery_History;
    DROP FUNCTION Search_Platform;
    DROP FUNCTION Reconcile_Order_Totals;
    DROP FUNCTION Nearby_Businesses_By_Category;
    DROP FUNCTION Platform_Health_Snapshot;
    DROP FUNCTION h_GetUserId;
    DROP FUNCTION h_AdminProfile;
    DROP FUNCTION h_MyBusiness;
    DROP FUNCTION h_BusinessPhones;
    DROP FUNCTION h_MyProducts;
    DROP FUNCTION h_RiderProfile;
    DROP FUNCTION h_CustomerProfile;
    DROP FUNCTION h_MyAddresses;
    DROP FUNCTION h_MyCards;
    DROP FUNCTION h_MyActiveCart;
    DROP FUNCTION h_CartItems;
    DROP FUNCTION h_MyVouchers;
    DROP FUNCTION h_BusinessDetails;
    DROP FUNCTION h_BusinessProducts;
    DROP FUNCTION h_OrderSubOrders;

    DROP PROCEDURE createAllTables;
    DROP PROCEDURE dropAllTables;
    DROP PROCEDURE h_RecomputeOrderStatus;
    DROP PROCEDURE h_RefundOrder;
    DROP PROCEDURE h_RestoreVoucherIfCancelled;
    DROP PROCEDURE h_CancelOrder;
    DROP PROCEDURE h_CancelSubOrder;
    DROP PROCEDURE h_SetActiveAddress;
    DROP PROCEDURE h_ValidateAccount;
    DROP PROCEDURE h_CreateUser;
    DROP PROCEDURE Customer_Register;
    DROP PROCEDURE Partner_Register;
    DROP PROCEDURE Rider_Register;
    DROP PROCEDURE Change_Password;
    DROP PROCEDURE Create_Admin;
    DROP PROCEDURE Approve_Business;
    DROP PROCEDURE Reject_Business;
    DROP PROCEDURE Suspend_Business;
    DROP PROCEDURE Reinstate_Business;
    DROP PROCEDURE Create_Zone;
    DROP PROCEDURE Update_Zone_Fee;
    DROP PROCEDURE Assign_Admin_Zone;
    DROP PROCEDURE Issue_Voucher;
    DROP PROCEDURE Blacklist_Customer;
    DROP PROCEDURE Lift_Customer_Blacklist;
    DROP PROCEDURE Register_Business;
    DROP PROCEDURE Update_Business_Info;
    DROP PROCEDURE Upsert_Product;
    DROP PROCEDURE Toggle_Product_Status;
    DROP PROCEDURE Set_Product_Promotion;
    DROP PROCEDURE Add_Customer_Address;
    DROP PROCEDURE Update_Delete_Customer_Address;
    DROP PROCEDURE Change_Active_Address;
    DROP PROCEDURE Add_Card;
    DROP PROCEDURE Create_Cart;
    DROP PROCEDURE Add_To_Cart;
    DROP PROCEDURE Remove_From_Cart;
    DROP PROCEDURE h_AssignRiders;
    DROP PROCEDURE Checkout_Cart;
    DROP PROCEDURE Cancel_Order;
    DROP PROCEDURE Reorder;
    DROP PROCEDURE Submit_Feedback;
    DROP PROCEDURE Rate_Rider;
    DROP PROCEDURE Toggle_Favorite;
    DROP PROCEDURE Set_Rider_Availability;
    DROP PROCEDURE Mark_Picked_Up;
    DROP PROCEDURE Mark_Delivered;
END;
GO

EXEC createAllTables;
GO

-- h_IsBusinessOpen
CREATE FUNCTION h_IsBusinessOpen (@opening TIME, @closing TIME, @now TIME)
RETURNS BIT
as
BEGIN
    IF @opening = @closing RETURN 1;
    IF @opening < @closing
        RETURN CASE WHEN @now >= @opening and @now < @closing THEN 1 ELSE 0 END;
    RETURN CASE WHEN @now >= @opening or @now < @closing THEN 1 ELSE 0 END;
END;
GO

-- h_IsSuperAdmin
CREATE FUNCTION h_IsSuperAdmin (@admin_id INT)
RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN EXISTS (SELECT 1 FROM Admin WHERE admin_id = @admin_id AND role = 'Super Admin')
                THEN 1 ELSE 0 END;
END;
GO

-- h_AdminCanManageBusiness
create function h_AdminCanManageBusiness (@admin_id int, @business_id int)
returns bit
as
begin
    if dbo.h_IsSuperAdmin(@admin_id) = 1 return 1;
    return case when exists (select 1
                             from Admin a
                             join Business b on b.zone_id = a.zone_id
                             where a.admin_id = @admin_id and a.role = 'Zone Admin'
                               and b.business_id = @business_id)
                then 1 else 0 end;
end;
GO

-- h_AdminCanManageCustomer
CREATE FUNCTION h_AdminCanManageCustomer (@admin_id INT, @customer_id INT)
RETURNS BIT
as
BEGIN
    IF dbo.h_IsSuperAdmin(@admin_id) = 1 RETURN 1;
    RETURN CASE WHEN exists (select 1
                             from Admin a
                             join Address ad on ad.zone_id = a.zone_id
                             where a.admin_id = @admin_id and a.role = 'Zone Admin'
                               and ad.customer_id = @customer_id)
                THEN 1 ELSE 0 END;
END;
GO

-- h_ActiveAddress
CREATE FUNCTION h_ActiveAddress (@customer_id INT)
RETURNS INT
as
BEGIN
    RETURN (select top 1 address_id from Address
            where customer_id = @customer_id and is_active = 1
            order by address_id);
END;
GO

-- h_LeastBusyRider
CREATE FUNCTION h_LeastBusyRider (@zone_id INT)
RETURNS INT
AS
BEGIN
    RETURN (
        SELECT TOP 1 r.rider_id
        FROM Rider r
        JOIN Users u ON u.user_id = r.rider_id
        WHERE r.zone_id = @zone_id
          AND r.is_available = 1
          AND u.account_status = 'Active'
        ORDER BY (SELECT COUNT(*) FROM Delivery d
                  JOIN SubOrder s ON s.suborder_id = d.suborder_id
                  WHERE d.rider_id = r.rider_id AND s.status IN ('Assigned', 'Picked Up')),
                 r.rider_id
    );
END;
GO

-- h_RecomputeOrderStatus
create procedure h_RecomputeOrderStatus @order_id int
as
begin
    update Orders
    set status = case
        when not exists (select 1 from SubOrder where order_id = @order_id and status <> 'Cancelled')
            then 'Cancelled'
        when not exists (select 1 from SubOrder where order_id = @order_id
                         and status not in ('Cancelled', 'Delivered'))
            then 'Delivered'
        when exists (select 1 from SubOrder where order_id = @order_id
                     and status in ('Picked Up', 'Delivered'))
            then 'In Progress'
        else 'Placed'
    end
    where order_id = @order_id;
end;
GO

-- h_RefundOrder
CREATE PROCEDURE h_RefundOrder @order_id INT, @amount DECIMAL(10,2)
AS
BEGIN
    DECLARE @refund DECIMAL(10,2), @method VARCHAR(20), @customer_id INT;

    SELECT @refund = CASE WHEN @amount < p.amount - p.refunded_amount
                          THEN @amount ELSE p.amount - p.refunded_amount END,
           @method = p.method
    FROM Payment p
    WHERE p.order_id = @order_id;

    IF @refund IS NULL OR @refund <= 0 RETURN;

    SELECT @customer_id = c.customer_id
    FROM Orders o JOIN Cart c ON c.cart_id = o.cart_id
    WHERE o.order_id = @order_id;

    UPDATE Payment SET refunded_amount = refunded_amount + @refund WHERE order_id = @order_id;
    IF @method <> 'Cash'
        UPDATE Customer SET wallet_balance = wallet_balance + @refund WHERE customer_id = @customer_id;
END;
GO

-- h_RestoreVoucherIfCancelled
CREATE PROCEDURE h_RestoreVoucherIfCancelled @order_id INT
as
BEGIN
    DECLARE @voucher_id INT;
    select @voucher_id = voucher_id from Orders where order_id = @order_id and status = 'Cancelled';
    IF @voucher_id is not null
    BEGIN
        update Voucher set status = 'Unused' where voucher_id = @voucher_id;
        update Orders set voucher_id = null where order_id = @order_id;
    END
END;
GO

-- h_CancelOrder
CREATE PROCEDURE h_CancelOrder @order_id INT
as
BEGIN
    DECLARE @remaining DECIMAL(10,2);

    update SubOrder set status = 'Cancelled'
    where order_id = @order_id and status in ('Placed', 'Assigned');
    EXEC h_RecomputeOrderStatus @order_id;

    select @remaining = amount - refunded_amount from Payment where order_id = @order_id;
    EXEC h_RefundOrder @order_id, @remaining;
    EXEC h_RestoreVoucherIfCancelled @order_id;
END;
GO

-- h_CancelSubOrder
CREATE PROCEDURE h_CancelSubOrder @suborder_id INT
as
BEGIN
    DECLARE @order_id INT, @amount DECIMAL(10,2);
    select @order_id = order_id, @amount = total_price + delivery_fee
    from SubOrder where suborder_id = @suborder_id and status in ('Placed', 'Assigned');
    IF @order_id is null RETURN;

    update SubOrder set status = 'Cancelled' where suborder_id = @suborder_id;
    EXEC h_RefundOrder @order_id, @amount;
    EXEC h_RecomputeOrderStatus @order_id;
    EXEC h_RestoreVoucherIfCancelled @order_id;
END;
GO

-- h_SetActiveAddress
create procedure h_SetActiveAddress @customer_id int, @address_id int
as
begin
    update Address
    set is_active = case when address_id = @address_id then 1 else 0 end
    where customer_id = @customer_id;
end;
GO

-- h_ValidateAccount
CREATE PROCEDURE h_ValidateAccount
    @first_name VARCHAR(30), @last_name VARCHAR(30), @username VARCHAR(30),
    @password VARCHAR(30), @email VARCHAR(100), @phone CHAR(11), @dob DATE
as
BEGIN
    IF isnull(@first_name, '') = '' or isnull(@last_name, '') = ''
       or isnull(@username, '') = '' or isnull(@password, '') = ''
       or isnull(@email, '') = ''
        RETURN -1;
    IF @phone is not null and (LEN(@phone) <> 11 or @phone like '%[^0-9]%')
        RETURN -1;
    IF @dob is not null and @dob > GETDATE()
        RETURN -1;
    IF exists (select 1 from Users where username = @username)
       or exists (select 1 from Users where email = @email)
        RETURN -2;
    RETURN 0;
END;
GO

-- h_CreateUser
CREATE PROCEDURE h_CreateUser
    @first_name VARCHAR(30), @middle_name VARCHAR(30), @last_name VARCHAR(30),
    @username VARCHAR(30), @password VARCHAR(30), @email VARCHAR(100),
    @phone CHAR(11), @dob DATE, @user_id INT OUTPUT
AS
BEGIN
    INSERT INTO Users (first_name, middle_name, last_name, username, password, email, dob)
    VALUES (@first_name, @middle_name, @last_name, @username, @password, @email, @dob);
    SELECT @user_id = user_id FROM Users WHERE username = @username;
    IF @phone IS NOT NULL
        INSERT INTO User_Phone (user_id, phone) VALUES (@user_id, @phone);
END;
GO

-- 4.2.a allBusinessProfiles
CREATE VIEW allBusinessProfiles
AS
SELECT b.business_id,
       b.name AS business_name,
       CASE WHEN r.business_id IS NOT NULL THEN 'Restaurant'
            WHEN ph.business_id IS NOT NULL THEN 'Pharmacy' END AS business_type,
       z.zone_name,
       u.first_name + ' ' + u.last_name AS partner_name,
       b.status,
       b.opening_hour,
       b.closing_hour
FROM Business b
JOIN Zone z ON z.zone_id = b.zone_id
JOIN Users u ON u.user_id = b.partner_id
LEFT JOIN Restaurant r ON r.business_id = b.business_id
LEFT JOIN Pharmacy ph ON ph.business_id = b.business_id;
GO

-- 4.2.b BusinessesPerZone
CREATE VIEW BusinessesPerZone
AS
SELECT z.zone_id, z.zone_name, COUNT(b.business_id) AS business_count
FROM Zone z
LEFT JOIN Business b ON b.zone_id = z.zone_id AND b.status = 'Active'
GROUP BY z.zone_id, z.zone_name;
GO

-- 4.2.c BusinessRatingsSummary
CREATE VIEW BusinessRatingsSummary
AS
SELECT b.business_id,
       b.name AS business_name,
       CAST(AVG(f.rating * 1.0) AS DECIMAL(10,2)) AS avg_rating,
       COUNT(f.feedback_id) AS ratings_count
FROM Business b
LEFT JOIN SubOrder s ON s.business_id = b.business_id
LEFT JOIN Feedback f ON f.suborder_id = s.suborder_id
GROUP BY b.business_id, b.name;
GO

-- 4.2.d ActiveVouchers
CREATE VIEW ActiveVouchers
as
select voucher_id, promo_code, customer_id, is_percentage, amount, expiry_date
from Voucher
where status = 'Unused' and expiry_date >= CAST(GETDATE() as DATE);
GO

-- 4.2.e PendingBusinessApprovals
CREATE VIEW PendingBusinessApprovals
AS
SELECT business_id, business_name, business_type, zone_name, partner_name
FROM allBusinessProfiles
WHERE status = 'Pending';
GO

-- 4.2.f RiderPerformanceSummary
CREATE VIEW RiderPerformanceSummary
as
select r.rider_id,
       u.first_name + ' ' + u.last_name as rider_name,
       z.zone_name,
       count(CASE WHEN s.status = 'Delivered' THEN 1 END) as completed_deliveries,
       CAST(avg(d.rider_rating * 1.0) as DECIMAL(10,2)) as avg_rating
from Rider r
join Users u on u.user_id = r.rider_id
join Zone z on z.zone_id = r.zone_id
left join Delivery d on d.rider_id = r.rider_id
left join SubOrder s on s.suborder_id = d.suborder_id
group by r.rider_id, u.first_name, u.last_name, z.zone_name;
GO

-- 4.2.g TopSellingProducts
CREATE VIEW TopSellingProducts
AS
SELECT TOP 10
       p.product_id,
       p.name AS product_name,
       b.name AS business_name,
       CASE WHEN r.business_id IS NOT NULL THEN 'Restaurant' ELSE 'Pharmacy' END AS business_type,
       SUM(ci.quantity) AS units_sold,
       SUM(ci.quantity * ci.unit_price) AS total_revenue
FROM Orders o
JOIN CartItem ci ON ci.cart_id = o.cart_id
JOIN Product p ON p.product_id = ci.product_id
JOIN SubOrder s ON s.order_id = o.order_id AND s.business_id = p.business_id
JOIN Business b ON b.business_id = p.business_id
LEFT JOIN Restaurant r ON r.business_id = b.business_id
WHERE s.status <> 'Cancelled'
GROUP BY p.product_id, p.name, b.name, r.business_id
ORDER BY SUM(ci.quantity) DESC, p.product_id ASC;
GO

-- 4.2.h ZoneDeliveryPerformance
create view ZoneDeliveryPerformance
as
select z.zone_id,
       z.zone_name,
       count(x.delivery_id) as delivery_count,
       cast(avg(x.tracking_time * 1.0) as decimal(10,2)) as avg_tracking_time
from Zone z
left join (select d.delivery_id, d.tracking_time, o.zone_id
           from Delivery d
           join SubOrder s on s.suborder_id = d.suborder_id
           join Orders o on o.order_id = s.order_id
           where s.status = 'Delivered') x on x.zone_id = z.zone_id
group by z.zone_id, z.zone_name;
GO

-- 4.3.a Customer_Register
CREATE PROCEDURE Customer_Register
    @first_name VARCHAR(30), @middle_name VARCHAR(30), @last_name VARCHAR(30),
    @username VARCHAR(30), @password VARCHAR(30), @email VARCHAR(100),
    @phone CHAR(11), @dob DATE
AS
BEGIN
    DECLARE @rc INT, @user_id INT;
    EXEC @rc = h_ValidateAccount @first_name, @last_name, @username, @password, @email, @phone, @dob;
    IF @rc <> 0 RETURN @rc;

    EXEC h_CreateUser @first_name, @middle_name, @last_name, @username, @password, @email,
                      @phone, @dob, @user_id OUTPUT;
    INSERT INTO Customer (customer_id, wallet_balance) VALUES (@user_id, 0);
    RETURN 0;
END;
GO

-- 4.3.b Partner_Register
create procedure Partner_Register
    @first_name varchar(30), @middle_name varchar(30), @last_name varchar(30),
    @username varchar(30), @password varchar(30), @email varchar(100),
    @phone char(11), @dob date
as
begin
    declare @rc int, @user_id int;
    exec @rc = h_ValidateAccount @first_name, @last_name, @username, @password, @email, @phone, @dob;
    if @rc <> 0 return @rc;

    exec h_CreateUser @first_name, @middle_name, @last_name, @username, @password, @email,
                      @phone, @dob, @user_id output;
    insert into Partner (partner_id) values (@user_id);
    return 0;
end;
GO

-- 4.3.c Rider_Register
create procedure Rider_Register
    @first_name varchar(30), @middle_name varchar(30), @last_name varchar(30),
    @username varchar(30), @password varchar(30), @email varchar(100),
    @phone char(11), @dob date, @vehicle_type varchar(30), @plate_no varchar(15),
    @license_no varchar(20), @zone_id int
as
begin
    declare @rc int, @user_id int;

    if isnull(@vehicle_type, '') = '' or isnull(@plate_no, '') = ''
       or isnull(@license_no, '') = ''
       or @zone_id is null or not exists (select 1 from Zone where zone_id = @zone_id)
        return -1;

    exec @rc = h_ValidateAccount @first_name, @last_name, @username, @password, @email, @phone, @dob;
    if @rc <> 0 return @rc;

    if exists (select 1 from Rider where plate_no = @plate_no or license_no = @license_no)
        return -2;

    exec h_CreateUser @first_name, @middle_name, @last_name, @username, @password, @email,
                      @phone, @dob, @user_id output;
    insert into Rider (rider_id, vehicle_type, plate_no, license_no, is_available, zone_id)
    values (@user_id, @vehicle_type, @plate_no, @license_no, 1, @zone_id);
    return 0;
end;
GO

-- 4.3.d CustomerLoginValidation
create function CustomerLoginValidation (@username varchar(30), @password varchar(30))
returns bit
as
begin
    return case when exists (select 1
                             from Users u join Customer c on c.customer_id = u.user_id
                             where u.username = @username and u.password = @password
                               and u.account_status = 'Active')
                then 1 else 0 end;
end;
GO

-- 4.3.e PartnerLoginValidation
CREATE FUNCTION PartnerLoginValidation (@username VARCHAR(30), @password VARCHAR(30))
RETURNS BIT
as
BEGIN
    RETURN CASE WHEN exists (select 1
                             from Users u join Partner p on p.partner_id = u.user_id
                             where u.username = @username and u.password = @password
                               and u.account_status = 'Active')
                THEN 1 ELSE 0 END;
END;
GO

-- 4.3.f RiderLoginValidation
create function RiderLoginValidation (@username varchar(30), @password varchar(30))
returns bit
as
begin
    return case when exists (select 1
                             from Users u join Rider r on r.rider_id = u.user_id
                             where u.username = @username and u.password = @password
                               and u.account_status = 'Active')
                then 1 else 0 end;
end;
GO

-- 4.3.g AdminLoginValidation
CREATE FUNCTION AdminLoginValidation (@username VARCHAR(30), @password VARCHAR(30))
RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN EXISTS (SELECT 1
                             FROM Users u JOIN Admin a ON a.admin_id = u.user_id
                             WHERE u.username = @username AND u.password = @password
                               AND u.account_status = 'Active')
                THEN 1 ELSE 0 END;
END;
GO

-- 4.3.h Change_Password
create procedure Change_Password
    @user_id int, @old_password varchar(30), @new_password varchar(30),
    @new_password_repeat varchar(30), @success bit output
as
begin
    set @success = 0;

    if isnull(@new_password, '') = '' or @new_password_repeat is null
       or @new_password <> @new_password_repeat
        return -1;
    if not exists (select 1 from Users where user_id = @user_id and password = @old_password)
        return -1;
    if @new_password = @old_password
        return -1;

    update Users set password = @new_password where user_id = @user_id;
    set @success = 1;
    return 0;
end;
GO

-- 4.4.a Create_Admin
create procedure Create_Admin
    @first_name varchar(30), @middle_name varchar(30), @last_name varchar(30),
    @username varchar(30), @password varchar(30), @email varchar(100),
    @phone char(11), @dob date, @role varchar(20), @zone_id int, @super_admin_id int
as
begin
    declare @rc int, @user_id int;

    if dbo.h_IsSuperAdmin(@super_admin_id) = 0 return -3;

    set @role = isnull(@role, 'Super Admin');
    if @role not in ('Super Admin', 'Zone Admin') return -1;
    if @role = 'Super Admin' and @zone_id is not null return -1;
    if @role = 'Zone Admin'
       and (@zone_id is null or not exists (select 1 from Zone where zone_id = @zone_id))
        return -1;

    exec @rc = h_ValidateAccount @first_name, @last_name, @username, @password, @email, @phone, @dob;
    if @rc <> 0 return @rc;

    exec h_CreateUser @first_name, @middle_name, @last_name, @username, @password, @email,
                      @phone, @dob, @user_id output;
    insert into Admin (admin_id, role, zone_id) values (@user_id, @role, @zone_id);
    return 0;
end;
GO

-- 4.4.b Approve_Business
CREATE PROCEDURE Approve_Business @business_id INT, @admin_id INT
as
BEGIN
    DECLARE @status VARCHAR(20);
    select @status = status from Business where business_id = @business_id;
    IF @status is null RETURN -1;
    IF dbo.h_AdminCanManageBusiness(@admin_id, @business_id) = 0 RETURN -3;
    IF @status <> 'Pending' RETURN -4;

    update Business set status = 'Active' where business_id = @business_id;
    RETURN 0;
END;
GO

-- 4.4.c Reject_Business
create procedure Reject_Business @business_id int, @admin_id int
as
begin
    declare @status varchar(20);
    select @status = status from Business where business_id = @business_id;
    if @status is null return -1;
    if dbo.h_AdminCanManageBusiness(@admin_id, @business_id) = 0 return -3;
    if @status <> 'Pending' return -4;

    update Business set status = 'Rejected' where business_id = @business_id;
    return 0;
end;
GO

-- 4.4.d Suspend_Business
CREATE PROCEDURE Suspend_Business @business_id INT, @admin_id INT, @reason VARCHAR(255)
as
BEGIN
    DECLARE @status VARCHAR(20);
    select @status = status from Business where business_id = @business_id;
    IF @status is null or isnull(@reason, '') = '' RETURN -1;
    IF dbo.h_AdminCanManageBusiness(@admin_id, @business_id) = 0 RETURN -3;
    IF @status <> 'Active' RETURN -4;

    update Business set status = 'Suspended', suspension_reason = @reason
    where business_id = @business_id;
    update Product set is_available = 0 where business_id = @business_id;

    update Customer
    set wallet_balance = wallet_balance +
        (select isnull(sum(CASE WHEN s.total_price + s.delivery_fee < p.amount - p.refunded_amount
                                THEN s.total_price + s.delivery_fee
                                ELSE p.amount - p.refunded_amount END), 0)
         from SubOrder s
         inner join Payment p on p.order_id = s.order_id
         inner join Orders o on o.order_id = s.order_id
         inner join Cart c on c.cart_id = o.cart_id
         where s.business_id = @business_id and s.status in ('Placed', 'Assigned')
           and p.method <> 'Cash' and c.customer_id = Customer.customer_id)
    where customer_id in (select c.customer_id
                          from SubOrder s
                          inner join Orders o on o.order_id = s.order_id
                          inner join Cart c on c.cart_id = o.cart_id
                          where s.business_id = @business_id and s.status in ('Placed', 'Assigned'));

    update Payment
    set refunded_amount = refunded_amount +
        (select CASE WHEN s.total_price + s.delivery_fee < Payment.amount - Payment.refunded_amount
                     THEN s.total_price + s.delivery_fee
                     ELSE Payment.amount - Payment.refunded_amount END
         from SubOrder s
         where s.order_id = Payment.order_id and s.business_id = @business_id
           and s.status in ('Placed', 'Assigned'))
    where order_id in (select order_id from SubOrder
                       where business_id = @business_id and status in ('Placed', 'Assigned'));

    update SubOrder set status = 'Cancelled'
    where business_id = @business_id and status in ('Placed', 'Assigned');

    update Orders
    set status = CASE
        WHEN not exists (select 1 from SubOrder s where s.order_id = Orders.order_id and s.status <> 'Cancelled')
            THEN 'Cancelled'
        WHEN not exists (select 1 from SubOrder s where s.order_id = Orders.order_id
                         and s.status not in ('Cancelled', 'Delivered'))
            THEN 'Delivered'
        WHEN exists (select 1 from SubOrder s where s.order_id = Orders.order_id
                     and s.status in ('Picked Up', 'Delivered'))
            THEN 'In Progress'
        ELSE 'Placed'
    END
    where order_id in (select order_id from SubOrder where business_id = @business_id);

    update Voucher set status = 'Unused'
    where voucher_id in (select voucher_id from Orders
                         where status = 'Cancelled' and voucher_id is not null
                           and order_id in (select order_id from SubOrder where business_id = @business_id));
    update Orders set voucher_id = null
    where status = 'Cancelled' and voucher_id is not null
      and order_id in (select order_id from SubOrder where business_id = @business_id);
    RETURN 0;
END;
GO

-- 4.4.e Reinstate_Business
create procedure Reinstate_Business @business_id int, @super_admin_id int
as
begin
    declare @status varchar(20);
    select @status = status from Business where business_id = @business_id;
    if @status is null return -1;
    if dbo.h_IsSuperAdmin(@super_admin_id) = 0 return -3;
    if @status <> 'Suspended' return -4;

    update Business set status = 'Active', suspension_reason = null
    where business_id = @business_id;
    return 0;
end;
GO

-- 4.4.f Create_Zone
CREATE PROCEDURE Create_Zone @zone_name VARCHAR(50), @delivery_fee DECIMAL(10,2), @super_admin_id INT
as
BEGIN
    IF dbo.h_IsSuperAdmin(@super_admin_id) = 0 RETURN -3;
    IF isnull(@zone_name, '') = '' or @delivery_fee is null or @delivery_fee < 0 RETURN -1;
    IF exists (select 1 from Zone where zone_name = @zone_name) RETURN -2;

    insert into Zone (zone_name, delivery_fee) values (@zone_name, @delivery_fee);
    RETURN 0;
END;
GO

-- 4.4.g Update_Zone_Fee
CREATE PROCEDURE Update_Zone_Fee @zone_id INT, @new_fee DECIMAL(10,2), @super_admin_id INT
AS
BEGIN
    IF dbo.h_IsSuperAdmin(@super_admin_id) = 0 RETURN -3;
    IF @new_fee IS NULL OR @new_fee < 0 OR NOT EXISTS (SELECT 1 FROM Zone WHERE zone_id = @zone_id)
        RETURN -1;

    UPDATE Zone SET delivery_fee = @new_fee WHERE zone_id = @zone_id;
    RETURN 0;
END;
GO

-- 4.4.h Assign_Admin_Zone
CREATE PROCEDURE Assign_Admin_Zone @admin_id INT, @zone_id INT, @super_admin_id INT
AS
BEGIN
    IF dbo.h_IsSuperAdmin(@super_admin_id) = 0 RETURN -3;
    IF NOT EXISTS (SELECT 1 FROM Admin WHERE admin_id = @admin_id AND role = 'Zone Admin')
       OR NOT EXISTS (SELECT 1 FROM Zone WHERE zone_id = @zone_id)
        RETURN -1;

    UPDATE Admin SET zone_id = @zone_id WHERE admin_id = @admin_id;
    RETURN 0;
END;
GO

-- 4.4.i Issue_Voucher
create procedure Issue_Voucher
    @customer_id int, @promo_code varchar(30), @is_percentage bit, @amount decimal(10,2),
    @expiry_date date, @admin_id int
as
begin
    if not exists (select 1 from Admin where admin_id = @admin_id) return -3;
    if not exists (select 1 from Customer where customer_id = @customer_id) return -1;
    if exists (select 1 from Users where user_id = @customer_id and account_status = 'Blacklisted') return -3;

    if isnull(@promo_code, '') = '' or @is_percentage is null or @amount is null
       or @amount <= 0 or @expiry_date is null or @expiry_date < cast(getdate() as date)
       or (@is_percentage = 1 and (@amount < 1 or @amount > 100))
        return -1;
    if exists (select 1 from Voucher where promo_code = @promo_code) return -2;

    insert into Voucher (promo_code, is_percentage, amount, expiry_date, status, customer_id)
    values (@promo_code, @is_percentage, @amount, @expiry_date, 'Unused', @customer_id);
    return 0;
end;
GO

-- 4.4.j Blacklist_Customer
create procedure Blacklist_Customer @customer_id int, @admin_id int, @reason varchar(255)
as
begin
    if not exists (select 1 from Customer where customer_id = @customer_id) return -1;
    if not exists (select 1 from Admin where admin_id = @admin_id) return -3;
    if dbo.h_AdminCanManageCustomer(@admin_id, @customer_id) = 0 return -3;
    if isnull(@reason, '') = '' return -1;
    if exists (select 1 from Users where user_id = @customer_id and account_status = 'Blacklisted') return -4;

    update Users set account_status = 'Blacklisted' where user_id = @customer_id;
    insert into Blacklist (customer_id, admin_id, reason) values (@customer_id, @admin_id, @reason);

    update Customer
    set wallet_balance = wallet_balance +
        (select isnull(sum(p.amount - p.refunded_amount), 0)
         from Payment p
         inner join Orders o on o.order_id = p.order_id
         inner join Cart c on c.cart_id = o.cart_id
         where c.customer_id = @customer_id and p.method <> 'Cash'
           and o.status <> 'Cancelled'
           and not exists (select 1 from SubOrder s where s.order_id = o.order_id
                           and s.status in ('Picked Up', 'Delivered')))
    where customer_id = @customer_id;

    update Payment set refunded_amount = amount
    where order_id in (select o.order_id
                       from Orders o inner join Cart c on c.cart_id = o.cart_id
                       where c.customer_id = @customer_id and o.status <> 'Cancelled'
                         and not exists (select 1 from SubOrder s where s.order_id = o.order_id
                                         and s.status in ('Picked Up', 'Delivered')));

    update SubOrder set status = 'Cancelled'
    where status in ('Placed', 'Assigned')
      and order_id in (select o.order_id
                       from Orders o inner join Cart c on c.cart_id = o.cart_id
                       where c.customer_id = @customer_id and o.status <> 'Cancelled'
                         and not exists (select 1 from SubOrder s where s.order_id = o.order_id
                                         and s.status in ('Picked Up', 'Delivered')));

    update Voucher set status = 'Unused'
    where voucher_id in (select o.voucher_id
                         from Orders o inner join Cart c on c.cart_id = o.cart_id
                         where c.customer_id = @customer_id and o.status <> 'Cancelled'
                           and not exists (select 1 from SubOrder s where s.order_id = o.order_id
                                           and s.status <> 'Cancelled'));
    update Orders set status = 'Cancelled', voucher_id = null
    where status <> 'Cancelled'
      and cart_id in (select cart_id from Cart where customer_id = @customer_id)
      and not exists (select 1 from SubOrder s where s.order_id = Orders.order_id
                      and s.status <> 'Cancelled');

    delete from Voucher where customer_id = @customer_id and status = 'Unused';
    return 0;
end;
GO

-- 4.4.k Lift_Customer_Blacklist
CREATE PROCEDURE Lift_Customer_Blacklist @customer_id INT, @admin_id INT
as
BEGIN
    DECLARE @owner INT;
    IF not exists (select 1 from Admin where admin_id = @admin_id) RETURN -3;
    select @owner = admin_id from Blacklist where customer_id = @customer_id;
    IF @owner is null RETURN -4;
    IF @owner <> @admin_id RETURN -3;

    delete from Blacklist where customer_id = @customer_id;
    update Users set account_status = 'Active' where user_id = @customer_id;
    RETURN 0;
END;
GO

-- 4.4.l ZoneOrderReport
CREATE FUNCTION ZoneOrderReport (@zone_id INT, @from_date DATE, @to_date DATE)
RETURNS TABLE
as
RETURN
(
    select z.zone_id,
           z.zone_name,
           count(o.order_id) as number_of_orders,
           CAST(avg(o.total_amount) as DECIMAL(10,2)) as avg_order_total,
           CAST(isnull(sum(o.price), 0) * 0.10 as DECIMAL(10,2)) as platform_commission
    from Zone z
    left join (select od.order_id, od.zone_id, od.total_amount,
                      (select sum(s.total_price) from SubOrder s
                       where s.order_id = od.order_id and s.status <> 'Cancelled') as price
               from Orders od
               where od.status <> 'Cancelled'
                 and CAST(od.order_date as DATE) between @from_date and @to_date) o
           on o.zone_id = z.zone_id
    where z.zone_id = @zone_id and @from_date <= @to_date
    group by z.zone_id, z.zone_name
);
GO

-- 4.4.m TopRiders
create function TopRiders (@from_date date, @to_date date)
returns table
as
return
(
    select top 5
           1 + (select count(*)
                from (select d2.rider_id, count(*) as cnt
                      from Delivery d2
                      inner join SubOrder s2 on s2.suborder_id = d2.suborder_id and s2.status = 'Delivered'
                      where cast(d2.delivered_at as date) between @from_date and @to_date
                      group by d2.rider_id) t2
                where t2.cnt > t.completed_delivery_count
                   or (t2.cnt = t.completed_delivery_count and t2.rider_id < t.rider_id)) as rider_rank,
           t.rider_id,
           t.rider_name,
           t.completed_delivery_count
    from (select r.rider_id,
                 u.first_name + ' ' + u.last_name as rider_name,
                 count(*) as completed_delivery_count
          from Delivery d
          inner join SubOrder s on s.suborder_id = d.suborder_id and s.status = 'Delivered'
          inner join Rider r on r.rider_id = d.rider_id
          inner join Users u on u.user_id = r.rider_id
          where cast(d.delivered_at as date) between @from_date and @to_date
          group by r.rider_id, u.first_name, u.last_name) t
    where @from_date <= @to_date
    order by t.completed_delivery_count desc, t.rider_id asc
);
GO

-- 4.4.n Daily_Revenue_Report
CREATE FUNCTION Daily_Revenue_Report (@report_date DATE)
RETURNS TABLE
AS
RETURN
(
    SELECT z.zone_name,
           CASE WHEN r.business_id IS NOT NULL THEN 'Restaurant' ELSE 'Pharmacy' END AS business_type,
           COUNT(s.suborder_id) AS number_of_suborders,
           SUM(s.total_price) AS gross_sales,
           SUM(s.delivery_fee) AS delivery_fees,
           CAST(SUM(s.total_price) * 0.10 AS DECIMAL(10,2)) AS platform_commission
    FROM Orders o
    JOIN Zone z ON z.zone_id = o.zone_id
    JOIN SubOrder s ON s.order_id = o.order_id AND s.status <> 'Cancelled'
    LEFT JOIN Restaurant r ON r.business_id = s.business_id
    WHERE CAST(o.order_date AS DATE) = @report_date
    GROUP BY z.zone_name, CASE WHEN r.business_id IS NOT NULL THEN 'Restaurant' ELSE 'Pharmacy' END
);
GO

-- 4.5.a Register_Business
CREATE PROCEDURE Register_Business
    @partner_id INT, @name VARCHAR(100), @description VARCHAR(255), @link_website VARCHAR(255),
    @zone_id INT, @opening_hour TIME, @closing_hour TIME, @expected_delivery_time INT,
    @phone CHAR(11), @business_type VARCHAR(20), @cuisine_type VARCHAR(50),
    @food_category VARCHAR(50), @pharmacy_type VARCHAR(50)
AS
BEGIN
    DECLARE @business_id INT, @status VARCHAR(20);

    IF NOT EXISTS (SELECT 1 FROM Partner WHERE partner_id = @partner_id) RETURN -3;

    IF ISNULL(@name, '') = ''
       OR @zone_id IS NULL OR NOT EXISTS (SELECT 1 FROM Zone WHERE zone_id = @zone_id)
       OR @opening_hour IS NULL OR @closing_hour IS NULL
       OR @expected_delivery_time IS NULL OR @expected_delivery_time <= 0
       OR (@phone IS NOT NULL AND (LEN(@phone) <> 11 OR @phone LIKE '%[^0-9]%'))
       OR @business_type IS NULL OR @business_type NOT IN ('Restaurant', 'Pharmacy')
       OR (@business_type = 'Restaurant'
           AND (ISNULL(@cuisine_type, '') = '' OR ISNULL(@food_category, '') = ''))
       OR (@business_type = 'Pharmacy' AND ISNULL(@pharmacy_type, '') = '')
        RETURN -1;

    SELECT @business_id = business_id, @status = status FROM Business WHERE partner_id = @partner_id;
    IF @business_id IS NOT NULL AND @status <> 'Rejected' RETURN -2;

    IF @business_id IS NULL
    BEGIN
        INSERT INTO Business (name, description, link_website, opening_hour, closing_hour,
                              expected_delivery_time, status, partner_id, zone_id)
        VALUES (@name, @description, @link_website, @opening_hour, @closing_hour,
                @expected_delivery_time, 'Pending', @partner_id, @zone_id);
        SELECT @business_id = business_id FROM Business WHERE partner_id = @partner_id;
    END
    ELSE
    BEGIN

        UPDATE Business
        SET name = @name, description = @description, link_website = @link_website,
            opening_hour = @opening_hour, closing_hour = @closing_hour,
            expected_delivery_time = @expected_delivery_time, zone_id = @zone_id,
            status = 'Pending', suspension_reason = NULL
        WHERE business_id = @business_id;
        DELETE FROM Business_Phone WHERE business_id = @business_id;
        DELETE FROM Restaurant WHERE business_id = @business_id;
        DELETE FROM Pharmacy WHERE business_id = @business_id;
    END

    IF @phone IS NOT NULL INSERT INTO Business_Phone (business_id, phone) VALUES (@business_id, @phone);
    IF @business_type = 'Restaurant'
        INSERT INTO Restaurant (business_id, cuisine_type, food_category)
        VALUES (@business_id, @cuisine_type, @food_category);
    ELSE
        INSERT INTO Pharmacy (business_id, pharmacy_type) VALUES (@business_id, @pharmacy_type);
    RETURN 0;
END;
GO

-- 4.5.b Update_Business_Info
create procedure Update_Business_Info
    @business_id int, @opening_hour time, @closing_hour time, @phone char(11), @link_website varchar(255)
as
begin
    if not exists (select 1 from Business where business_id = @business_id) return -1;
    if @phone is not null and (len(@phone) <> 11 or @phone like '%[^0-9]%') return -1;
    if @phone is not null and exists (select 1 from Business_Phone where business_id = @business_id and phone = @phone)
        return -2;

    update Business
    set opening_hour = isnull(@opening_hour, opening_hour),
        closing_hour = isnull(@closing_hour, closing_hour),
        link_website = isnull(@link_website, link_website)
    where business_id = @business_id;
    if @phone is not null insert into Business_Phone (business_id, phone) values (@business_id, @phone);
    return 0;
end;
GO

-- 4.5.c Upsert_Product
CREATE PROCEDURE Upsert_Product
    @business_id INT, @product_id INT, @name VARCHAR(100), @description VARCHAR(255),
    @category VARCHAR(50), @price DECIMAL(10,2), @is_available BIT
as
BEGIN
    DECLARE @status VARCHAR(20), @owner INT, @discount DECIMAL(10,2);
    select @status = status from Business where business_id = @business_id;
    IF @status is null RETURN -1;

    IF @product_id is not null
    BEGIN
        select @owner = business_id, @discount = discount_amount from Product where product_id = @product_id;
        IF @owner is null RETURN -1;
        IF @owner <> @business_id RETURN -3;
    END

    IF isnull(@name, '') = '' or isnull(@category, '') = ''
       or @price is null or @price <= 0 or @is_available is null
       or (@product_id is not null and @discount > 0.5 * @price)
        RETURN -1;
    IF @status = 'Suspended' RETURN -4;

    IF @product_id is null
        insert into Product (name, description, category, price, discount_amount, is_available, business_id)
        values (@name, @description, @category, @price, 0, @is_available, @business_id);
    ELSE
        update Product
        set name = @name, description = @description, category = @category,
            price = @price, is_available = @is_available
        where product_id = @product_id;
    RETURN 0;
END;
GO

-- 4.5.d Toggle_Product_Status
create procedure Toggle_Product_Status @product_id int, @is_available bit
as
begin
    declare @status varchar(20);
    select @status = b.status
    from Product p join Business b on b.business_id = p.business_id
    where p.product_id = @product_id;
    if @status is null or @is_available is null return -1;
    if @is_available = 1 and @status = 'Suspended' return -4;

    update Product set is_available = @is_available where product_id = @product_id;
    return 0;
end;
GO

-- 4.5.e Set_Product_Promotion
CREATE PROCEDURE Set_Product_Promotion @product_id INT, @discount_amount DECIMAL(10,2)
AS
BEGIN
    DECLARE @price DECIMAL(10,2);
    SELECT @price = price FROM Product WHERE product_id = @product_id;
    IF @price IS NULL OR @discount_amount IS NULL OR @discount_amount < 0 OR @discount_amount > 0.5 * @price
        RETURN -1;

    UPDATE Product SET discount_amount = @discount_amount WHERE product_id = @product_id;
    RETURN 0;
END;
GO

-- 4.5.f BusinessSalesReport
create function BusinessSalesReport (@business_id int, @from_date date, @to_date date)
returns table
as
return
(
    select p.product_id,
           p.name as product_name,
           sum(ci.quantity) as units_sold,
           sum(ci.quantity * ci.unit_price) as revenue_per_product
    from Product p
    join CartItem ci on ci.product_id = p.product_id
    join Orders o on o.cart_id = ci.cart_id
    join SubOrder s on s.order_id = o.order_id and s.business_id = p.business_id
    where p.business_id = @business_id
      and @from_date <= @to_date
      and cast(o.order_date as date) between @from_date and @to_date
      and s.status <> 'Cancelled'
    group by p.product_id, p.name
);
GO

-- 4.5.g BusinessFeedbackOverview
CREATE FUNCTION BusinessFeedbackOverview (@business_id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT CAST(AVG(f.rating * 1.0) AS DECIMAL(10,2)) AS avg_rating,
           COUNT(f.feedback_id) AS number_of_feedbacks,
           COUNT(CASE WHEN f.rating = 5 THEN 1 END) AS five_star,
           COUNT(CASE WHEN f.rating = 4 THEN 1 END) AS four_star,
           COUNT(CASE WHEN f.rating = 3 THEN 1 END) AS three_star,
           COUNT(CASE WHEN f.rating = 2 THEN 1 END) AS two_star,
           COUNT(CASE WHEN f.rating = 1 THEN 1 END) AS one_star
    FROM Business b
    LEFT JOIN SubOrder s ON s.business_id = b.business_id
    LEFT JOIN Feedback f ON f.suborder_id = s.suborder_id
    WHERE b.business_id = @business_id
);
GO

-- 4.6.a Add_Customer_Address
CREATE PROCEDURE Add_Customer_Address @customer_id INT, @description VARCHAR(150), @zone_id INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Customer WHERE customer_id = @customer_id) RETURN -3;
    IF ISNULL(@description, '') = ''
       OR @zone_id IS NULL OR NOT EXISTS (SELECT 1 FROM Zone WHERE zone_id = @zone_id)
        RETURN -1;

    UPDATE Address SET is_active = 0 WHERE customer_id = @customer_id;
    INSERT INTO Address (description, is_active, customer_id, zone_id)
    VALUES (@description, 1, @customer_id, @zone_id);
    RETURN 0;
END;
GO

-- 4.6.b Update_Delete_Customer_Address
CREATE PROCEDURE Update_Delete_Customer_Address
    @customer_id INT, @address_id INT, @description VARCHAR(150), @zone_id INT, @action VARCHAR(20)
as
BEGIN
    DECLARE @owner INT, @was_active BIT;

    IF @action is null or @action not in ('Update', 'Delete', 'Remove') RETURN -1;
    select @owner = customer_id, @was_active = is_active from Address where address_id = @address_id;
    IF @owner is null RETURN -1;
    IF @owner <> @customer_id RETURN -3;

    IF exists (select 1
               from Cart c join Orders o on o.cart_id = c.cart_id
               where c.address_id = @address_id and o.status in ('Placed', 'In Progress'))
        RETURN -4;

    IF @action = 'Update'
    BEGIN
        IF isnull(@description, '') = ''
           or @zone_id is null or not exists (select 1 from Zone where zone_id = @zone_id)
            RETURN -1;
        update Address set description = @description, zone_id = @zone_id where address_id = @address_id;
        RETURN 0;
    END

    IF exists (select 1 from Cart where address_id = @address_id) RETURN -4;
    delete from Address where address_id = @address_id;
    IF @was_active = 1
        update Address set is_active = 1
        where address_id = (select MIN(address_id) from Address where customer_id = @customer_id);
    RETURN 0;
END;
GO

-- 4.6.c Change_Active_Address
CREATE PROCEDURE Change_Active_Address @customer_id INT, @new_address_id INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Customer WHERE customer_id = @customer_id) RETURN -3;
    IF NOT EXISTS (SELECT 1 FROM Address WHERE address_id = @new_address_id AND customer_id = @customer_id)
        RETURN -3;

    EXEC h_SetActiveAddress @customer_id, @new_address_id;
    RETURN 0;
END;
GO

-- 4.6.d Add_Card
create procedure Add_Card
    @customer_id int, @card_no char(16), @card_holder_name varchar(100), @expiration_date date
as
begin
    if not exists (select 1 from Customer where customer_id = @customer_id) return -3;
    if @card_no is null or len(@card_no) <> 16 or @card_no like '%[^0-9]%'
       or isnull(@card_holder_name, '') = ''
       or @expiration_date is null or @expiration_date < cast(getdate() as date)
        return -1;
    if exists (select 1 from Card where customer_id = @customer_id and card_no = @card_no) return -2;

    insert into Card (card_no, card_holder_name, expiration_date, customer_id)
    values (@card_no, @card_holder_name, @expiration_date, @customer_id);
    return 0;
end;
GO

-- 4.6.e Create_Cart
create procedure Create_Cart @customer_id int
as
begin
    declare @address_id int;
    if not exists (select 1 from Customer where customer_id = @customer_id) return -3;
    if exists (select 1 from Users where user_id = @customer_id and account_status = 'Blacklisted') return -3;
    set @address_id = dbo.h_ActiveAddress(@customer_id);
    if @address_id is null return -1;
    if exists (select 1 from Cart where address_id = @address_id and status = 'Active') return -2;

    insert into Cart (status, created_at, customer_id, address_id)
    values ('Active', getdate(), @customer_id, @address_id);
    return 0;
end;
GO

-- 4.6.f Add_To_Cart
CREATE PROCEDURE Add_To_Cart @cart_id INT, @product_id INT, @quantity INT, @notes VARCHAR(255)
as
BEGIN
    DECLARE @cstatus VARCHAR(20), @customer_id INT, @address_id INT, @addr_zone INT,
            @available BIT, @bstatus VARCHAR(20), @bzone INT, @existing INT;

    select @cstatus = status, @customer_id = customer_id, @address_id = address_id
    from Cart where cart_id = @cart_id;
    IF @customer_id is null RETURN -1;
    select @available = p.is_available, @bstatus = b.status, @bzone = b.zone_id
    from Product p join Business b on b.business_id = p.business_id
    where p.product_id = @product_id;
    IF @bstatus is null RETURN -1;

    IF @quantity is null or @quantity < 1 RETURN -1;
    IF @quantity > 10 RETURN -6;
    IF @cstatus <> 'Active' RETURN -4;
    IF isnull(dbo.h_ActiveAddress(@customer_id), 0) <> @address_id RETURN -4;
    IF @available = 0 or @bstatus <> 'Active' RETURN -4;
    select @addr_zone = zone_id from Address where address_id = @address_id;
    IF @bzone <> @addr_zone RETURN -5;

    select @existing = quantity from CartItem where cart_id = @cart_id and product_id = @product_id;
    IF isnull(@existing, 0) + @quantity > 10 RETURN -6;

    IF @existing is null
        insert into CartItem (cart_id, product_id, quantity, notes, unit_price)
        values (@cart_id, @product_id, @quantity, @notes, null);
    ELSE
        update CartItem
        set quantity = quantity + @quantity, notes = isnull(@notes, notes)
        where cart_id = @cart_id and product_id = @product_id;
    RETURN 0;
END;
GO

-- 4.6.g Remove_From_Cart
CREATE PROCEDURE Remove_From_Cart @cart_id INT, @product_id INT
as
BEGIN
    DECLARE @cstatus VARCHAR(20), @customer_id INT, @address_id INT;
    select @cstatus = status, @customer_id = customer_id, @address_id = address_id
    from Cart where cart_id = @cart_id;
    IF @customer_id is null RETURN -1;
    IF @cstatus <> 'Active' RETURN -4;
    IF isnull(dbo.h_ActiveAddress(@customer_id), 0) <> @address_id RETURN -4;
    IF not exists (select 1 from CartItem where cart_id = @cart_id and product_id = @product_id) RETURN -1;

    delete from CartItem where cart_id = @cart_id and product_id = @product_id;
    RETURN 0;
END;
GO

-- 4.6.h Calculate_Voucher_Discount
CREATE FUNCTION Calculate_Voucher_Discount (@voucher_id INT, @order_subtotal DECIMAL(10,2))
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @discount DECIMAL(10,2);
    IF @order_subtotal IS NULL OR @order_subtotal < 0 RETURN -1;
    IF @voucher_id IS NULL RETURN 0;

    SELECT @discount = CASE WHEN is_percentage = 1 THEN @order_subtotal * amount / 100
                            ELSE amount END
    FROM Voucher
    WHERE voucher_id = @voucher_id AND status = 'Unused' AND expiry_date >= CAST(GETDATE() AS DATE);

    IF @discount IS NULL RETURN 0;
    RETURN CASE WHEN @discount > @order_subtotal THEN @order_subtotal ELSE @discount END;
END;
GO

-- h_AssignRiders
CREATE PROCEDURE h_AssignRiders @order_id INT, @zone_id INT
AS
BEGIN
    DECLARE @sub INT, @rider INT;
    SELECT @sub = MIN(suborder_id) FROM SubOrder WHERE order_id = @order_id AND status = 'Placed';
    IF @sub IS NULL RETURN 0;

    SET @rider = dbo.h_LeastBusyRider(@zone_id);
    INSERT INTO Delivery (assigned_at, suborder_id, rider_id) VALUES (GETDATE(), @sub, @rider);
    UPDATE SubOrder SET status = 'Assigned' WHERE suborder_id = @sub;

    EXEC h_AssignRiders @order_id, @zone_id;
    RETURN 0;
END;
GO

-- 4.6.i Checkout_Cart
CREATE PROCEDURE Checkout_Cart
    @cart_id INT, @voucher_id INT, @payment_method VARCHAR(20), @card_id INT
as
BEGIN
    DECLARE @status VARCHAR(20), @customer_id INT, @address_id INT, @zone_id INT,
            @zone_fee DECIMAL(10,2), @subtotal DECIMAL(10,2), @fees DECIMAL(10,2),
            @discount DECIMAL(10,2), @total DECIMAL(10,2), @order_id INT,
            @now TIME = CAST(GETDATE() as TIME), @today DATE = CAST(GETDATE() as DATE),
            @v_owner INT, @v_status VARCHAR(20), @v_expiry DATE;

    select @status = status, @customer_id = customer_id, @address_id = address_id
    from Cart where cart_id = @cart_id;
    IF @customer_id is null or @payment_method is null
       or @payment_method not in ('Cash', 'Card', 'Wallet')
        RETURN -1;

    IF exists (select 1 from Users where user_id = @customer_id and account_status = 'Blacklisted') RETURN -3;
    IF @status <> 'Active' RETURN -4;
    IF isnull(dbo.h_ActiveAddress(@customer_id), 0) <> @address_id RETURN -4;
    IF not exists (select 1 from CartItem where cart_id = @cart_id) RETURN -9;

    select @zone_id = a.zone_id, @zone_fee = z.delivery_fee
    from Address a join Zone z on z.zone_id = a.zone_id
    where a.address_id = @address_id;

    IF exists (select 1 from CartItem ci
               join Product p on p.product_id = ci.product_id
               join Business b on b.business_id = p.business_id
               where ci.cart_id = @cart_id and (p.is_available = 0 or b.status <> 'Active'))
        RETURN -4;
    IF exists (select 1 from CartItem ci
               join Product p on p.product_id = ci.product_id
               join Business b on b.business_id = p.business_id
               where ci.cart_id = @cart_id and b.zone_id <> @zone_id)
        RETURN -5;
    IF exists (select 1 from CartItem ci
               join Product p on p.product_id = ci.product_id
               join Business b on b.business_id = p.business_id
               where ci.cart_id = @cart_id
                 and dbo.h_IsBusinessOpen(b.opening_hour, b.closing_hour, @now) = 0)
        RETURN -4;

    IF @voucher_id is not null
    BEGIN
        select @v_owner = customer_id, @v_status = status, @v_expiry = expiry_date
        from Voucher where voucher_id = @voucher_id;
        IF @v_owner is null or @v_expiry < @today RETURN -1;
        IF @v_owner <> @customer_id RETURN -3;
        IF @v_status <> 'Unused' RETURN -4;
    END

    select @subtotal = sum(ci.quantity * (p.price - p.discount_amount)),
           @fees = count(distinct p.business_id) * @zone_fee
    from CartItem ci join Product p on p.product_id = ci.product_id
    where ci.cart_id = @cart_id;
    set @discount = dbo.Calculate_Voucher_Discount(@voucher_id, @subtotal);
    set @total = @subtotal + @fees - @discount;

    IF @payment_method = 'Card'
       and (@card_id is null
            or not exists (select 1 from Card where card_id = @card_id and customer_id = @customer_id
                           and expiration_date >= @today))
        RETURN -7;
    IF @payment_method = 'Wallet'
       and (select wallet_balance from Customer where customer_id = @customer_id) < @total
        RETURN -7;

    IF dbo.h_LeastBusyRider(@zone_id) is null RETURN -8;

    update CartItem
    set unit_price = (select p.price - p.discount_amount from Product p
                      where p.product_id = CartItem.product_id)
    where cart_id = @cart_id;

    insert into Orders (order_date, status, discount_amount, total_amount, cart_id, zone_id, voucher_id)
    values (GETDATE(), 'Placed', @discount, @total, @cart_id, @zone_id, @voucher_id);
    select @order_id = order_id from Orders where cart_id = @cart_id;

    insert into SubOrder (status, total_price, delivery_fee, order_id, business_id)
    select 'Placed', sum(ci.quantity * ci.unit_price), @zone_fee, @order_id, p.business_id
    from CartItem ci join Product p on p.product_id = ci.product_id
    where ci.cart_id = @cart_id
    group by p.business_id
    order by p.business_id;

    EXEC h_AssignRiders @order_id, @zone_id;

    IF @voucher_id is not null update Voucher set status = 'Used' where voucher_id = @voucher_id;

    insert into Payment (amount, currency, method, transaction_date, refunded_amount, order_id, card_id)
    values (@total, 'EGP', @payment_method, GETDATE(), 0, @order_id,
            CASE WHEN @payment_method = 'Card' THEN @card_id END);
    IF @payment_method = 'Wallet'
        update Customer set wallet_balance = wallet_balance - @total where customer_id = @customer_id;

    update Cart set status = 'Checked Out' where cart_id = @cart_id;
    RETURN 0;
END;
GO

-- 4.6.j Cancel_Order
CREATE PROCEDURE Cancel_Order @order_id INT
as
BEGIN
    DECLARE @status VARCHAR(20);
    select @status = status from Orders where order_id = @order_id;
    IF @status is null RETURN -1;
    IF @status = 'Cancelled' RETURN -4;
    IF exists (select 1 from SubOrder where order_id = @order_id and status in ('Picked Up', 'Delivered'))
        RETURN -4;

    EXEC h_CancelOrder @order_id;
    RETURN 0;
END;
GO

-- 4.6.k Reorder
CREATE PROCEDURE Reorder @order_id INT, @address_id INT
AS
BEGIN
    DECLARE @old_cart INT, @customer_id INT, @order_zone INT, @addr_owner INT, @addr_zone INT,
            @new_cart INT, @copyable INT;

    SELECT @old_cart = o.cart_id, @customer_id = c.customer_id, @order_zone = o.zone_id
    FROM Orders o JOIN Cart c ON c.cart_id = o.cart_id
    WHERE o.order_id = @order_id;
    IF @old_cart IS NULL RETURN -1;
    IF EXISTS (SELECT 1 FROM Users WHERE user_id = @customer_id AND account_status = 'Blacklisted') RETURN -3;

    SELECT @addr_owner = customer_id, @addr_zone = zone_id FROM Address WHERE address_id = @address_id;
    IF @addr_owner IS NULL OR @addr_owner <> @customer_id RETURN -3;
    IF @addr_zone <> @order_zone RETURN -5;
    IF EXISTS (SELECT 1 FROM Cart WHERE address_id = @address_id AND status = 'Active') RETURN -2;

    SELECT @copyable = COUNT(*)
    FROM CartItem ci
    JOIN Product p ON p.product_id = ci.product_id
    JOIN Business b ON b.business_id = p.business_id
    WHERE ci.cart_id = @old_cart AND p.is_available = 1 AND b.status = 'Active' AND b.zone_id = @addr_zone;
    IF @copyable = 0 RETURN -9;

    EXEC h_SetActiveAddress @customer_id, @address_id;
    INSERT INTO Cart (status, created_at, customer_id, address_id)
    VALUES ('Active', GETDATE(), @customer_id, @address_id);
    SELECT @new_cart = cart_id FROM Cart WHERE address_id = @address_id AND status = 'Active';

    INSERT INTO CartItem (cart_id, product_id, quantity, notes, unit_price)
    SELECT @new_cart, ci.product_id, ci.quantity, ci.notes, NULL
    FROM CartItem ci
    JOIN Product p ON p.product_id = ci.product_id
    JOIN Business b ON b.business_id = p.business_id
    WHERE ci.cart_id = @old_cart AND p.is_available = 1 AND b.status = 'Active' AND b.zone_id = @addr_zone;
    RETURN 0;
END;
GO

-- 4.6.l Submit_Feedback
create procedure Submit_Feedback
    @suborder_id int, @headline varchar(100), @description varchar(500), @rating int
as
begin
    declare @status varchar(20);
    select @status = status from SubOrder where suborder_id = @suborder_id;
    if @status is null or isnull(@headline, '') = ''
       or @rating is null or @rating not between 1 and 5
        return -1;
    if @status <> 'Delivered' return -4;
    if exists (select 1 from Feedback where suborder_id = @suborder_id) return -2;

    insert into Feedback (headline, description, rating, feedback_date, suborder_id)
    values (@headline, @description, @rating, getdate(), @suborder_id);
    return 0;
end;
GO

-- 4.6.m Rate_Rider
create procedure Rate_Rider @suborder_id int, @rider_rating int
as
begin
    declare @status varchar(20), @existing int, @delivery int;
    select @status = status from SubOrder where suborder_id = @suborder_id;
    if @status is null or @rider_rating is null or @rider_rating not between 1 and 5 return -1;
    if @status <> 'Delivered' return -4;
    select @delivery = delivery_id, @existing = rider_rating from Delivery where suborder_id = @suborder_id;
    if @delivery is null return -4;
    if @existing is not null return -2;

    update Delivery set rider_rating = @rider_rating where delivery_id = @delivery;
    return 0;
end;
GO

-- 4.6.n My_Order_History
CREATE FUNCTION My_Order_History (@customer_id INT)
RETURNS TABLE
as
RETURN
(
    select o.order_id,
           o.order_date,
           z.zone_name,
           o.status,
           (select count(*) from SubOrder s where s.order_id = o.order_id) as number_of_suborders,
           o.discount_amount,
           o.total_amount,
           p.method as payment_method,
           p.refunded_amount
    from Orders o
    join Cart c on c.cart_id = o.cart_id
    join Zone z on z.zone_id = o.zone_id
    left join Payment p on p.order_id = o.order_id
    where c.customer_id = @customer_id
);
GO

-- 4.6.o Toggle_Favorite
create procedure Toggle_Favorite @customer_id int, @item_id int, @item_type varchar(20)
as
begin
    if not exists (select 1 from Customer where customer_id = @customer_id) return -3;
    if @item_type is null or @item_type not in ('Business', 'Product') return -1;

    if @item_type = 'Business'
    begin
        if not exists (select 1 from Business where business_id = @item_id) return -1;
        if exists (select 1 from Favorite_Business where customer_id = @customer_id and business_id = @item_id)
            delete from Favorite_Business where customer_id = @customer_id and business_id = @item_id;
        else
            insert into Favorite_Business (customer_id, business_id) values (@customer_id, @item_id);
    end
    else
    begin
        if not exists (select 1 from Product where product_id = @item_id) return -1;
        if exists (select 1 from Favorite_Product where customer_id = @customer_id and product_id = @item_id)
            delete from Favorite_Product where customer_id = @customer_id and product_id = @item_id;
        else
            insert into Favorite_Product (customer_id, product_id) values (@customer_id, @item_id);
    end
    return 0;
end;
GO

-- 4.6.p My_Favorites
CREATE FUNCTION My_Favorites (@customer_id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT p.product_id,
           p.name AS product_name,
           b.name AS business_name,
           CASE WHEN p.is_available = 1 AND b.status = 'Active' THEN 1 ELSE 0 END AS is_orderable
    FROM Favorite_Product fp
    JOIN Product p ON p.product_id = fp.product_id
    JOIN Business b ON b.business_id = p.business_id
    WHERE fp.customer_id = @customer_id
);
GO

-- 4.6.q Recommended_Products
CREATE FUNCTION Recommended_Products (@customer_id INT)
RETURNS TABLE
as
RETURN
(
    select top 10
           p.product_id,
           p.name as product_name,
           b.name as business_name,
           p.category,
           p.price - p.discount_amount as final_price
    from Product p
    join Business b on b.business_id = p.business_id
    join Address a on a.customer_id = @customer_id and a.is_active = 1 and a.zone_id = b.zone_id
    join (select p2.category, count(*) as times_ordered
          from Orders o
          join Cart c on c.cart_id = o.cart_id and c.customer_id = @customer_id
          join CartItem ci on ci.cart_id = c.cart_id
          join Product p2 on p2.product_id = ci.product_id
          group by p2.category) cat on cat.category = p.category
    where p.is_available = 1
      and b.status = 'Active'
      and not exists (select 1
                      from Orders o
                      join Cart c on c.cart_id = o.cart_id and c.customer_id = @customer_id
                      join CartItem ci on ci.cart_id = c.cart_id
                      where ci.product_id = p.product_id)
    order by cat.times_ordered desc, p.product_id asc
);
GO

-- 4.7.a Set_Rider_Availability
CREATE PROCEDURE Set_Rider_Availability @rider_id INT, @is_available BIT
as
BEGIN
    IF not exists (select 1 from Rider where rider_id = @rider_id) RETURN -3;
    IF @is_available is null RETURN -1;

    update Rider set is_available = @is_available where rider_id = @rider_id;
    RETURN 0;
END;
GO

-- 4.7.b My_Active_Deliveries
CREATE FUNCTION My_Active_Deliveries (@rider_id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT d.delivery_id,
           o.order_id,
           s.suborder_id,
           b.name AS business_name,
           u.first_name + ' ' + u.last_name AS customer_name,
           a.description AS address_description,
           z.zone_name,
           s.status,
           d.assigned_at
    FROM Delivery d
    JOIN SubOrder s ON s.suborder_id = d.suborder_id AND s.status IN ('Assigned', 'Picked Up')
    JOIN Orders o ON o.order_id = s.order_id
    JOIN Business b ON b.business_id = s.business_id
    JOIN Cart c ON c.cart_id = o.cart_id
    JOIN Users u ON u.user_id = c.customer_id
    JOIN Address a ON a.address_id = c.address_id
    JOIN Zone z ON z.zone_id = o.zone_id
    WHERE d.rider_id = @rider_id
);
GO

-- 4.7.c Mark_Picked_Up
CREATE PROCEDURE Mark_Picked_Up @delivery_id INT
AS
BEGIN
    DECLARE @sub INT, @order INT, @status VARCHAR(20);
    SELECT @sub = d.suborder_id, @order = s.order_id, @status = s.status
    FROM Delivery d JOIN SubOrder s ON s.suborder_id = d.suborder_id
    WHERE d.delivery_id = @delivery_id;
    IF @sub IS NULL RETURN -1;
    IF @status <> 'Assigned' RETURN -4;

    UPDATE SubOrder SET status = 'Picked Up' WHERE suborder_id = @sub;
    UPDATE Delivery SET picked_up_at = GETDATE() WHERE delivery_id = @delivery_id;
    EXEC h_RecomputeOrderStatus @order;
    RETURN 0;
END;
GO

-- 4.7.d Mark_Delivered
CREATE PROCEDURE Mark_Delivered @delivery_id INT
as
BEGIN
    DECLARE @sub INT, @order INT, @status VARCHAR(20), @picked DATETIME, @now DATETIME = GETDATE();
    select @sub = d.suborder_id, @order = s.order_id, @status = s.status, @picked = d.picked_up_at
    from Delivery d join SubOrder s on s.suborder_id = d.suborder_id
    where d.delivery_id = @delivery_id;
    IF @sub is null RETURN -1;
    IF @status <> 'Picked Up' RETURN -4;

    update SubOrder set status = 'Delivered' where suborder_id = @sub;
    update Delivery
    set delivered_at = @now, tracking_time = DATEDIFF(MINUTE, @picked, @now)
    where delivery_id = @delivery_id;
    EXEC h_RecomputeOrderStatus @order;
    RETURN 0;
END;
GO

-- 4.7.e My_Earnings
CREATE FUNCTION My_Earnings (@rider_id INT, @from_date DATE, @to_date DATE)
RETURNS TABLE
AS
RETURN
(
    SELECT COUNT(d.delivery_id) AS completed_deliveries,
           ISNULL(SUM(s.delivery_fee), 0) AS total_delivery_fees,
           CAST(ISNULL(SUM(s.delivery_fee), 0) * 0.80 AS DECIMAL(10,2)) AS total_earnings
    FROM Delivery d
    JOIN SubOrder s ON s.suborder_id = d.suborder_id AND s.status = 'Delivered'
    WHERE d.rider_id = @rider_id
      AND @from_date <= @to_date
      AND CAST(d.delivered_at AS DATE) BETWEEN @from_date AND @to_date
);
GO

-- 4.7.f My_Rating_Summary
create function My_Rating_Summary (@rider_id int)
returns table
as
return
(
    select cast(avg(rider_rating * 1.0) as decimal(10,2)) as avg_rating,
           count(rider_rating) as ratings_count,
           count(case when rider_rating = 5 then 1 end) as five_star,
           count(case when rider_rating = 4 then 1 end) as four_star,
           count(case when rider_rating = 3 then 1 end) as three_star,
           count(case when rider_rating = 2 then 1 end) as two_star,
           count(case when rider_rating = 1 then 1 end) as one_star
    from Delivery
    where rider_id = @rider_id
);
GO

-- 4.7.g My_Delivery_History
CREATE FUNCTION My_Delivery_History (@rider_id INT, @from_date DATE, @to_date DATE)
RETURNS TABLE
as
RETURN
(
    select d.delivery_id,
           s.order_id,
           b.name as business_name,
           s.status,
           d.assigned_at,
           d.picked_up_at,
           d.delivered_at,
           d.tracking_time
    from Delivery d
    join SubOrder s on s.suborder_id = d.suborder_id and s.status in ('Delivered', 'Cancelled')
    join Business b on b.business_id = s.business_id
    where d.rider_id = @rider_id
      and @from_date <= @to_date
      and CAST(d.assigned_at as DATE) between @from_date and @to_date
);
GO

-- 4.8.a Search_Platform
CREATE FUNCTION Search_Platform (@customer_id INT, @keyword VARCHAR(100))
RETURNS TABLE
as
RETURN
(
    select top 1000000
           b.business_id,
           b.name as business_name,
           CASE WHEN b.name = @keyword THEN 1
                WHEN b.name like @keyword + '%' THEN 2
                ELSE 3 END as priority
    from Business b
    join Address a on a.customer_id = @customer_id and a.is_active = 1 and a.zone_id = b.zone_id
    where b.status = 'Active'
      and isnull(@keyword, '') <> ''
      and b.name like '%' + @keyword + '%'
    order by CASE WHEN b.name = @keyword THEN 1
                  WHEN b.name like @keyword + '%' THEN 2
                  ELSE 3 END,
             b.business_id
);
GO

-- 4.8.b Reconcile_Order_Totals
CREATE FUNCTION Reconcile_Order_Totals ()
RETURNS TABLE
as
RETURN
(
    select x.order_id,
           x.expected_total,
           x.total_amount as order_total,
           p.amount as payment_amount
    from (select o.order_id, o.total_amount,
                 isnull((select sum(s.total_price + s.delivery_fee) from SubOrder s
                         where s.order_id = o.order_id), 0) - o.discount_amount as expected_total
          from Orders o) x
    left join Payment p on p.order_id = x.order_id
    where x.total_amount <> x.expected_total
       or p.payment_id is null
       or p.amount <> x.total_amount
);
GO

-- 4.8.c Nearby_Businesses_By_Category
CREATE FUNCTION Nearby_Businesses_By_Category (@address_id INT, @product_category VARCHAR(50))
RETURNS TABLE
as
RETURN
(
    select top 1000000
           b.business_id,
           b.name as business_name,
           z.zone_name,
           CASE WHEN b.zone_id = a.zone_id THEN 1 ELSE 0 END as same_zone,
           (select CAST(avg(d.tracking_time * 1.0) as DECIMAL(10,2))
            from Delivery d
            inner join SubOrder s on s.suborder_id = d.suborder_id and s.status = 'Delivered'
            inner join Orders o on o.order_id = s.order_id
            where o.zone_id = b.zone_id) as zone_avg_delivery_time
    from Business b
    inner join Zone z on z.zone_id = b.zone_id
    inner join Address a on a.address_id = @address_id
    where b.status = 'Active'
      and exists (select 1 from Product p
                  where p.business_id = b.business_id and p.is_available = 1
                    and p.category = @product_category)
    order by CASE WHEN b.zone_id = a.zone_id THEN 1 ELSE 0 END desc,
             zone_avg_delivery_time asc,
             b.business_id asc
);
GO

-- 4.8.d Platform_Health_Snapshot
CREATE FUNCTION Platform_Health_Snapshot ()
RETURNS TABLE
AS
RETURN
(
    SELECT (SELECT COUNT(*) FROM Business WHERE status = 'Active') AS active_businesses,
           (SELECT COUNT(*) FROM Rider r JOIN Users u ON u.user_id = r.rider_id
            WHERE r.is_available = 1 AND u.account_status = 'Active') AS available_riders,
           (SELECT COUNT(*) FROM Orders WHERE CAST(order_date AS DATE) = CAST(GETDATE() AS DATE)) AS orders_today,
           (SELECT CAST(AVG(d.tracking_time * 1.0) AS DECIMAL(10,2))
            FROM Delivery d WHERE d.tracking_time IS NOT NULL
              AND CAST(d.delivered_at AS DATE) = CAST(GETDATE() AS DATE)) AS avg_delivery_time_today,
           (SELECT COUNT(*) FROM Feedback
            WHERE rating <= 2 AND CAST(feedback_date AS DATE) = CAST(GETDATE() AS DATE)) AS low_ratings_today
);
GO

-- h_GetUserId
create function h_GetUserId (@username varchar(30))
returns int
as
begin
    declare @user_id int;
    select @user_id = user_id from Users where username = @username;
    return @user_id;
end;
GO

-- h_ZoneList
create view h_ZoneList
as
select zone_id, zone_name, delivery_fee
from Zone;
GO

-- h_AdminProfile
CREATE FUNCTION h_AdminProfile (@admin_id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT a.admin_id,
           u.first_name + ' ' + u.last_name AS admin_name,
           a.role,
           a.zone_id,
           z.zone_name
    FROM Admin a
    INNER JOIN Users u ON u.user_id = a.admin_id
    LEFT JOIN Zone z ON z.zone_id = a.zone_id
    WHERE a.admin_id = @admin_id
);
GO

-- h_AdminList
CREATE VIEW h_AdminList
AS
SELECT a.admin_id,
       u.first_name + ' ' + u.last_name AS admin_name,
       u.username,
       a.role,
       z.zone_name
FROM Admin a
INNER JOIN Users u ON u.user_id = a.admin_id
LEFT JOIN Zone z ON z.zone_id = a.zone_id;
GO

-- h_CustomerList
create view h_CustomerList
as
select c.customer_id,
       u.first_name + ' ' + u.last_name as customer_name,
       u.username,
       u.email,
       u.account_status,
       z.zone_name as active_zone
from Customer c
inner join Users u on u.user_id = c.customer_id
left join Address a on a.customer_id = c.customer_id and a.is_active = 1
left join Zone z on z.zone_id = a.zone_id;
GO

-- h_BlacklistedCustomers
CREATE VIEW h_BlacklistedCustomers
as
select bl.customer_id,
       cu.first_name + ' ' + cu.last_name as customer_name,
       bl.reason,
       bl.admin_id,
       au.first_name + ' ' + au.last_name as blacklisted_by
from Blacklist bl
inner join Users cu on cu.user_id = bl.customer_id
inner join Users au on au.user_id = bl.admin_id;
GO

-- h_SuspendedBusinesses
create view h_SuspendedBusinesses
as
select b.business_id,
       b.name as business_name,
       z.zone_name,
       b.suspension_reason
from Business b
inner join Zone z on z.zone_id = b.zone_id
where b.status = 'Suspended';
GO

-- h_MyBusiness
create function h_MyBusiness (@partner_id int)
returns table
as
return
(
    select b.business_id,
           b.name as business_name,
           b.description,
           b.link_website,
           case when r.business_id is not null then 'Restaurant' else 'Pharmacy' end as business_type,
           r.cuisine_type,
           r.food_category,
           ph.pharmacy_type,
           b.zone_id,
           z.zone_name,
           b.opening_hour,
           b.closing_hour,
           b.expected_delivery_time,
           b.status,
           b.suspension_reason
    from Business b
    inner join Zone z on z.zone_id = b.zone_id
    left join Restaurant r on r.business_id = b.business_id
    left join Pharmacy ph on ph.business_id = b.business_id
    where b.partner_id = @partner_id
);
GO

-- h_BusinessPhones
CREATE FUNCTION h_BusinessPhones (@business_id INT)
RETURNS TABLE
as
RETURN
(
    select phone from Business_Phone where business_id = @business_id
);
GO

-- h_MyProducts
create function h_MyProducts (@partner_id int)
returns table
as
return
(
    select p.product_id,
           p.name as product_name,
           p.description,
           p.category,
           p.price,
           p.discount_amount,
           p.price - p.discount_amount as final_price,
           p.is_available
    from Product p
    inner join Business b on b.business_id = p.business_id
    where b.partner_id = @partner_id
);
GO

-- h_RiderProfile
CREATE FUNCTION h_RiderProfile (@rider_id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT r.rider_id,
           u.first_name + ' ' + u.last_name AS rider_name,
           z.zone_name,
           r.vehicle_type,
           r.plate_no,
           r.is_available,
           u.account_status
    FROM Rider r
    INNER JOIN Users u ON u.user_id = r.rider_id
    INNER JOIN Zone z ON z.zone_id = r.zone_id
    WHERE r.rider_id = @rider_id
);
GO

-- h_CustomerProfile
CREATE FUNCTION h_CustomerProfile (@customer_id INT)
RETURNS TABLE
as
RETURN
(
    select c.customer_id,
           u.first_name + ' ' + u.last_name as customer_name,
           u.account_status,
           c.wallet_balance,
           a.address_id as active_address_id,
           a.description as active_address,
           z.zone_id as active_zone_id,
           z.zone_name as active_zone
    from Customer c
    inner join Users u on u.user_id = c.customer_id
    left join Address a on a.customer_id = c.customer_id and a.is_active = 1
    left join Zone z on z.zone_id = a.zone_id
    where c.customer_id = @customer_id
);
GO

-- h_MyAddresses
create function h_MyAddresses (@customer_id int)
returns table
as
return
(
    select a.address_id, a.description, a.zone_id, z.zone_name, a.is_active
    from Address a
    inner join Zone z on z.zone_id = a.zone_id
    where a.customer_id = @customer_id
);
GO

-- h_MyCards
CREATE FUNCTION h_MyCards (@customer_id INT)
RETURNS TABLE
as
RETURN
(
    select card_id,
           card_holder_name,
           RIGHT(card_no, 4) as last_four_digits,
           expiration_date
    from Card
    where customer_id = @customer_id
);
GO

-- h_MyActiveCart
CREATE FUNCTION h_MyActiveCart (@customer_id INT)
RETURNS INT
as
BEGIN
    DECLARE @cart_id INT;
    select @cart_id = c.cart_id
    from Cart c
    inner join Address a on a.address_id = c.address_id
    where c.customer_id = @customer_id and c.status = 'Active' and a.is_active = 1;
    RETURN @cart_id;
END;
GO

-- h_CartItems
CREATE FUNCTION h_CartItems (@cart_id INT)
RETURNS TABLE
as
RETURN
(
    select ci.product_id,
           p.name as product_name,
           b.business_id,
           b.name as business_name,
           ci.quantity,
           ci.notes,
           p.price - p.discount_amount as unit_price,
           ci.quantity * (p.price - p.discount_amount) as line_total,
           p.is_available
    from CartItem ci
    inner join Product p on p.product_id = ci.product_id
    inner join Business b on b.business_id = p.business_id
    where ci.cart_id = @cart_id
);
GO

-- h_MyVouchers
CREATE FUNCTION h_MyVouchers (@customer_id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT voucher_id, promo_code, is_percentage, amount, expiry_date
    FROM Voucher
    WHERE customer_id = @customer_id AND status = 'Unused'
      AND expiry_date >= CAST(GETDATE() AS DATE)
);
GO

-- h_BusinessDetails
create function h_BusinessDetails (@business_id int)
returns table
as
return
(
    select b.business_id,
           b.name as business_name,
           b.description,
           b.link_website,
           z.zone_name,
           b.opening_hour,
           b.closing_hour,
           dbo.h_IsBusinessOpen(b.opening_hour, b.closing_hour, cast(getdate() as time)) as is_open_now,
           b.expected_delivery_time,
           b.status,
           (select cast(avg(f.rating * 1.0) as decimal(10,2))
            from Feedback f inner join SubOrder s on s.suborder_id = f.suborder_id
            where s.business_id = b.business_id) as avg_rating,
           (select count(*)
            from Feedback f inner join SubOrder s on s.suborder_id = f.suborder_id
            where s.business_id = b.business_id) as number_of_ratings
    from Business b
    inner join Zone z on z.zone_id = b.zone_id
    where b.business_id = @business_id
);
GO

-- h_BusinessProducts
CREATE FUNCTION h_BusinessProducts (@business_id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT p.product_id,
           p.name AS product_name,
           p.description,
           p.category,
           p.price,
           p.discount_amount,
           p.price - p.discount_amount AS final_price
    FROM Product p
    INNER JOIN Business b ON b.business_id = p.business_id
    WHERE p.business_id = @business_id AND p.is_available = 1 AND b.status = 'Active'
);
GO

-- h_OrderSubOrders
create function h_OrderSubOrders (@order_id int)
returns table
as
return
(
    select s.suborder_id,
           b.business_id,
           b.name as business_name,
           s.status,
           s.total_price,
           s.delivery_fee,
           d.delivery_id,
           ru.first_name + ' ' + ru.last_name as rider_name,
           d.assigned_at,
           d.picked_up_at,
           d.delivered_at,
           b.expected_delivery_time,
           case when exists (select 1 from Feedback f where f.suborder_id = s.suborder_id)
                then 1 else 0 end as has_feedback,
           d.rider_rating
    from SubOrder s
    inner join Business b on b.business_id = s.business_id
    left join Delivery d on d.suborder_id = s.suborder_id
    left join Users ru on ru.user_id = d.rider_id
    where s.order_id = @order_id
);
GO
