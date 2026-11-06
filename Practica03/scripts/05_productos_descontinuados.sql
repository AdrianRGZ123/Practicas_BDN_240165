/* ============================================================
   PRÁCTICA 03 · Productos descontinuados (status = b'0')
   Actualmente todos los productos están en b'1'; la práctica pide incorporar descontinuados.
   Marca como descontinuado 1 de cada 25 productos (~4 %). Los triggers AFTER UPDATE
   registran cada cambio en tb_logs con la cuenta que ejecuta el script.
   ============================================================ */
USE db_test;

UPDATE tb_products SET status = b'0' WHERE MOD(id, 25) = 0 AND status = b'1';

SELECT SUM(status = b'1') AS activos, SUM(status = b'0') AS descontinuados, COUNT(*) AS total
FROM tb_products;
