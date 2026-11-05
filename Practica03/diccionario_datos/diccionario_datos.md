# Diccionario de datos — `db_test`

> Fuente: `Respaldo 29-10-26.sql`. Generado automáticamente desde el DDL del respaldo (MySQL 8.0.42, volcado 2026-11-04). Los conteos de registros se obtuvieron contando las sentencias `INSERT` del mismo respaldo; no se reproducen datos.

## Índice

1. [Resumen ejecutivo](#resumen-ejecutivo)
2. [Tablas y columnas](#tablas-y-columnas)
3. [Vistas](#vistas)
4. [Triggers](#triggers)
5. [Procedimientos almacenados](#procedimientos-almacenados)
6. [Funciones almacenadas](#funciones-almacenadas)
7. [Dominios y convenciones](#dominios-y-convenciones)
8. [Observaciones de diseño](#observaciones-de-diseño)
9. [Pendientes por confirmar](#pendientes-por-confirmar)

## Resumen ejecutivo

| Elemento | Conteo |
|---|---:|
| Tablas | 27 |
| Vistas | 29 |
| Triggers | 85 |
| Procedimientos | 15 |
| Funciones | 6 |
| Relaciones FK | 42 |

Registros por tabla (según los `INSERT` del respaldo):

| Tabla | Registros |
|---|---:|
| `tb_logs` | 83 804 |
| `tbd_products_categories` | 23 020 |
| `tb_products` | 15 007 |
| `tbd_products_users_providers` | 15 007 |
| `tb_users` | 10 240 |
| `tb_people` | 10 226 |
| `tbc_categories` | 100 |
| `tbd_address_components` | 7 |
| `tb_shipments` | 5 |
| `tbd_buyer_orders` | 5 |
| `tbd_cart_items` | 5 |
| `tb_payment_methods` | 4 |
| `tbc_payment_methods_types` | 4 |
| `tb_payment_transaction` | 2 |
| `tb_orders` | 1 |
| `tb_payments` | 1 |
| `tb_user_addresses` | 1 |
| `tbd_user_payment_methods` | 1 |
| `tb_carts` | 0 |
| `tb_order_cancellations` | 0 |
| `tb_refunds` | 0 |
| `tb_returns` | 0 |
| `tb_seller_orders` | 0 |
| `tbd_cancellation_items` | 0 |
| `tbd_order_items` | 0 |
| `tbd_return_items` | 0 |
| `tbd_users_wishlist_products` | 0 |

## Tablas y columnas

### `tb_carts`

- **Prefijo/tipo:** tb_ (principal). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 0.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `int unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de carts. | Obligatorio; Identificador |
| 2 | `user_ID` | `int` | NO | — | — | FK | Referencia a `tb_users.ID`; vincula el registro de carts con su entidad relacionada. | Obligatorio; Identificador |
| 3 | `status` | `bit(1)` | SÍ | b'1' | — | — | Estado lógico del registro (1 = activo, 0 = inactivo). | Opcional; Cualitativa nominal |
| 4 | `active_user_ID` | `int` | SÍ | — | GENERADA STORED: if((`status` = 0x01),`user_ID`,NULL) | — | Valor calculado automáticamente por el motor a partir de otras columnas. | Opcional; Cuantitativa |
| 5 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 6 | `last_update` | `datetime` | SÍ | NULL | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Opcional; Temporal |

**Restricciones/índices:** PK (`ID`); UNIQUE `uk_cart_active_user` (`active_user_ID`); ÍNDICE `idx_cart_user` (`user_ID`); FK `tb_carts_ibfk_1` (`user_ID`) → `tb_users` (`ID`)
**Relaciones:** `tb_carts_ibfk_1`: `tb_carts` (user_ID) → `tb_users` (ID); Tabla hija `tbd_cart_items` mediante `tbd_cart_items_ibfk_1`
**Triggers asociados:** `trg_tb_carts_after_insert`, `trg_tb_carts_after_update`, `trg_tb_carts_after_delete`

### `tb_logs`

- **Prefijo/tipo:** tb_ (principal). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 83804.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `int` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de logs. | Obligatorio; Identificador |
| 2 | `table_name` | `varchar(100)` | NO | — | — | — | Tabla origen del evento auditado. | Obligatorio; Cualitativa |
| 3 | `operation` | `enum('Create','Read','Update','Delete')` | NO | — | — | — | Tipo de operación registrada. | Obligatorio; Cualitativa nominal |
| 4 | `db_user` | `varchar(80)` | NO | — | — | — | Usuario de base de datos que ejecutó la acción. | Obligatorio; Cualitativa |
| 5 | `description` | `text` | NO | — | — | — | Descripción de logs. | Obligatorio; Cualitativa |
| 6 | `operation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora del evento. | Obligatorio; Temporal |
| 7 | `operation_status` | `bit(1)` | SÍ | b'1' | — | — | Resultado del evento (1 = correcto, 0 = fallido). | Opcional; Cualitativa nominal |

**Restricciones/índices:** PK (`ID`)
**Relaciones:** No hay relaciones FK declaradas.
**Triggers asociados:** Ninguno.

### `tb_order_cancellations`

- **Prefijo/tipo:** tb_ (principal). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 0.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `int unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de order cancellations. | Obligatorio; Identificador |
| 2 | `order_ID` | `int unsigned` | SÍ | NULL | — | FK | Referencia a `tb_orders.ID`; vincula el registro de order cancellations con su entidad relacionada. | Opcional; Identificador |
| 3 | `buyer_order_ID` | `int unsigned` | SÍ | NULL | — | FK | Referencia a `tbd_buyer_orders.ID`; vincula el registro de order cancellations con su entidad relacionada. | Opcional; Identificador |
| 4 | `requested_by_user_ID` | `int` | SÍ | NULL | — | FK | Referencia a `tb_users.ID`; vincula el registro de order cancellations con su entidad relacionada. | Opcional; Identificador |
| 5 | `cancellation_scope` | `enum('WholeOrder','SellerOrder','Items')` | NO | 'WholeOrder' | — | — | Atributo «cancellation scope» de order cancellations. | Obligatorio; Cualitativa nominal |
| 6 | `reason_code` | `varchar(60)` | SÍ | NULL | — | — | Motivo registrado. | Opcional; Cualitativa |
| 7 | `reason_detail` | `varchar(1000)` | SÍ | NULL | — | — | Motivo registrado. | Opcional; Cualitativa |
| 8 | `cancellation_status` | `enum('Requested','Approved','Rejected','Completed')` | NO | 'Requested' | — | — | Estado del flujo de order cancellations. | Obligatorio; Cualitativa nominal |
| 9 | `requested_at` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha/hora asociada a requested at en order cancellations. | Obligatorio; Temporal |
| 10 | `reviewed_at` | `datetime` | SÍ | NULL | — | — | Fecha/hora asociada a reviewed at en order cancellations. | Opcional; Temporal |
| 11 | `completed_at` | `datetime` | SÍ | NULL | — | — | Fecha/hora asociada a completed at en order cancellations. | Opcional; Temporal |
| 12 | `internal_notes` | `varchar(1000)` | SÍ | NULL | — | — | Atributo «internal notes» de order cancellations. | Opcional; Cualitativa |
| 13 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 14 | `last_update` | `datetime` | SÍ | NULL | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Opcional; Temporal |

**Restricciones/índices:** PK (`ID`); ÍNDICE `idx_cancellations_order` (`order_ID`); ÍNDICE `idx_cancellations_buyer_order` (`buyer_order_ID`); ÍNDICE `idx_cancellations_requester` (`requested_by_user_ID`); FK `fk_cancellations_buyer_order` (`buyer_order_ID`) → `tbd_buyer_orders` (`ID`); FK `fk_cancellations_order` (`order_ID`) → `tb_orders` (`ID`); FK `fk_cancellations_requester` (`requested_by_user_ID`) → `tb_users` (`ID`); CHECK `chk_cancellations_target`: `((((`cancellation_scope` = 'WholeOrder') and (`order_ID` is not null) and (`buyer_order_ID` is null)) or ((`cancellation_scope` in ('SellerOrder','Items')) and (`buyer_order_ID` is not null))))`
**Relaciones:** `fk_cancellations_buyer_order`: `tb_order_cancellations` (buyer_order_ID) → `tbd_buyer_orders` (ID); `fk_cancellations_order`: `tb_order_cancellations` (order_ID) → `tb_orders` (ID); `fk_cancellations_requester`: `tb_order_cancellations` (requested_by_user_ID) → `tb_users` (ID); Tabla hija `tb_refunds` mediante `fk_refunds_cancellation`; Tabla hija `tbd_cancellation_items` mediante `fk_cancellation_items_cancellation`
**Triggers asociados:** `trg_tb_order_cancellations_after_insert`, `trg_tb_order_cancellations_after_update`, `trg_tb_order_cancellations_after_delete`

### `tb_orders`

- **Prefijo/tipo:** tb_ (principal). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 1.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `int unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de orders. | Obligatorio; Identificador |
| 2 | `key` | `varchar(40)` | NO | — | — | — | Atributo «key» de orders. | Obligatorio; Cualitativa |
| 3 | `User_ID` | `int` | NO | — | — | FK | Referencia a `tb_users.ID`; vincula el registro de orders con su entidad relacionada. | Obligatorio; Identificador |
| 4 | `total_products` | `int` | NO | — | — | — | Atributo «total products» de orders. | Obligatorio; Cuantitativa |
| 5 | `total_cost` | `decimal(12,2)` | NO | '0.00' | — | — | Atributo «total cost» de orders. | Obligatorio; Cuantitativa |
| 6 | `status_string` | `enum('Registered','Payed','Canceled','Delivered','Devolved','Attended','Sended')` | NO | 'Registered' | — | — | Atributo «status string» de orders. | Obligatorio; Cualitativa nominal |
| 7 | `status` | `bit(1)` | SÍ | b'1' | — | — | Estado lógico del registro (1 = activo, 0 = inactivo). | Opcional; Cualitativa nominal |
| 8 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 9 | `last_update` | `datetime` | SÍ | NULL | — | — | Fecha y hora de la última modificación. | Opcional; Temporal |

**Restricciones/índices:** PK (`ID`); UNIQUE `uk_orders_key` (`key`); ÍNDICE `fk_user_2_idx` (`User_ID`); FK `fk_user_2` (`User_ID`) → `tb_users` (`ID`)
**Relaciones:** `fk_user_2`: `tb_orders` (User_ID) → `tb_users` (ID); Tabla hija `tb_order_cancellations` mediante `fk_cancellations_order`; Tabla hija `tb_payments` mediante `fk_payment_order`; Tabla hija `tbd_buyer_orders` mediante `fk_buyer_orders_order`
**Triggers asociados:** `trg_tb_orders_after_insert`, `trg_tb_orders_after_update`, `trg_tb_orders_after_delete`

### `tb_payment_methods`

- **Prefijo/tipo:** tb_ (principal). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 4.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `int unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de payment methods. | Obligatorio; Identificador |
| 2 | `name` | `varchar(60)` | NO | — | — | — | Nombre de payment methods. | Obligatorio; Cualitativa |
| 3 | `description` | `varchar(255)` | SÍ | NULL | — | — | Descripción de payment methods. | Opcional; Cualitativa |
| 4 | `status` | `bit(1)` | NO | b'1' | — | — | Estado lógico del registro (1 = activo, 0 = inactivo). | Obligatorio; Cualitativa nominal |
| 5 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 6 | `last_update` | `datetime` | SÍ | NULL | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Opcional; Temporal |

**Restricciones/índices:** PK (`ID`); UNIQUE `uk_payment_method_name` (`name`)
**Relaciones:** Tabla hija `tb_payments` mediante `fk_payment_method`
**Triggers asociados:** `trg_tb_payment_methods_after_insert`, `trg_tb_payment_methods_after_update`, `trg_tb_payment_methods_after_delete`

### `tb_payment_transaction`

- **Prefijo/tipo:** tb_ (principal). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 2.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `int unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de payment transaction. | Obligatorio; Identificador |
| 2 | `payment_ID` | `int unsigned` | NO | — | — | FK | Referencia a `tb_payments.ID`; vincula el registro de payment transaction con su entidad relacionada. | Obligatorio; Identificador |
| 3 | `refund_ID` | `int unsigned` | SÍ | NULL | — | FK | Referencia a `tb_refunds.ID`; vincula el registro de payment transaction con su entidad relacionada. | Opcional; Identificador |
| 4 | `transaction_type` | `enum('Authorization','Capture','Charge','Void','Refund','Chargeback','Adjustment')` | NO | — | — | — | Atributo «transaction type» de payment transaction. | Obligatorio; Cualitativa nominal |
| 5 | `transaction_status` | `enum('Pending','Succeeded','Failed')` | NO | 'Pending' | — | — | Estado del flujo de payment transaction. | Obligatorio; Cualitativa nominal |
| 6 | `amount` | `decimal(10,2)` | NO | — | — | — | Monto de la operación. | Obligatorio; Cuantitativa |
| 7 | `currency` | `char(3)` | NO | 'MXN' | — | — | Moneda del importe. | Obligatorio; Cualitativa |
| 8 | `provider` | `varchar(60)` | SÍ | NULL | — | — | Proveedor externo del servicio/medio. | Opcional; Cualitativa |
| 9 | `provider_transaction_id` | `varchar(150)` | SÍ | NULL | — | — | Atributo «provider transaction id» de payment transaction. | Opcional; Cualitativa |
| 10 | `idempotency_key` | `varchar(100)` | SÍ | NULL | — | — | Atributo «idempotency key» de payment transaction. | Opcional; Cualitativa |
| 11 | `response_code` | `varchar(100)` | SÍ | NULL | — | — | Atributo «response code» de payment transaction. | Opcional; Cualitativa |
| 12 | `response_message` | `varchar(500)` | SÍ | NULL | — | — | Atributo «response message» de payment transaction. | Opcional; Cualitativa |
| 13 | `request_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha/hora asociada a request date en payment transaction. | Obligatorio; Temporal |
| 14 | `response_date` | `datetime` | SÍ | NULL | — | — | Fecha/hora asociada a response date en payment transaction. | Opcional; Temporal |
| 15 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 16 | `last_update` | `datetime` | SÍ | NULL | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Opcional; Temporal |

**Restricciones/índices:** PK (`ID`); UNIQUE `uk_payment_transaction_provider_ref` (`provider`, `provider_transaction_id`); UNIQUE `uk_payment_transaction_idempotency` (`provider`, `idempotency_key`); ÍNDICE `idx_payment_transaction_payment` (`payment_ID`); ÍNDICE `idx_payment_transaction_refund` (`refund_ID`); ÍNDICE `fk_payment_transaction_refund_payment` (`refund_ID`, `payment_ID`); FK `fk_payment_transaction_payment` (`payment_ID`) → `tb_payments` (`ID`); FK `fk_payment_transaction_refund_payment` (`refund_ID`, `payment_ID`) → `tb_refunds` (`ID`, `payment_ID`); CHECK `chk_payment_transaction_amount`: `((`amount` > 0))`; CHECK `chk_payment_transaction_refund`: `(((`transaction_type` <> 'Refund') or (`refund_ID` is not null)))`
**Relaciones:** `fk_payment_transaction_payment`: `tb_payment_transaction` (payment_ID) → `tb_payments` (ID); `fk_payment_transaction_refund_payment`: `tb_payment_transaction` (refund_ID, payment_ID) → `tb_refunds` (ID, payment_ID)
**Triggers asociados:** `trg_tb_payment_transaction_after_insert`, `trg_tb_payment_transaction_after_update`, `trg_tb_payment_transaction_after_delete`

### `tb_payments`

- **Prefijo/tipo:** tb_ (principal). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 1.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `int unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de payments. | Obligatorio; Identificador |
| 2 | `order_ID` | `int unsigned` | NO | — | — | FK | Referencia a `tb_orders.ID`; vincula el registro de payments con su entidad relacionada. | Obligatorio; Identificador |
| 3 | `payment_method_ID` | `int unsigned` | NO | — | — | FK | Referencia a `tb_payment_methods.ID`; vincula el registro de payments con su entidad relacionada. | Obligatorio; Identificador |
| 4 | `user_payment_method_ID` | `bigint unsigned` | SÍ | NULL | — | FK | Referencia a `tbd_user_payment_methods.ID`; vincula el registro de payments con su entidad relacionada. | Opcional; Identificador |
| 5 | `amount` | `decimal(10,2)` | NO | — | — | — | Monto de la operación. | Obligatorio; Cuantitativa |
| 6 | `currency` | `char(3)` | NO | 'MXN' | — | — | Moneda del importe. | Obligatorio; Cualitativa |
| 7 | `payment_status` | `enum('Pending','Authorized','Paid','Failed','Refunded','PartiallyRefunded')` | NO | 'Pending' | — | — | Estado del flujo de payments. | Obligatorio; Cualitativa nominal |
| 8 | `provider` | `varchar(60)` | SÍ | NULL | — | — | Proveedor externo del servicio/medio. | Opcional; Cualitativa |
| 9 | `provider_reference` | `varchar(150)` | SÍ | NULL | — | — | Referencia externa asignada por el proveedor. | Opcional; Cualitativa |
| 10 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 11 | `paid_date` | `datetime` | SÍ | NULL | — | — | Fecha/hora asociada a paid date en payments. | Opcional; Temporal |
| 12 | `last_update` | `datetime` | SÍ | NULL | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Opcional; Temporal |

**Restricciones/índices:** PK (`ID`); UNIQUE `uk_payment_provider_reference` (`provider`, `provider_reference`); ÍNDICE `idx_payment_order` (`order_ID`); ÍNDICE `fk_payment_method` (`payment_method_ID`); ÍNDICE `idx_payment_user_method` (`user_payment_method_ID`); FK `fk_payment_method` (`payment_method_ID`) → `tb_payment_methods` (`ID`); FK `fk_payment_order` (`order_ID`) → `tb_orders` (`ID`); FK `fk_payment_user_method` (`user_payment_method_ID`) → `tbd_user_payment_methods` (`ID`); CHECK `chk_payment_amount`: `((`amount` > 0))`
**Relaciones:** `fk_payment_method`: `tb_payments` (payment_method_ID) → `tb_payment_methods` (ID); `fk_payment_order`: `tb_payments` (order_ID) → `tb_orders` (ID); `fk_payment_user_method`: `tb_payments` (user_payment_method_ID) → `tbd_user_payment_methods` (ID); Tabla hija `tb_payment_transaction` mediante `fk_payment_transaction_payment`; Tabla hija `tb_refunds` mediante `fk_refunds_payment`
**Triggers asociados:** `trg_tb_payments_after_insert`, `trg_tb_payments_after_update`, `trg_tb_payments_after_delete`

### `tb_people`

- **Prefijo/tipo:** tb_ (principal). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 10226.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `person_ID` | `bigint unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de people. | Obligatorio; Identificador |
| 2 | `user_ID` | `int` | SÍ | NULL | — | FK | Referencia a `tb_users.ID`; vincula el registro de people con su entidad relacionada. | Opcional; Identificador |
| 3 | `courtesy_title` | `varchar(20)` | SÍ | NULL | — | — | Atributo «courtesy title» de people. | Opcional; Cualitativa |
| 4 | `given_names` | `varchar(150)` | NO | — | — | — | Nombre(s) de pila. | Obligatorio; Cualitativa |
| 5 | `family_names` | `varchar(150)` | SÍ | NULL | — | — | Apellidos. | Opcional; Cualitativa |
| 6 | `birth_date` | `date` | SÍ | NULL | — | — | Fecha de nacimiento. | Opcional; Temporal |
| 7 | `gender_ID` | `tinyint unsigned` | SÍ | NULL | — | — | Atributo «gender ID» de people. | Opcional; Cuantitativa |
| 8 | `country_code` | `char(2)` | SÍ | NULL | — | — | Código de país (ISO de 2 letras). | Opcional; Cualitativa |
| 9 | `phone` | `varchar(25)` | SÍ | NULL | — | — | Teléfono de contacto. | Opcional; Cualitativa |
| 10 | `status` | `bit(1)` | SÍ | b'1' | — | — | Estado lógico del registro (1 = activo, 0 = inactivo). | Opcional; Cualitativa nominal |
| 11 | `creation_date` | `datetime` | SÍ | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Opcional; Temporal |
| 12 | `last_update` | `datetime` | SÍ | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Opcional; Temporal |

**Restricciones/índices:** PK (`person_ID`); UNIQUE `user_ID` (`user_ID`); FK `fk_persons_users` (`user_ID`) → `tb_users` (`ID`)
**Relaciones:** `fk_persons_users`: `tb_people` (user_ID) → `tb_users` (ID)
**Triggers asociados:** `trg_tb_people_after_insert`, `trg_tb_people_after_update`, `trg_tb_people_after_delete`

### `tb_products`

- **Prefijo/tipo:** tb_ (principal). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 15007.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `id` | `int unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de products. | Obligatorio; Identificador |
| 2 | `sku` | `varchar(50)` | NO | — | — | — | Código de inventario del producto (único). | Obligatorio; Cualitativa |
| 3 | `name` | `varchar(250)` | NO | — | — | — | Nombre de products. | Obligatorio; Cualitativa |
| 4 | `description` | `text` | SÍ | — | — | — | Descripción de products. | Opcional; Cualitativa |
| 5 | `current_price` | `decimal(10,2)` | NO | '0.00' | — | — | Precio vigente del producto. | Obligatorio; Cuantitativa |
| 6 | `current_stock` | `int unsigned` | NO | '0' | — | — | Existencias disponibles. | Obligatorio; Cuantitativa |
| 7 | `status` | `bit(1)` | SÍ | b'1' | — | — | Estado lógico del registro (1 = activo, 0 = inactivo). | Opcional; Cualitativa nominal |
| 8 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 9 | `last_update` | `datetime` | NO | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Obligatorio; Temporal |

**Restricciones/índices:** PK (`id`); UNIQUE `sku` (`sku`)
**Relaciones:** Tabla hija `tbd_products_categories` mediante `fk_product`; Tabla hija `tbd_products_users_providers` mediante `fk_products2`; Tabla hija `tbd_users_wishlist_products` mediante `fk_products3`
**Triggers asociados:** `trg_products_after_insert`, `trg_tb_products_after_insert`, `trg_products_after_update`, `trg_tb_products_after_update`, `trg_products_before_delete`, `trg_tb_products_after_delete`

### `tb_refunds`

- **Prefijo/tipo:** tb_ (principal). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 0.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `int unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de refunds. | Obligatorio; Identificador |
| 2 | `payment_ID` | `int unsigned` | NO | — | — | FK | Referencia a `tb_payments.ID`; vincula el registro de refunds con su entidad relacionada. | Obligatorio; Identificador |
| 3 | `cancellation_ID` | `int unsigned` | SÍ | NULL | — | FK | Referencia a `tb_order_cancellations.ID`; vincula el registro de refunds con su entidad relacionada. | Opcional; Identificador |
| 4 | `return_ID` | `int unsigned` | SÍ | NULL | — | FK | Referencia a `tb_returns.ID`; vincula el registro de refunds con su entidad relacionada. | Opcional; Identificador |
| 5 | `reason` | `enum('Cancellation','Return','Adjustment','Goodwill')` | NO | — | — | — | Motivo registrado. | Obligatorio; Cualitativa nominal |
| 6 | `amount` | `decimal(10,2)` | NO | — | — | — | Monto de la operación. | Obligatorio; Cuantitativa |
| 7 | `currency` | `char(3)` | NO | 'MXN' | — | — | Moneda del importe. | Obligatorio; Cualitativa |
| 8 | `refund_status` | `enum('Pending','Submitted','Succeeded','Failed','Canceled')` | NO | 'Pending' | — | — | Estado del flujo de refunds. | Obligatorio; Cualitativa nominal |
| 9 | `provider` | `varchar(60)` | SÍ | NULL | — | — | Proveedor externo del servicio/medio. | Opcional; Cualitativa |
| 10 | `provider_reference` | `varchar(150)` | SÍ | NULL | — | — | Referencia externa asignada por el proveedor. | Opcional; Cualitativa |
| 11 | `requested_by_user_ID` | `int` | SÍ | NULL | — | FK | Referencia a `tb_users.ID`; vincula el registro de refunds con su entidad relacionada. | Opcional; Identificador |
| 12 | `reason_detail` | `varchar(1000)` | SÍ | NULL | — | — | Motivo registrado. | Opcional; Cualitativa |
| 13 | `requested_at` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha/hora asociada a requested at en refunds. | Obligatorio; Temporal |
| 14 | `processed_at` | `datetime` | SÍ | NULL | — | — | Fecha/hora asociada a processed at en refunds. | Opcional; Temporal |
| 15 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 16 | `last_update` | `datetime` | SÍ | NULL | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Opcional; Temporal |

**Restricciones/índices:** PK (`ID`); UNIQUE `uk_refunds_id_payment` (`ID`, `payment_ID`); UNIQUE `uk_refunds_provider_reference` (`provider`, `provider_reference`); ÍNDICE `idx_refunds_payment` (`payment_ID`); ÍNDICE `idx_refunds_cancellation` (`cancellation_ID`); ÍNDICE `idx_refunds_return` (`return_ID`); ÍNDICE `idx_refunds_requester` (`requested_by_user_ID`); FK `fk_refunds_cancellation` (`cancellation_ID`) → `tb_order_cancellations` (`ID`); FK `fk_refunds_payment` (`payment_ID`) → `tb_payments` (`ID`); FK `fk_refunds_requester` (`requested_by_user_ID`) → `tb_users` (`ID`); FK `fk_refunds_return` (`return_ID`) → `tb_returns` (`ID`); CHECK `chk_refunds_amount`: `((`amount` > 0))`; CHECK `chk_refunds_source`: `((((`reason` = 'Cancellation') and (`cancellation_ID` is not null) and (`return_ID` is null)) or ((`reason` = 'Return') and (`return_ID` is not null) and (`cancellation_ID` is null)) or ((`reason` in ('Adjustment','Goodwill')) and (`cancellation_ID` is null) and (`return_ID` is null))))`
**Relaciones:** `fk_refunds_cancellation`: `tb_refunds` (cancellation_ID) → `tb_order_cancellations` (ID); `fk_refunds_payment`: `tb_refunds` (payment_ID) → `tb_payments` (ID); `fk_refunds_requester`: `tb_refunds` (requested_by_user_ID) → `tb_users` (ID); `fk_refunds_return`: `tb_refunds` (return_ID) → `tb_returns` (ID); Tabla hija `tb_payment_transaction` mediante `fk_payment_transaction_refund_payment`
**Triggers asociados:** `trg_tb_refunds_after_insert`, `trg_tb_refunds_after_update`, `trg_tb_refunds_after_delete`

### `tb_returns`

- **Prefijo/tipo:** tb_ (principal). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 0.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `int unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de returns. | Obligatorio; Identificador |
| 2 | `buyer_order_ID` | `int unsigned` | NO | — | — | FK | Referencia a `tbd_buyer_orders.ID`; vincula el registro de returns con su entidad relacionada. | Obligatorio; Identificador |
| 3 | `requested_by_user_ID` | `int` | SÍ | NULL | — | FK | Referencia a `tb_users.ID`; vincula el registro de returns con su entidad relacionada. | Opcional; Identificador |
| 4 | `reason_code` | `varchar(60)` | SÍ | NULL | — | — | Motivo registrado. | Opcional; Cualitativa |
| 5 | `reason_detail` | `varchar(1000)` | SÍ | NULL | — | — | Motivo registrado. | Opcional; Cualitativa |
| 6 | `return_status` | `enum('Requested','Authorized','Rejected','LabelCreated','InTransit','Received','Inspected','Approved','PartiallyApproved','Refunded','Closed')` | NO | 'Requested' | — | — | Estado del flujo de returns. | Obligatorio; Cualitativa nominal |
| 7 | `return_carrier` | `varchar(100)` | SÍ | NULL | — | — | Atributo «return carrier» de returns. | Opcional; Cualitativa |
| 8 | `return_tracking_number` | `varchar(150)` | SÍ | NULL | — | — | Atributo «return tracking number» de returns. | Opcional; Cualitativa |
| 9 | `requested_at` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha/hora asociada a requested at en returns. | Obligatorio; Temporal |
| 10 | `authorized_at` | `datetime` | SÍ | NULL | — | — | Fecha/hora asociada a authorized at en returns. | Opcional; Temporal |
| 11 | `received_at` | `datetime` | SÍ | NULL | — | — | Fecha/hora asociada a received at en returns. | Opcional; Temporal |
| 12 | `closed_at` | `datetime` | SÍ | NULL | — | — | Fecha/hora asociada a closed at en returns. | Opcional; Temporal |
| 13 | `internal_notes` | `varchar(1000)` | SÍ | NULL | — | — | Atributo «internal notes» de returns. | Opcional; Cualitativa |
| 14 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 15 | `last_update` | `datetime` | SÍ | NULL | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Opcional; Temporal |

**Restricciones/índices:** PK (`ID`); ÍNDICE `idx_returns_buyer_order` (`buyer_order_ID`); ÍNDICE `idx_returns_requester` (`requested_by_user_ID`); ÍNDICE `idx_returns_tracking` (`return_carrier`, `return_tracking_number`); FK `fk_returns_buyer_order` (`buyer_order_ID`) → `tbd_buyer_orders` (`ID`); FK `fk_returns_requester` (`requested_by_user_ID`) → `tb_users` (`ID`)
**Relaciones:** `fk_returns_buyer_order`: `tb_returns` (buyer_order_ID) → `tbd_buyer_orders` (ID); `fk_returns_requester`: `tb_returns` (requested_by_user_ID) → `tb_users` (ID); Tabla hija `tb_refunds` mediante `fk_refunds_return`; Tabla hija `tbd_return_items` mediante `fk_return_items_return`
**Triggers asociados:** `trg_tb_returns_after_insert`, `trg_tb_returns_after_update`, `trg_tb_returns_after_delete`

### `tb_seller_orders`

- **Prefijo/tipo:** tb_ (principal). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 0.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `int unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de seller orders. | Obligatorio; Identificador |
| 2 | `seller_ID` | `int` | NO | — | — | FK | Referencia a `tb_users.ID`; vincula el registro de seller orders con su entidad relacionada. | Obligatorio; Identificador |
| 3 | `subtotal` | `decimal(12,2)` | NO | '0.00' | — | — | Importe parcial (sin envío). | Obligatorio; Cuantitativa |
| 4 | `shipping_cost` | `decimal(12,2)` | NO | '0.00' | — | — | Costo de envío. | Obligatorio; Cuantitativa |
| 5 | `fulfillment_status` | `enum('Pending','Accepted','Preparing','Sent','Delivered','Canceled','Returned')` | NO | 'Pending' | — | — | Estado del flujo de seller orders. | Obligatorio; Cualitativa nominal |
| 6 | `status` | `bit(1)` | NO | b'1' | — | — | Estado lógico del registro (1 = activo, 0 = inactivo). | Obligatorio; Cualitativa nominal |
| 7 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 8 | `last_update` | `datetime` | SÍ | NULL | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Opcional; Temporal |

**Restricciones/índices:** PK (`ID`); ÍNDICE `seller_ID` (`seller_ID`); FK `tb_seller_orders_ibfk_1` (`seller_ID`) → `tb_users` (`ID`); CHECK `tb_seller_orders_chk_1`: `((`subtotal` >= 0))`; CHECK `tb_seller_orders_chk_2`: `((`shipping_cost` >= 0))`
**Relaciones:** `tb_seller_orders_ibfk_1`: `tb_seller_orders` (seller_ID) → `tb_users` (ID)
**Triggers asociados:** `trg_tb_seller_orders_after_insert`, `trg_tb_seller_orders_after_update`, `trg_tb_seller_orders_after_delete`

### `tb_shipments`

- **Prefijo/tipo:** tb_ (principal). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 5.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `int unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de shipments. | Obligatorio; Identificador |
| 2 | `buyer_order_ID` | `int unsigned` | NO | — | — | FK | Referencia a `tbd_buyer_orders.ID`; vincula el registro de shipments con su entidad relacionada. | Obligatorio; Identificador |
| 3 | `address_ID` | `bigint unsigned` | SÍ | NULL | — | FK | Referencia a `tb_user_addresses.ID`; vincula el registro de shipments con su entidad relacionada. | Opcional; Identificador |
| 4 | `recipient_name` | `varchar(150)` | SÍ | NULL | — | — | Atributo «recipient name» de shipments. | Opcional; Cualitativa |
| 5 | `recipient_phone` | `varchar(25)` | SÍ | NULL | — | — | Atributo «recipient phone» de shipments. | Opcional; Cualitativa |
| 6 | `address_line_1` | `varchar(255)` | SÍ | NULL | — | — | Atributo «address line 1» de shipments. | Opcional; Cualitativa |
| 7 | `address_line_2` | `varchar(255)` | SÍ | NULL | — | — | Atributo «address line 2» de shipments. | Opcional; Cualitativa |
| 8 | `city` | `varchar(120)` | SÍ | NULL | — | — | Atributo «city» de shipments. | Opcional; Cualitativa |
| 9 | `state_region` | `varchar(120)` | SÍ | NULL | — | — | Atributo «state region» de shipments. | Opcional; Cualitativa |
| 10 | `postal_code` | `varchar(20)` | SÍ | NULL | — | — | Atributo «postal code» de shipments. | Opcional; Cualitativa |
| 11 | `country_code` | `char(2)` | SÍ | NULL | — | — | Código de país (ISO de 2 letras). | Opcional; Cualitativa |
| 12 | `carrier` | `varchar(100)` | SÍ | NULL | — | — | Atributo «carrier» de shipments. | Opcional; Cualitativa |
| 13 | `service_level` | `varchar(100)` | SÍ | NULL | — | — | Atributo «service level» de shipments. | Opcional; Cualitativa |
| 14 | `tracking_number` | `varchar(150)` | SÍ | NULL | — | — | Atributo «tracking number» de shipments. | Opcional; Cualitativa |
| 15 | `tracking_url` | `varchar(500)` | SÍ | NULL | — | — | Atributo «tracking url» de shipments. | Opcional; Cualitativa |
| 16 | `shipment_status` | `enum('Pending','LabelCreated','ReadyToShip','InTransit','OutForDelivery','Delivered','DeliveryFailed','Lost','Returned')` | NO | 'Pending' | — | — | Estado del flujo de shipments. | Obligatorio; Cualitativa nominal |
| 17 | `shipping_cost` | `decimal(12,2)` | NO | '0.00' | — | — | Costo de envío. | Obligatorio; Cuantitativa |
| 18 | `shipped_at` | `datetime` | SÍ | NULL | — | — | Fecha/hora asociada a shipped at en shipments. | Opcional; Temporal |
| 19 | `estimated_delivery_at` | `datetime` | SÍ | NULL | — | — | Fecha/hora asociada a estimated delivery at en shipments. | Opcional; Temporal |
| 20 | `delivered_at` | `datetime` | SÍ | NULL | — | — | Fecha/hora asociada a delivered at en shipments. | Opcional; Temporal |
| 21 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 22 | `last_update` | `datetime` | SÍ | NULL | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Opcional; Temporal |

**Restricciones/índices:** PK (`ID`); ÍNDICE `idx_shipments_buyer_order` (`buyer_order_ID`); ÍNDICE `idx_shipments_address` (`address_ID`); ÍNDICE `idx_shipments_tracking` (`carrier`, `tracking_number`); FK `fk_shipments_address` (`address_ID`) → `tb_user_addresses` (`ID`); FK `fk_shipments_buyer_order` (`buyer_order_ID`) → `tbd_buyer_orders` (`ID`); CHECK `chk_shipments_shipping_cost`: `((`shipping_cost` >= 0))`
**Relaciones:** `fk_shipments_address`: `tb_shipments` (address_ID) → `tb_user_addresses` (ID); `fk_shipments_buyer_order`: `tb_shipments` (buyer_order_ID) → `tbd_buyer_orders` (ID)
**Triggers asociados:** `trg_tb_shipments_after_insert`, `trg_tb_shipments_after_update`, `trg_tb_shipments_after_delete`

### `tb_user_addresses`

- **Prefijo/tipo:** tb_ (principal). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 1.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `bigint unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de user addresses. | Obligatorio; Identificador |
| 2 | `user_ID` | `int` | NO | — | — | FK | Referencia a `tb_users.ID`; vincula el registro de user addresses con su entidad relacionada. | Obligatorio; Identificador |
| 3 | `address_label` | `varchar(100)` | NO | — | — | — | Atributo «address label» de user addresses. | Obligatorio; Cualitativa |
| 4 | `recipient_name` | `varchar(150)` | SÍ | NULL | — | — | Atributo «recipient name» de user addresses. | Opcional; Cualitativa |
| 5 | `recipient_phone` | `varchar(25)` | SÍ | NULL | — | — | Atributo «recipient phone» de user addresses. | Opcional; Cualitativa |
| 6 | `delivery_instructions` | `varchar(500)` | SÍ | NULL | — | — | Atributo «delivery instructions» de user addresses. | Opcional; Cualitativa |
| 7 | `latitude` | `decimal(10,7)` | SÍ | NULL | — | — | Latitud geográfica. | Opcional; Cuantitativa |
| 8 | `longitude` | `decimal(10,7)` | SÍ | NULL | — | — | Longitud geográfica. | Opcional; Cuantitativa |
| 9 | `is_default` | `tinyint(1)` | NO | '0' | — | — | Marca de elemento predeterminado (1 = sí). | Obligatorio; Cuantitativa |
| 10 | `status` | `bit(1)` | NO | b'1' | — | — | Estado lógico del registro (1 = activo, 0 = inactivo). | Obligatorio; Cualitativa nominal |
| 11 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 12 | `last_update` | `datetime` | SÍ | NULL | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Opcional; Temporal |

**Restricciones/índices:** PK (`ID`); ÍNDICE `idx_user_addresses` (`user_ID`); FK `fk_addresses_users` (`user_ID`) → `tb_users` (`ID`); CHECK `chk_coordinates`: `((((`latitude` is null) and (`longitude` is null)) or ((`latitude` is not null) and (`longitude` is not null))))`; CHECK `chk_latitude`: `((`latitude` between -(90) and 90))`; CHECK `chk_longitude`: `((`longitude` between -(180) and 180))`
**Relaciones:** `fk_addresses_users`: `tb_user_addresses` (user_ID) → `tb_users` (ID); Tabla hija `tb_shipments` mediante `fk_shipments_address`; Tabla hija `tbd_address_components` mediante `fk_component_address`
**Triggers asociados:** `trg_tb_user_addresses_after_insert`, `trg_tb_user_addresses_after_update`, `trg_tb_user_addresses_after_delete`

### `tb_users`

- **Prefijo/tipo:** tb_ (principal). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 10240.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `int` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de users. | Obligatorio; Identificador |
| 2 | `email` | `varchar(80)` | NO | — | — | — | Correo electrónico (único). | Obligatorio; Cualitativa |
| 3 | `nickname` | `varchar(100)` | NO | — | — | — | Alias público de la cuenta (único). | Obligatorio; Cualitativa |
| 4 | `password` | `varchar(255)` | NO | — | — | — | Contraseña almacenada de la cuenta. | Obligatorio; Cualitativa |
| 5 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 6 | `last_update` | `datetime` | SÍ | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Opcional; Temporal |
| 7 | `last_login` | `datetime` | SÍ | NULL | — | — | Fecha y hora del último inicio de sesión. | Opcional; Temporal |
| 8 | `status` | `bit(1)` | NO | b'1' | — | — | Estado lógico del registro (1 = activo, 0 = inactivo). | Obligatorio; Cualitativa nominal |

**Restricciones/índices:** PK (`ID`); UNIQUE `email` (`email`); UNIQUE `nickname` (`nickname`)
**Relaciones:** Tabla hija `tb_carts` mediante `tb_carts_ibfk_1`; Tabla hija `tb_order_cancellations` mediante `fk_cancellations_requester`; Tabla hija `tb_orders` mediante `fk_user_2`; Tabla hija `tb_people` mediante `fk_persons_users`; Tabla hija `tb_refunds` mediante `fk_refunds_requester`; Tabla hija `tb_returns` mediante `fk_returns_requester`; Tabla hija `tb_seller_orders` mediante `tb_seller_orders_ibfk_1`; Tabla hija `tb_user_addresses` mediante `fk_addresses_users`; Tabla hija `tbd_buyer_orders` mediante `tbd_buyer_orders_ibfk_1`; Tabla hija `tbd_products_users_providers` mediante `fk_user1`; Tabla hija `tbd_user_payment_methods` mediante `tbd_user_payment_methods_ibfk_1`; Tabla hija `tbd_users_wishlist_products` mediante `fk_user2`
**Triggers asociados:** `trg_users_after_insert`, `trg_tb_users_after_insert`, `trg_users_after_update`, `trg_tb_users_after_update`, `trg_users_after_delete`, `trg_tb_users_after_delete`

### `tbc_categories`

- **Prefijo/tipo:** tbc_ (catálogo). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 100.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `int unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de categories. | Obligatorio; Identificador |
| 2 | `name` | `varchar(120)` | NO | — | — | — | Nombre de categories. | Obligatorio; Cualitativa |
| 3 | `description` | `text` | SÍ | — | — | — | Descripción de categories. | Opcional; Cualitativa |
| 4 | `sup_id_category` | `int unsigned` | SÍ | NULL | — | FK | Referencia a `tbc_categories.ID`; vincula el registro de categories con su entidad relacionada. | Opcional; Identificador |
| 5 | `status` | `bit(1)` | NO | b'1' | — | — | Estado lógico del registro (1 = activo, 0 = inactivo). | Obligatorio; Cualitativa nominal |
| 6 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 7 | `last_update` | `datetime` | NO | — | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Obligatorio; Temporal |

**Restricciones/índices:** PK (`ID`); UNIQUE `name` (`name`); ÍNDICE `fk_superior_category` (`sup_id_category`); FK `fk_superior_category` (`sup_id_category`) → `tbc_categories` (`ID`)
**Relaciones:** `fk_superior_category`: `tbc_categories` (sup_id_category) → `tbc_categories` (ID); Tabla hija `tbc_categories` mediante `fk_superior_category`; Tabla hija `tbd_products_categories` mediante `fk_category`
**Triggers asociados:** `trg_tbc_categories_after_insert`, `trg_tbc_categories_after_update`, `trg_tbc_categories_after_delete`

### `tbc_payment_methods_types`

- **Prefijo/tipo:** tbc_ (catálogo). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 4.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `int unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de payment methods types. | Obligatorio; Identificador |
| 2 | `code` | `varchar(30)` | NO | — | — | — | Código corto identificador (único). | Obligatorio; Cualitativa |
| 3 | `description` | `text` | NO | — | — | — | Descripción de payment methods types. | Obligatorio; Cualitativa |
| 4 | `status` | `bit(1)` | NO | b'1' | — | — | Estado lógico del registro (1 = activo, 0 = inactivo). | Obligatorio; Cualitativa nominal |
| 5 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 6 | `last_update` | `datetime` | SÍ | NULL | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Opcional; Temporal |

**Restricciones/índices:** PK (`ID`); UNIQUE `code_UNIQUE` (`code`)
**Relaciones:** Tabla hija `tbd_user_payment_methods` mediante `tbd_user_payment_methods_ibfk_2`
**Triggers asociados:** `trg_tbc_payment_methods_types_after_insert`, `trg_tbc_payment_methods_types_after_update`, `trg_tbc_payment_methods_types_after_delete`

### `tbd_address_components`

- **Prefijo/tipo:** tbd_ (detalle/asociación). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 7.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `bigint unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de address components. | Obligatorio; Identificador |
| 2 | `address_ID` | `bigint unsigned` | NO | — | — | FK | Referencia a `tb_user_addresses.ID`; vincula el registro de address components con su entidad relacionada. | Obligatorio; Identificador |
| 3 | `value` | `varchar(255)` | NO | — | — | — | Atributo «value» de address components. | Obligatorio; Cualitativa |
| 4 | `component_type` | `varchar(50)` | NO | — | — | — | Atributo «component type» de address components. | Obligatorio; Cualitativa |
| 5 | `status` | `bit(1)` | NO | b'1' | — | — | Estado lógico del registro (1 = activo, 0 = inactivo). | Obligatorio; Cualitativa nominal |
| 6 | `address_sup_ID` | `bigint unsigned` | SÍ | NULL | — | FK | Referencia a `tbd_address_components.ID`; vincula el registro de address components con su entidad relacionada. | Opcional; Identificador |
| 7 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 8 | `last_update` | `datetime` | SÍ | NULL | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Opcional; Temporal |

**Restricciones/índices:** PK (`ID`); UNIQUE `uk_address_component` (`address_ID`, `ID`); ÍNDICE `idx_address_parent` (`address_ID`, `address_sup_ID`); FK `fk_component_address` (`address_ID`) → `tb_user_addresses` (`ID`) ON DELETE RESTRICT; FK `fk_component_parent` (`address_ID`, `address_sup_ID`) → `tbd_address_components` (`address_ID`, `ID`) ON DELETE RESTRICT
**Relaciones:** `fk_component_address`: `tbd_address_components` (address_ID) → `tb_user_addresses` (ID); `fk_component_parent`: `tbd_address_components` (address_ID, address_sup_ID) → `tbd_address_components` (address_ID, ID); Tabla hija `tbd_address_components` mediante `fk_component_parent`
**Triggers asociados:** `trg_tbd_address_components_after_insert`, `trg_tbd_address_components_after_update`, `trg_tbd_address_components_after_delete`

### `tbd_buyer_orders`

- **Prefijo/tipo:** tbd_ (detalle/asociación). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 5.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `int unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de buyer orders. | Obligatorio; Identificador |
| 2 | `order_ID` | `int unsigned` | NO | — | — | FK | Referencia a `tb_orders.ID`; vincula el registro de buyer orders con su entidad relacionada. | Obligatorio; Identificador |
| 3 | `seller_ID` | `int` | NO | — | — | FK | Referencia a `tb_users.ID`; vincula el registro de buyer orders con su entidad relacionada. | Obligatorio; Identificador |
| 4 | `subtotal` | `decimal(12,2)` | NO | '0.00' | — | — | Importe parcial (sin envío). | Obligatorio; Cuantitativa |
| 5 | `shipping_cost` | `decimal(12,2)` | NO | '0.00' | — | — | Costo de envío. | Obligatorio; Cuantitativa |
| 6 | `fulfillment_status` | `enum('Pending','Accepted','Preparing','Sent','Delivered','Canceled','Returned')` | NO | 'Pending' | — | — | Estado del flujo de buyer orders. | Obligatorio; Cualitativa nominal |
| 7 | `status` | `bit(1)` | NO | b'1' | — | — | Estado lógico del registro (1 = activo, 0 = inactivo). | Obligatorio; Cualitativa nominal |
| 8 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 9 | `last_update` | `datetime` | SÍ | NULL | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Opcional; Temporal |

**Restricciones/índices:** PK (`ID`); UNIQUE `uk_buyer_orders_order_seller` (`order_ID`, `seller_ID`); ÍNDICE `seller_ID` (`seller_ID`); FK `fk_buyer_orders_order` (`order_ID`) → `tb_orders` (`ID`); FK `tbd_buyer_orders_ibfk_1` (`seller_ID`) → `tb_users` (`ID`); CHECK `tbd_buyer_orders_chk_1`: `((`subtotal` >= 0))`; CHECK `tbd_buyer_orders_chk_2`: `((`shipping_cost` >= 0))`
**Relaciones:** `fk_buyer_orders_order`: `tbd_buyer_orders` (order_ID) → `tb_orders` (ID); `tbd_buyer_orders_ibfk_1`: `tbd_buyer_orders` (seller_ID) → `tb_users` (ID); Tabla hija `tb_order_cancellations` mediante `fk_cancellations_buyer_order`; Tabla hija `tb_returns` mediante `fk_returns_buyer_order`; Tabla hija `tb_shipments` mediante `fk_shipments_buyer_order`; Tabla hija `tbd_order_items` mediante `fk_order_items_buyer_order`
**Triggers asociados:** `trg_tbd_buyer_orders_after_insert`, `trg_tbd_buyer_orders_after_update`, `trg_tbd_buyer_orders_after_delete`

### `tbd_cancellation_items`

- **Prefijo/tipo:** tbd_ (detalle/asociación). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 0.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `int unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de cancellation items. | Obligatorio; Identificador |
| 2 | `cancellation_ID` | `int unsigned` | NO | — | — | FK | Referencia a `tb_order_cancellations.ID`; vincula el registro de cancellation items con su entidad relacionada. | Obligatorio; Identificador |
| 3 | `order_item_ID` | `int unsigned` | NO | — | — | FK | Referencia a `tbd_order_items.ID`; vincula el registro de cancellation items con su entidad relacionada. | Obligatorio; Identificador |
| 4 | `quantity` | `int unsigned` | NO | — | — | — | Cantidad de unidades. | Obligatorio; Cuantitativa |
| 5 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |

**Restricciones/índices:** PK (`ID`); UNIQUE `uk_cancellation_order_item` (`cancellation_ID`, `order_item_ID`); ÍNDICE `idx_cancellation_items_order_item` (`order_item_ID`); FK `fk_cancellation_items_cancellation` (`cancellation_ID`) → `tb_order_cancellations` (`ID`); FK `fk_cancellation_items_order_item` (`order_item_ID`) → `tbd_order_items` (`ID`); CHECK `chk_cancellation_items_quantity`: `((`quantity` > 0))`
**Relaciones:** `fk_cancellation_items_cancellation`: `tbd_cancellation_items` (cancellation_ID) → `tb_order_cancellations` (ID); `fk_cancellation_items_order_item`: `tbd_cancellation_items` (order_item_ID) → `tbd_order_items` (ID)
**Triggers asociados:** `trg_tbd_cancellation_items_after_insert`, `trg_tbd_cancellation_items_after_update`, `trg_tbd_cancellation_items_after_delete`

### `tbd_cart_items`

- **Prefijo/tipo:** tbd_ (detalle/asociación). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 5.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `cart_ID` | `int unsigned` | NO | — | — | PK+FK | Referencia a `tb_carts.ID`; vincula el registro de cart items con su entidad relacionada. | Obligatorio; Identificador |
| 2 | `provider_ID` | `int` | NO | — | — | PK+FK | Referencia a `tbd_products_users_providers.user_ID`; vincula el registro de cart items con su entidad relacionada. | Obligatorio; Identificador |
| 3 | `product_ID` | `int unsigned` | NO | — | — | PK+FK | Referencia a `tbd_products_users_providers.product_ID`; vincula el registro de cart items con su entidad relacionada. | Obligatorio; Identificador |
| 4 | `quantity` | `int unsigned` | NO | '1' | — | — | Cantidad de unidades. | Obligatorio; Cuantitativa |
| 5 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |

**Restricciones/índices:** PK (`cart_ID`, `provider_ID`, `product_ID`); ÍNDICE `provider_ID` (`provider_ID`); ÍNDICE `product_ID` (`product_ID`); ÍNDICE `idx_cart_items_provider_product` (`provider_ID`, `product_ID`); FK `fk_cart_items_provider_product` (`provider_ID`, `product_ID`) → `tbd_products_users_providers` (`user_ID`, `product_ID`); FK `tbd_cart_items_ibfk_1` (`cart_ID`) → `tb_carts` (`ID`); CHECK `chk_cart_quantity`: `((`quantity` > 0))`
**Relaciones:** `fk_cart_items_provider_product`: `tbd_cart_items` (provider_ID, product_ID) → `tbd_products_users_providers` (user_ID, product_ID); `tbd_cart_items_ibfk_1`: `tbd_cart_items` (cart_ID) → `tb_carts` (ID)
**Triggers asociados:** `trg_tbd_cart_items_before_insert`, `trg_tbd_cart_items_after_insert`, `trg_tbd_cart_items_after_update`, `trg_tbd_cart_items_after_delete`

### `tbd_order_items`

- **Prefijo/tipo:** tbd_ (detalle/asociación). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 0.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `int unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de order items. | Obligatorio; Identificador |
| 2 | `buyer_order_ID` | `int unsigned` | NO | — | — | FK | Referencia a `tbd_buyer_orders.ID`; vincula el registro de order items con su entidad relacionada. | Obligatorio; Identificador |
| 3 | `product_ID` | `int unsigned` | NO | — | — | FK | Referencia a `tbd_products_users_providers.product_ID`; vincula el registro de order items con su entidad relacionada. | Obligatorio; Identificador |
| 4 | `provider_ID` | `int` | NO | — | — | FK | Referencia a `tbd_products_users_providers.user_ID`; vincula el registro de order items con su entidad relacionada. | Obligatorio; Identificador |
| 5 | `product_name` | `varchar(255)` | NO | — | — | — | Atributo «product name» de order items. | Obligatorio; Cualitativa |
| 6 | `quantity` | `int unsigned` | NO | — | — | — | Cantidad de unidades. | Obligatorio; Cuantitativa |
| 7 | `unit_price` | `decimal(12,2)` | NO | — | — | — | Precio unitario al momento de la operación. | Obligatorio; Cuantitativa |
| 8 | `subtotal` | `decimal(12,2)` | SÍ | — | GENERADA STORED: (`quantity` * `unit_price`) | — | Valor calculado automáticamente por el motor a partir de otras columnas. | Opcional; Cuantitativa |
| 9 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |

**Restricciones/índices:** PK (`ID`); ÍNDICE `idx_order_items_buyer_order` (`buyer_order_ID`); ÍNDICE `product_ID` (`product_ID`); ÍNDICE `provider_ID` (`provider_ID`); ÍNDICE `idx_order_items_provider_product` (`provider_ID`, `product_ID`); FK `fk_order_items_buyer_order` (`buyer_order_ID`) → `tbd_buyer_orders` (`ID`); FK `fk_order_items_provider_product` (`provider_ID`, `product_ID`) → `tbd_products_users_providers` (`user_ID`, `product_ID`); CHECK `tbd_order_items_chk_1`: `((`quantity` > 0))`; CHECK `tbd_order_items_chk_2`: `((`unit_price` >= 0))`
**Relaciones:** `fk_order_items_buyer_order`: `tbd_order_items` (buyer_order_ID) → `tbd_buyer_orders` (ID); `fk_order_items_provider_product`: `tbd_order_items` (provider_ID, product_ID) → `tbd_products_users_providers` (user_ID, product_ID); Tabla hija `tbd_cancellation_items` mediante `fk_cancellation_items_order_item`; Tabla hija `tbd_return_items` mediante `fk_return_items_order_item`
**Triggers asociados:** `trg_tbd_order_items_after_insert`, `trg_tbd_order_items_after_update`, `trg_tbd_order_items_after_delete`

### `tbd_products_categories`

- **Prefijo/tipo:** tbd_ (detalle/asociación). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 23020.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `category_ID` | `int unsigned` | NO | — | — | PK+FK | Referencia a `tbc_categories.ID`; vincula el registro de products categories con su entidad relacionada. | Obligatorio; Identificador |
| 2 | `product_ID` | `int unsigned` | NO | — | — | PK+FK | Referencia a `tb_products.id`; vincula el registro de products categories con su entidad relacionada. | Obligatorio; Identificador |
| 3 | `status` | `bit(1)` | NO | b'1' | — | — | Estado lógico del registro (1 = activo, 0 = inactivo). | Obligatorio; Cualitativa nominal |
| 4 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 5 | `last_update` | `datetime` | NO | — | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Obligatorio; Temporal |

**Restricciones/índices:** PK (`category_ID`, `product_ID`); ÍNDICE `fk_product` (`product_ID`); FK `fk_category` (`category_ID`) → `tbc_categories` (`ID`); FK `fk_product` (`product_ID`) → `tb_products` (`id`)
**Relaciones:** `fk_category`: `tbd_products_categories` (category_ID) → `tbc_categories` (ID); `fk_product`: `tbd_products_categories` (product_ID) → `tb_products` (id)
**Triggers asociados:** `trg_tbd_products_categories_after_insert`, `trg_tbd_products_categories_after_update`, `trg_tbd_products_categories_after_delete`

### `tbd_products_users_providers`

- **Prefijo/tipo:** tbd_ (detalle/asociación). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 15007.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `user_ID` | `int` | NO | — | — | PK+FK | Referencia a `tb_users.ID`; vincula el registro de products users providers con su entidad relacionada. | Obligatorio; Identificador |
| 2 | `product_ID` | `int unsigned` | NO | — | — | PK+FK | Referencia a `tb_products.id`; vincula el registro de products users providers con su entidad relacionada. | Obligatorio; Identificador |
| 3 | `type_ownership` | `enum('Owner','Reseller','Distributor')` | SÍ | NULL | — | — | Atributo «type ownership» de products users providers. | Opcional; Cualitativa nominal |
| 4 | `status` | `bit(1)` | NO | b'1' | — | — | Estado lógico del registro (1 = activo, 0 = inactivo). | Obligatorio; Cualitativa nominal |
| 5 | `available_date` | `datetime` | NO | — | — | — | Fecha/hora asociada a available date en products users providers. | Obligatorio; Temporal |
| 6 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 7 | `last_update` | `datetime` | NO | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Obligatorio; Temporal |

**Restricciones/índices:** PK (`user_ID`, `product_ID`); ÍNDICE `fk_products2` (`product_ID`); FK `fk_products2` (`product_ID`) → `tb_products` (`id`); FK `fk_user1` (`user_ID`) → `tb_users` (`ID`)
**Relaciones:** `fk_products2`: `tbd_products_users_providers` (product_ID) → `tb_products` (id); `fk_user1`: `tbd_products_users_providers` (user_ID) → `tb_users` (ID); Tabla hija `tbd_cart_items` mediante `fk_cart_items_provider_product`; Tabla hija `tbd_order_items` mediante `fk_order_items_provider_product`
**Triggers asociados:** `trg_products_users_providers_after_insert`, `trg_products_users_providers_after_update`, `trg_products_users_providers_after_delete`

### `tbd_return_items`

- **Prefijo/tipo:** tbd_ (detalle/asociación). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 0.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `int unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de return items. | Obligatorio; Identificador |
| 2 | `return_ID` | `int unsigned` | NO | — | — | FK | Referencia a `tb_returns.ID`; vincula el registro de return items con su entidad relacionada. | Obligatorio; Identificador |
| 3 | `order_item_ID` | `int unsigned` | NO | — | — | FK | Referencia a `tbd_order_items.ID`; vincula el registro de return items con su entidad relacionada. | Obligatorio; Identificador |
| 4 | `quantity` | `int unsigned` | NO | — | — | — | Cantidad de unidades. | Obligatorio; Cuantitativa |
| 5 | `item_condition` | `enum('Unopened','Unused','Used','Damaged','Defective','Other')` | SÍ | NULL | — | — | Atributo «item condition» de return items. | Opcional; Cualitativa nominal |
| 6 | `disposition` | `enum('Pending','Restock','Repair','Dispose','SupplierReturn')` | NO | 'Pending' | — | — | Atributo «disposition» de return items. | Obligatorio; Cualitativa nominal |
| 7 | `approved_refund_amount` | `decimal(12,2)` | NO | '0.00' | — | — | Atributo «approved refund amount» de return items. | Obligatorio; Cuantitativa |
| 8 | `item_status` | `enum('Requested','Approved','Rejected','Received','Refunded')` | NO | 'Requested' | — | — | Estado del flujo de return items. | Obligatorio; Cualitativa nominal |
| 9 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 10 | `last_update` | `datetime` | SÍ | NULL | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Opcional; Temporal |

**Restricciones/índices:** PK (`ID`); UNIQUE `uk_return_order_item` (`return_ID`, `order_item_ID`); ÍNDICE `idx_return_items_order_item` (`order_item_ID`); FK `fk_return_items_order_item` (`order_item_ID`) → `tbd_order_items` (`ID`); FK `fk_return_items_return` (`return_ID`) → `tb_returns` (`ID`); CHECK `chk_return_items_quantity`: `((`quantity` > 0))`; CHECK `chk_return_items_refund_amount`: `((`approved_refund_amount` >= 0))`
**Relaciones:** `fk_return_items_order_item`: `tbd_return_items` (order_item_ID) → `tbd_order_items` (ID); `fk_return_items_return`: `tbd_return_items` (return_ID) → `tb_returns` (ID)
**Triggers asociados:** `trg_tbd_return_items_after_insert`, `trg_tbd_return_items_after_update`, `trg_tbd_return_items_after_delete`

### `tbd_user_payment_methods`

- **Prefijo/tipo:** tbd_ (detalle/asociación). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 1.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `ID` | `bigint unsigned` | NO | — | AUTO_INCREMENT | PK | Identificador autogenerado del registro de user payment methods. | Obligatorio; Identificador |
| 2 | `user_ID` | `int` | NO | — | — | FK | Referencia a `tb_users.ID`; vincula el registro de user payment methods con su entidad relacionada. | Obligatorio; Identificador |
| 3 | `payment_method_type_ID` | `int unsigned` | NO | — | — | FK | Referencia a `tbc_payment_methods_types.ID`; vincula el registro de user payment methods con su entidad relacionada. | Obligatorio; Identificador |
| 4 | `provider` | `varchar(60)` | NO | — | — | — | Proveedor externo del servicio/medio. | Obligatorio; Cualitativa |
| 5 | `provider_method_ref` | `varchar(255)` | NO | — | — | — | Referencia externa asignada por el proveedor. | Obligatorio; Cualitativa |
| 6 | `label` | `varchar(100)` | SÍ | NULL | — | — | Atributo «label» de user payment methods. | Opcional; Cualitativa |
| 7 | `last_four` | `char(4)` | SÍ | NULL | — | — | Atributo «last four» de user payment methods. | Opcional; Cualitativa |
| 8 | `is_default` | `tinyint(1)` | NO | '0' | — | — | Marca de elemento predeterminado (1 = sí). | Obligatorio; Cuantitativa |
| 9 | `status` | `bit(1)` | NO | b'1' | — | — | Estado lógico del registro (1 = activo, 0 = inactivo). | Obligatorio; Cualitativa nominal |
| 10 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 11 | `last_update` | `datetime` | SÍ | NULL | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Opcional; Temporal |

**Restricciones/índices:** PK (`ID`); UNIQUE `uk_provider_method` (`provider`, `provider_method_ref`); ÍNDICE `user_ID` (`user_ID`); ÍNDICE `payment_method_type_ID` (`payment_method_type_ID`); FK `tbd_user_payment_methods_ibfk_1` (`user_ID`) → `tb_users` (`ID`); FK `tbd_user_payment_methods_ibfk_2` (`payment_method_type_ID`) → `tbc_payment_methods_types` (`ID`); CHECK `chk_user_pm_last_four`: `(((`last_four` is null) or regexp_like(`last_four`,'^[0-9]{4}$')))`
**Relaciones:** `tbd_user_payment_methods_ibfk_1`: `tbd_user_payment_methods` (user_ID) → `tb_users` (ID); `tbd_user_payment_methods_ibfk_2`: `tbd_user_payment_methods` (payment_method_type_ID) → `tbc_payment_methods_types` (ID); Tabla hija `tb_payments` mediante `fk_payment_user_method`
**Triggers asociados:** `trg_tbd_user_payment_methods_after_insert`, `trg_tbd_user_payment_methods_after_update`, `trg_tbd_user_payment_methods_after_delete`

### `tbd_users_wishlist_products`

- **Prefijo/tipo:** tbd_ (detalle/asociación). **Motor:** InnoDB. **Charset/collation:** utf8mb4 / utf8mb4_0900_ai_ci. **Registros:** 0.

| # | Columna | Tipo | NULL | Default | Extras | Llave | Descripción | Clasificación |
|---:|---|---|:---:|---|---|---|---|---|
| 1 | `user_ID` | `int` | NO | — | — | PK+FK | Referencia a `tb_users.ID`; vincula el registro de users wishlist products con su entidad relacionada. | Obligatorio; Identificador |
| 2 | `product_ID` | `int unsigned` | NO | — | — | PK+FK | Referencia a `tb_products.id`; vincula el registro de users wishlist products con su entidad relacionada. | Obligatorio; Identificador |
| 3 | `status` | `bit(1)` | NO | b'1' | — | — | Estado lógico del registro (1 = activo, 0 = inactivo). | Obligatorio; Cualitativa nominal |
| 4 | `creation_date` | `datetime` | NO | CURRENT_TIMESTAMP | — | — | Fecha y hora de creación del registro. | Obligatorio; Temporal |
| 5 | `last_update` | `datetime` | NO | — | ON UPDATE CURRENT_TIMESTAMP | — | Fecha y hora de la última modificación. | Obligatorio; Temporal |

**Restricciones/índices:** PK (`user_ID`, `product_ID`); ÍNDICE `fk_products3` (`product_ID`); FK `fk_products3` (`product_ID`) → `tb_products` (`id`); FK `fk_user2` (`user_ID`) → `tb_users` (`ID`)
**Relaciones:** `fk_products3`: `tbd_users_wishlist_products` (product_ID) → `tb_products` (id); `fk_user2`: `tbd_users_wishlist_products` (user_ID) → `tb_users` (ID)
**Triggers asociados:** `trg_tbd_users_wishlist_products_after_insert`, `trg_tbd_users_wishlist_products_after_update`, `trg_tbd_users_wishlist_products_after_delete`

### Relaciones N:M mediante tablas de asociación

- `tbd_cart_items` resuelve la relación entre `tbd_products_users_providers` y `tb_carts`.
- `tbd_products_categories` resuelve la relación entre `tbc_categories` y `tb_products`.
- `tbd_products_users_providers` resuelve la relación entre `tb_products` y `tb_users`.
- `tbd_users_wishlist_products` resuelve la relación entre `tb_products` y `tb_users`.

## Vistas

| Vista | Propósito | Tablas base | Columnas expuestas |
|---|---|---|---|
| `vw_available_products` | Vista de reporte con agregaciones sobre las tablas base. | `tb_products`, `tbd_products_users_providers` | `product_ID`, `sku`, `name`, `current_price`, `current_stock`, `provider_ID`, `type_ownership` |
| `vw_trazabilidad_address_components` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_buyer_orders` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_cancellation_items` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_cart_items` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_carts` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_categorias` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_order_cancellations` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_order_items` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_orders` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_payment_methods` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_payment_methods_types` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_payment_transaction` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_payments` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_people` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_productos` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_products_categories` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_products_users_providers` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_refunds` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_return_items` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_returns` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_seller_orders` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_shipments` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_user_addresses` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_user_payment_methods` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_users_wishlist_products` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_trazabilidad_usuarios` | Consulta trazable de los registros de auditoría de `tb_logs` filtrados por entidad. | `tb_logs` | `ID`, `table_name`, `operation`, `db_user`, `description`, `operation_date`, `operation_status` |
| `vw_total_products_by_category` | Vista de reporte con agregaciones sobre las tablas base. | — | — |
| `vw_total_products_by_category1` | Vista de reporte con agregaciones sobre las tablas base. | — | — |

## Triggers

| Trigger | Tabla destino | Evento | Momento | Registra en `tb_logs` |
|---|---|---|---|---|
| `trg_tb_carts_after_insert` | `tb_carts` | INSERT | AFTER | Sí (Create) |
| `trg_tb_carts_after_update` | `tb_carts` | UPDATE | AFTER | Sí (Update) |
| `trg_tb_carts_after_delete` | `tb_carts` | DELETE | AFTER | Sí (Delete) |
| `trg_tb_order_cancellations_after_insert` | `tb_order_cancellations` | INSERT | AFTER | Sí (Create) |
| `trg_tb_order_cancellations_after_update` | `tb_order_cancellations` | UPDATE | AFTER | Sí (Update) |
| `trg_tb_order_cancellations_after_delete` | `tb_order_cancellations` | DELETE | AFTER | Sí (Delete) |
| `trg_tb_orders_after_insert` | `tb_orders` | INSERT | AFTER | Sí (Create) |
| `trg_tb_orders_after_update` | `tb_orders` | UPDATE | AFTER | Sí (Update) |
| `trg_tb_orders_after_delete` | `tb_orders` | DELETE | AFTER | Sí (Delete) |
| `trg_tb_payment_methods_after_insert` | `tb_payment_methods` | INSERT | AFTER | Sí (Create) |
| `trg_tb_payment_methods_after_update` | `tb_payment_methods` | UPDATE | AFTER | Sí (Update) |
| `trg_tb_payment_methods_after_delete` | `tb_payment_methods` | DELETE | AFTER | Sí (Delete) |
| `trg_tb_payment_transaction_after_insert` | `tb_payment_transaction` | INSERT | AFTER | Sí (Create) |
| `trg_tb_payment_transaction_after_update` | `tb_payment_transaction` | UPDATE | AFTER | Sí (Update) |
| `trg_tb_payment_transaction_after_delete` | `tb_payment_transaction` | DELETE | AFTER | Sí (Delete) |
| `trg_tb_payments_after_insert` | `tb_payments` | INSERT | AFTER | Sí (Create) |
| `trg_tb_payments_after_update` | `tb_payments` | UPDATE | AFTER | Sí (Update) |
| `trg_tb_payments_after_delete` | `tb_payments` | DELETE | AFTER | Sí (Delete) |
| `trg_tb_people_after_insert` | `tb_people` | INSERT | AFTER | Sí |
| `trg_tb_people_after_update` | `tb_people` | UPDATE | AFTER | Sí |
| `trg_tb_people_after_delete` | `tb_people` | DELETE | AFTER | Sí |
| `trg_products_after_insert` | `tb_products` | INSERT | AFTER | Sí (Create) |
| `trg_tb_products_after_insert` | `tb_products` | INSERT | AFTER | Sí (Create) |
| `trg_products_after_update` | `tb_products` | UPDATE | AFTER | Sí (Update) |
| `trg_tb_products_after_update` | `tb_products` | UPDATE | AFTER | Sí (Update) |
| `trg_products_before_delete` | `tb_products` | DELETE | BEFORE | Sí (Delete) |
| `trg_tb_products_after_delete` | `tb_products` | DELETE | AFTER | Sí (Delete) |
| `trg_tb_refunds_after_insert` | `tb_refunds` | INSERT | AFTER | Sí (Create) |
| `trg_tb_refunds_after_update` | `tb_refunds` | UPDATE | AFTER | Sí (Update) |
| `trg_tb_refunds_after_delete` | `tb_refunds` | DELETE | AFTER | Sí (Delete) |
| `trg_tb_returns_after_insert` | `tb_returns` | INSERT | AFTER | Sí (Create) |
| `trg_tb_returns_after_update` | `tb_returns` | UPDATE | AFTER | Sí (Update) |
| `trg_tb_returns_after_delete` | `tb_returns` | DELETE | AFTER | Sí (Delete) |
| `trg_tb_seller_orders_after_insert` | `tb_seller_orders` | INSERT | AFTER | Sí (Create) |
| `trg_tb_seller_orders_after_update` | `tb_seller_orders` | UPDATE | AFTER | Sí (Update) |
| `trg_tb_seller_orders_after_delete` | `tb_seller_orders` | DELETE | AFTER | Sí (Delete) |
| `trg_tb_shipments_after_insert` | `tb_shipments` | INSERT | AFTER | Sí (Create) |
| `trg_tb_shipments_after_update` | `tb_shipments` | UPDATE | AFTER | Sí (Update) |
| `trg_tb_shipments_after_delete` | `tb_shipments` | DELETE | AFTER | Sí (Delete) |
| `trg_tb_user_addresses_after_insert` | `tb_user_addresses` | INSERT | AFTER | Sí (Create) |
| `trg_tb_user_addresses_after_update` | `tb_user_addresses` | UPDATE | AFTER | Sí (Update) |
| `trg_tb_user_addresses_after_delete` | `tb_user_addresses` | DELETE | AFTER | Sí (Delete) |
| `trg_users_after_insert` | `tb_users` | INSERT | AFTER | Sí (Create) |
| `trg_tb_users_after_insert` | `tb_users` | INSERT | AFTER | Sí |
| `trg_users_after_update` | `tb_users` | UPDATE | AFTER | Sí (Update) |
| `trg_tb_users_after_update` | `tb_users` | UPDATE | AFTER | Sí (Update) |
| `trg_users_after_delete` | `tb_users` | DELETE | AFTER | Sí (Delete) |
| `trg_tb_users_after_delete` | `tb_users` | DELETE | AFTER | Sí (Delete) |
| `trg_tbc_categories_after_insert` | `tbc_categories` | INSERT | AFTER | Sí (Create) |
| `trg_tbc_categories_after_update` | `tbc_categories` | UPDATE | AFTER | Sí (Update) |
| `trg_tbc_categories_after_delete` | `tbc_categories` | DELETE | AFTER | Sí (Delete) |
| `trg_tbc_payment_methods_types_after_insert` | `tbc_payment_methods_types` | INSERT | AFTER | Sí (Create) |
| `trg_tbc_payment_methods_types_after_update` | `tbc_payment_methods_types` | UPDATE | AFTER | Sí (Update) |
| `trg_tbc_payment_methods_types_after_delete` | `tbc_payment_methods_types` | DELETE | AFTER | Sí (Delete) |
| `trg_tbd_address_components_after_insert` | `tbd_address_components` | INSERT | AFTER | Sí (Create) |
| `trg_tbd_address_components_after_update` | `tbd_address_components` | UPDATE | AFTER | Sí (Update) |
| `trg_tbd_address_components_after_delete` | `tbd_address_components` | DELETE | AFTER | Sí (Delete) |
| `trg_tbd_buyer_orders_after_insert` | `tbd_buyer_orders` | INSERT | AFTER | Sí (Create) |
| `trg_tbd_buyer_orders_after_update` | `tbd_buyer_orders` | UPDATE | AFTER | Sí (Update) |
| `trg_tbd_buyer_orders_after_delete` | `tbd_buyer_orders` | DELETE | AFTER | Sí (Delete) |
| `trg_tbd_cancellation_items_after_insert` | `tbd_cancellation_items` | INSERT | AFTER | Sí (Create) |
| `trg_tbd_cancellation_items_after_update` | `tbd_cancellation_items` | UPDATE | AFTER | Sí (Update) |
| `trg_tbd_cancellation_items_after_delete` | `tbd_cancellation_items` | DELETE | AFTER | Sí (Delete) |
| `trg_tbd_cart_items_before_insert` | `tbd_cart_items` | INSERT | BEFORE | No |
| `trg_tbd_cart_items_after_insert` | `tbd_cart_items` | INSERT | AFTER | Sí (Create) |
| `trg_tbd_cart_items_after_update` | `tbd_cart_items` | UPDATE | AFTER | Sí (Update) |
| `trg_tbd_cart_items_after_delete` | `tbd_cart_items` | DELETE | AFTER | Sí (Delete) |
| `trg_tbd_order_items_after_insert` | `tbd_order_items` | INSERT | AFTER | Sí (Create) |
| `trg_tbd_order_items_after_update` | `tbd_order_items` | UPDATE | AFTER | Sí (Update) |
| `trg_tbd_order_items_after_delete` | `tbd_order_items` | DELETE | AFTER | Sí (Delete) |
| `trg_tbd_products_categories_after_insert` | `tbd_products_categories` | INSERT | AFTER | Sí (Create) |
| `trg_tbd_products_categories_after_update` | `tbd_products_categories` | UPDATE | AFTER | Sí (Update) |
| `trg_tbd_products_categories_after_delete` | `tbd_products_categories` | DELETE | AFTER | Sí (Delete) |
| `trg_products_users_providers_after_insert` | `tbd_products_users_providers` | INSERT | AFTER | Sí (Create) |
| `trg_products_users_providers_after_update` | `tbd_products_users_providers` | UPDATE | AFTER | Sí (Update) |
| `trg_products_users_providers_after_delete` | `tbd_products_users_providers` | DELETE | AFTER | Sí (Delete) |
| `trg_tbd_return_items_after_insert` | `tbd_return_items` | INSERT | AFTER | Sí (Create) |
| `trg_tbd_return_items_after_update` | `tbd_return_items` | UPDATE | AFTER | Sí (Update) |
| `trg_tbd_return_items_after_delete` | `tbd_return_items` | DELETE | AFTER | Sí (Delete) |
| `trg_tbd_user_payment_methods_after_insert` | `tbd_user_payment_methods` | INSERT | AFTER | Sí (Create) |
| `trg_tbd_user_payment_methods_after_update` | `tbd_user_payment_methods` | UPDATE | AFTER | Sí (Update) |
| `trg_tbd_user_payment_methods_after_delete` | `tbd_user_payment_methods` | DELETE | AFTER | Sí (Delete) |
| `trg_tbd_users_wishlist_products_after_insert` | `tbd_users_wishlist_products` | INSERT | AFTER | Sí (Create) |
| `trg_tbd_users_wishlist_products_after_update` | `tbd_users_wishlist_products` | UPDATE | AFTER | Sí (Update) |
| `trg_tbd_users_wishlist_products_after_delete` | `tbd_users_wishlist_products` | DELETE | AFTER | Sí (Delete) |

## Procedimientos almacenados

### `sp_authorize_payment`

**Parámetros:** `IN p_payment_id INT UNSIGNED`

**Tablas consultadas/modificadas:** `tb_orders`, `tb_payment_transaction`, `tb_payments`

**Ejemplo:** `CALL sp_authorize_payment(/* p_payment_id */);`

### `sp_bulk_insert_full_users`

**Parámetros:** `IN p_total INT`

**Tablas consultadas/modificadas:** `tb_persons`, `tb_users`

**Ejemplo:** `CALL sp_bulk_insert_full_users(/* p_total */);`

### `sp_bulk_insert_persons`

**Parámetros:** `IN p_total INT`; `IN p_start_user_id INT`

**Tablas consultadas/modificadas:** `tb_persons`

**Ejemplo:** `CALL sp_bulk_insert_persons(/* p_total */, /* p_start_user_id */);`

### `sp_bulk_insert_users`

**Parámetros:** `IN p_total INT`

**Tablas consultadas/modificadas:** `tb_users`

**Ejemplo:** `CALL sp_bulk_insert_users(/* p_total */);`

### `sp_create_order_from_cart`

**Parámetros:** `IN p_user_id INT`; `OUT p_order_id INT UNSIGNED`

**Tablas consultadas/modificadas:** `tb_carts`, `tb_orders`, `tb_products`, `tbd_buyer_orders`, `tbd_cart_items`, `tbd_order_items`, `tbd_products_users_providers`

**Ejemplo:** `CALL sp_create_order_from_cart(/* p_user_id */, /* p_order_id */);`

### `sp_deliver_order`

**Parámetros:** `IN p_order_id INT UNSIGNED`

**Tablas consultadas/modificadas:** `tb_orders`, `tb_shipments`, `tbd_buyer_orders`

**Ejemplo:** `CALL sp_deliver_order(/* p_order_id */);`

### `sp_generate_bulk_users`

**Parámetros:** `IN p_total INT`; `IN p_forced_country VARCHAR(5)`; `IN p_min_age INT`; `IN p_max_age INT`; `IN p_active_ratio INT`

**Tablas consultadas/modificadas:** `tb_people`, `tb_users`

**Ejemplo:** `CALL sp_generate_bulk_users(/* p_total */, /* p_forced_country */, /* p_min_age */, /* p_max_age */, /* p_active_ratio */);`

### `sp_process_order`

**Parámetros:** `IN p_order_id INT UNSIGNED`

**Tablas consultadas/modificadas:** `tb_orders`, `tb_shipments`, `tb_user_addresses`, `tbd_address_components`, `tbd_buyer_orders`

**Ejemplo:** `CALL sp_process_order(/* p_order_id */);`

### `sp_register_payment`

**Parámetros:** `IN p_order_id INT UNSIGNED`; `IN p_user_payment_method_id BIGINT UNSIGNED`; `OUT p_payment_id INT UNSIGNED`

**Tablas consultadas/modificadas:** `tb_orders`, `tb_payment_methods`, `tb_payments`, `tbc_payment_methods_types`, `tbd_user_payment_methods`

**Ejemplo:** `CALL sp_register_payment(/* p_order_id */, /* p_user_payment_method_id */, /* p_payment_id */);`

### `sp_register_user_with_person`

**Parámetros:** `IN p_email VARCHAR(80)`; `IN p_nickname VARCHAR(100)`; `IN p_password VARCHAR(255)`; `IN p_courtesy_title VARCHAR(20)`; `IN p_given_names VARCHAR(150)`; `IN p_family_names VARCHAR(150)`; `IN p_birth_date DATE`; `IN p_gender_id TINYINT UNSIGNED`; `IN p_country_code CHAR(2)`; `IN p_phone VARCHAR(25)`

**Tablas consultadas/modificadas:** `tb_people`, `tb_users`

**Ejemplo:** `CALL sp_register_user_with_person(/* p_email */, /* p_nickname */, /* p_password */, /* p_courtesy_title */, /* p_given_names */, /* p_family_names */, /* p_birth_date */, /* p_gender_id */, /* p_country_code */, /* p_phone */);`

### `sp_restore_product`

**Parámetros:** `IN p_product_id INT UNSIGNED`

**Tablas consultadas/modificadas:** `tb_products`

**Ejemplo:** `CALL sp_restore_product(/* p_product_id */);`

### `sp_simulate_single_user`

**Parámetros:** `OUT p_created_user_id INT UNSIGNED`

**Ejemplo:** `CALL sp_simulate_single_user(/* p_created_user_id */);`

### `sp_simulate_users_bulk`

**Parámetros:** `IN p_quantity INT UNSIGNED`; `IN p_batch_size INT UNSIGNED`

**Invoca:** `sp_simulate_single_user`

**Ejemplo:** `CALL sp_simulate_users_bulk(/* p_quantity */, /* p_batch_size */);`

### `sp_soft_delete_product`

**Parámetros:** `IN p_product_id INT UNSIGNED`

**Tablas consultadas/modificadas:** `tb_products`

**Ejemplo:** `CALL sp_soft_delete_product(/* p_product_id */);`

### `sp_soft_delete_user`

**Parámetros:** `IN p_user_id INT UNSIGNED`

**Tablas consultadas/modificadas:** `tb_users`

**Ejemplo:** `CALL sp_soft_delete_user(/* p_user_id */);`

## Funciones almacenadas

### `fn_get_phone_by_country`

**Parámetros:** `p_country_code VARCHAR(5)`

**Retorna:** `varchar(20) CHARSET utf8mb4`

### `fn_get_random_birth_date`

**Parámetros:** `p_min_age INT`; `p_max_age INT`

**Retorna:** `date`

### `fn_simulate_birthdate`

**Parámetros:** Ninguno

**Retorna:** `date`

### `fn_simulate_country_code`

**Parámetros:** Ninguno

**Retorna:** `char(2) CHARSET utf8mb4`

### `fn_simulate_courtesy_title_id`

**Parámetros:** `p_gender_id TINYINT UNSIGNED`

**Retorna:** `tinyint unsigned`

### `fn_simulate_gender_id`

**Parámetros:** Ninguno

**Retorna:** `tinyint unsigned`

## Dominios y convenciones

**ENUM y campos de estado:**
- `tb_carts.status`: 1 = activo/habilitado; 0 = inactivo/deshabilitado.
- `tb_logs.operation`: Create, Read, Update, Delete.
- `tb_order_cancellations.cancellation_scope`: WholeOrder, SellerOrder, Items.
- `tb_order_cancellations.cancellation_status`: Requested, Approved, Rejected, Completed.
- `tb_orders.status_string`: Registered, Payed, Canceled, Delivered, Devolved, Attended, Sended.
- `tb_orders.status`: 1 = activo/habilitado; 0 = inactivo/deshabilitado.
- `tb_payment_methods.status`: 1 = activo/habilitado; 0 = inactivo/deshabilitado.
- `tb_payment_transaction.transaction_type`: Authorization, Capture, Charge, Void, Refund, Chargeback, Adjustment.
- `tb_payment_transaction.transaction_status`: Pending, Succeeded, Failed.
- `tb_payments.payment_status`: Pending, Authorized, Paid, Failed, Refunded, PartiallyRefunded.
- `tb_people.status`: 1 = activo/habilitado; 0 = inactivo/deshabilitado.
- `tb_products.status`: 1 = activo/habilitado; 0 = inactivo/deshabilitado.
- `tb_refunds.reason`: Cancellation, Return, Adjustment, Goodwill.
- `tb_refunds.refund_status`: Pending, Submitted, Succeeded, Failed, Canceled.
- `tb_returns.return_status`: Requested, Authorized, Rejected, LabelCreated, InTransit, Received, Inspected, Approved, PartiallyApproved, Refunded, Closed.
- `tb_seller_orders.fulfillment_status`: Pending, Accepted, Preparing, Sent, Delivered, Canceled, Returned.
- `tb_seller_orders.status`: 1 = activo/habilitado; 0 = inactivo/deshabilitado.
- `tb_shipments.shipment_status`: Pending, LabelCreated, ReadyToShip, InTransit, OutForDelivery, Delivered, DeliveryFailed, Lost, Returned.
- `tb_user_addresses.is_default`: 1 = predeterminado; 0 = no predeterminado.
- `tb_user_addresses.status`: 1 = activo/habilitado; 0 = inactivo/deshabilitado.
- `tb_users.status`: 1 = activo/habilitado; 0 = inactivo/deshabilitado.
- `tbc_categories.status`: 1 = activo/habilitado; 0 = inactivo/deshabilitado.
- `tbc_payment_methods_types.status`: 1 = activo/habilitado; 0 = inactivo/deshabilitado.
- `tbd_address_components.status`: 1 = activo/habilitado; 0 = inactivo/deshabilitado.
- `tbd_buyer_orders.fulfillment_status`: Pending, Accepted, Preparing, Sent, Delivered, Canceled, Returned.
- `tbd_buyer_orders.status`: 1 = activo/habilitado; 0 = inactivo/deshabilitado.
- `tbd_products_categories.status`: 1 = activo/habilitado; 0 = inactivo/deshabilitado.
- `tbd_products_users_providers.type_ownership`: Owner, Reseller, Distributor.
- `tbd_products_users_providers.status`: 1 = activo/habilitado; 0 = inactivo/deshabilitado.
- `tbd_return_items.item_condition`: Unopened, Unused, Used, Damaged, Defective, Other.
- `tbd_return_items.disposition`: Pending, Restock, Repair, Dispose, SupplierReturn.
- `tbd_return_items.item_status`: Requested, Approved, Rejected, Received, Refunded.
- `tbd_user_payment_methods.is_default`: 1 = predeterminado; 0 = no predeterminado.
- `tbd_user_payment_methods.status`: 1 = activo/habilitado; 0 = inactivo/deshabilitado.
- `tbd_users_wishlist_products.status`: 1 = activo/habilitado; 0 = inactivo/deshabilitado.

**Prefijos de tabla:** `tb_` entidades principales; `tbc_` catálogos; `tbd_` tablas de detalle/asociación.

## Observaciones de diseño

- **Alta:** `sp_register_user_with_person` aplica MD5 a la contraseña; MD5 no es adecuado para almacenar contraseñas. Recomendación: Argon2id, bcrypt o scrypt con sal.
- **Media:** `tb_products`, `tb_users` tienen más de un trigger para el mismo evento y momento; pueden duplicar el historial en `tb_logs`.
- **Baja:** posible vista duplicada: `vw_total_products_by_category1`.

## Pendientes por confirmar

- Significado funcional de ENUM y banderas sin comentario explícito en el DDL.
- Moneda, zona horaria y validaciones de formato no expresadas en el DDL.
- Los conteos de registros corresponden al momento del respaldo y deben validarse en el servidor.
