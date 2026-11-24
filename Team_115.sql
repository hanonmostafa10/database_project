-- Team 115 - Milestone 3 helpers
-- Run after the given database script and seed_data.sql.
-- Only read-only helpers for the website pages; no Milestone 2 logic is changed.

USE LocalDeliveryMarketplace_Team_00;
GO

-- h_ProductCategories
-- The product categories a customer can browse by (3.6 a, Nearby_Businesses_By_Category):
-- categories that have at least one available product of an active business.
DROP VIEW IF EXISTS h_ProductCategories;
GO
CREATE VIEW h_ProductCategories
AS
SELECT DISTINCT p.category
FROM Product p
INNER JOIN Business b ON b.business_id = p.business_id
WHERE p.is_available = 1 AND b.status = 'Active';
GO

-- h_MyFavoriteBusinesses
-- My favorite businesses (3.6 b): My_Favorites only lists products, so the website
-- needs this to show which businesses are in my favorites and to remove them.
DROP FUNCTION IF EXISTS h_MyFavoriteBusinesses;
GO
CREATE FUNCTION h_MyFavoriteBusinesses (@customer_id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT b.business_id,
           b.name AS business_name,
           z.zone_name,
           b.status
    FROM Favorite_Business fb
    INNER JOIN Business b ON b.business_id = fb.business_id
    INNER JOIN Zone z ON z.zone_id = b.zone_id
    WHERE fb.customer_id = @customer_id
);
GO
