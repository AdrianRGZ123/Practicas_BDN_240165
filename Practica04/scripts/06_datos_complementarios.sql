/* ============================================================
   PRÁCTICA 04 - 06. DATOS COMPLEMENTARIOS (ejecutar después de los 5 casos)
   - tbd_users_wishlist_products: 3 productos en listas de deseos.
   - tb_seller_orders: réplica de tbd_buyer_orders (mismos ID y datos).
   Ejecutar como: adrian.rios (superadmin).
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;

INSERT INTO tbd_users_wishlist_products (user_ID, product_ID, last_update)
VALUES (1500, 120, NOW()), (5100, 3500, NOW()), (7400, 9000, NOW());

INSERT INTO tb_seller_orders (ID, seller_ID, subtotal, shipping_cost, fulfillment_status, status, creation_date, last_update)
SELECT ID, seller_ID, subtotal, shipping_cost, fulfillment_status, status, creation_date, last_update FROM tbd_buyer_orders;
