/* ============================================================
   CASO DE PRUEBA 3: "Compra exitosa con cancelación parcial, ajuste y reembolso parcial"
   PARTE 1 (pasos 1 a 5) - Conexión: app_web  (rol user_not_registered; buyer al pagar)
   Usuario ya registrado: ID 5100 (John Williams)
   ============================================================ */
SET NAMES utf8mb4;
USE db_test;
SELECT CURRENT_USER() AS usuario_conexion, CURRENT_ROLE() AS rol_activo;
SET @uid = 5100;

/* PASO 1. Carrito con 3 productos de la MISMA categoría, cantidades de 1 a 10 unidades */
SET @cat = (SELECT pc.category_ID
            FROM tbd_products_categories pc JOIN vw_available_products v ON v.product_ID = pc.product_ID
            WHERE v.current_stock >= 10
            GROUP BY pc.category_ID HAVING COUNT(*) >= 3
            ORDER BY pc.category_ID LIMIT 1 OFFSET 6);
SELECT ID AS category_ID, name AS categoria FROM tbc_categories WHERE ID = @cat;
INSERT INTO tb_carts (user_ID) VALUES (@uid);
SET @cart = LAST_INSERT_ID();
INSERT INTO tbd_cart_items (cart_ID, provider_ID, product_ID, quantity)
SELECT @cart, x.provider_ID, x.product_ID, 1 + MOD(x.product_ID, 10)
FROM (SELECT v.provider_ID, v.product_ID
      FROM vw_available_products v JOIN tbd_products_categories pc ON pc.product_ID = v.product_ID
      WHERE pc.category_ID = @cat AND v.current_stock >= 10
      ORDER BY MD5(CONCAT('caso3-', v.product_ID)) LIMIT 3) x;
SELECT ci.product_ID, p.name, ci.quantity, p.current_price, ci.quantity * p.current_price AS importe
FROM tbd_cart_items ci JOIN tb_products p ON p.id = ci.product_ID WHERE ci.cart_ID = @cart;

/* PASO 2. Realiza la orden de compra */
CALL sp_create_order_from_cart(@uid, @order);
SELECT * FROM vw_cart_to_order WHERE cart_ID = @cart;

/* PASO 3. Domicilio de envío en un lugar que no es su hogar: etiqueta "Casa Papas" */
CALL sp_register_address(@uid, 'Casa Papas', 'Robert Williams', '+52 2281345670', 'Los papás recibirán el pedido; preguntar por Robert', 0,
     'Veracruz', 'Xalapa', 'Xalapa-Enríquez', 'Xalapa Centro', '91000', 'Salud', 'Calle Enríquez', '58', NULL, @addr);
CALL sp_set_order_address(@order, @addr);
SELECT * FROM vw_user_addresses_full WHERE address_ID = @addr;

/* PASO 4. Método de pago: tarjeta digital Spin (cuenta simulada de 16 dígitos) */
SET @card = '7312904455186027';
INSERT INTO tbd_user_payment_methods (user_ID, payment_method_type_ID, provider, provider_method_ref, label, last_four, is_default)
SELECT @uid, ID, 'Spin', @card, 'Spin John', RIGHT(@card, 4), 0
FROM tbc_payment_methods_types WHERE code = 'DIGITAL_CARD';
SET @upm = LAST_INSERT_ID();
SELECT m.ID, t.code AS tipo, m.provider, m.provider_method_ref AS cuenta_16_digitos FROM tbd_user_payment_methods m
JOIN tbc_payment_methods_types t ON t.ID = m.payment_method_type_ID WHERE m.ID = @upm;

/* PASO 5. Registra un solo pago en efectivo por el costo total de la compra (rol buyer) */
SET ROLE 'buyer';
SELECT CURRENT_ROLE() AS rol_activo;
CALL sp_register_payment(@order, @upm, 1, 'CASH', @pay);
SELECT p.ID, p.order_ID, p.amount, pm.name AS forma_de_pago, p.payment_status, p.user_payment_method_ID
FROM tb_payments p JOIN tb_payment_methods pm ON pm.ID = p.payment_method_ID WHERE p.ID = @pay;
