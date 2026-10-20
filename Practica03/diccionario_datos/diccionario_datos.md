# Diccionario de datos — db_test

> Generado desde el DDL disponible. Las sentencias INSERT fueron ignoradas.

## Índice

- [Resumen y diferencias](#resumen-y-diferencias)
- [Tablas y columnas](#tablas-y-columnas)
- [Relaciones](#relaciones)
- [Vistas](#vistas)
- [Triggers](#triggers)
- [Procedimientos](#procedimientos)
- [Calidad de diseño](#calidad-de-diseño)

## Resumen y diferencias

- Tablas: 15; vistas: 16; triggers: 48; procedimientos: 3.
 - El inventario del archivo no coincide con las cantidades/nombres originalmente esperados; este documento refleja el contenido real del dump.

## Tablas y columnas

### tb_carts

| Nombre | Tipo SQL | Valor | Origen | Obligatoriedad | Llave | Naturaleza | Composición formal | Dominio |
|---|---|---|---|---|---|---|---|---|
| ID | int unsigned | Monovalor | Almacenado | Obligatorio (Sistema vía AUTO_INCREMENT) | PK | Cuantitativa discreta | @ID : int unsigned | No especificado |
| user_ID | int | Monovalor | Almacenado | Obligatorio (Usuario) | FK (tb_users.ID); UK (uk_cart_user) | Cuantitativa discreta | @user_ID : int | No especificado |
| status | bit(1) | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @status : bit(1) [opcional] | No especificado |
| creation_date | datetime | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @creation_date : datetime | No especificado |
| last_update | datetime | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @last_update : datetime [opcional] | No especificado |

### tb_logs

| Nombre | Tipo SQL | Valor | Origen | Obligatoriedad | Llave | Naturaleza | Composición formal | Dominio |
|---|---|---|---|---|---|---|---|---|
| ID | int | Monovalor | Almacenado | Obligatorio (Sistema vía AUTO_INCREMENT) | PK | Cuantitativa discreta | @ID : int | No especificado |
| table_name | varchar(100) | Monovalor | Almacenado | Obligatorio (Usuario) | Ninguna | Cualitativa nominal | @table_name : varchar(100) | No especificado |
| operation | enum('Create','Read','Update','Delete') | Monovalor | Almacenado | Obligatorio (Usuario) | Ninguna | Cuantitativa temporal | @operation : enum('Create','Read','Update','Delete') | No especificado |
| db_user | varchar(80) | Monovalor | Almacenado | Obligatorio (Usuario) | Ninguna | Cualitativa nominal | @db_user : varchar(80) | No especificado |
| description | text | Monovalor | Almacenado | Obligatorio (Usuario) | Ninguna | Cualitativa nominal | @description : text | No especificado |
| operation_date | datetime | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @operation_date : datetime | No especificado |
| operation_status | bit(1) | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @operation_status : bit(1) [opcional] | No especificado |

### tb_products

| Nombre | Tipo SQL | Valor | Origen | Obligatoriedad | Llave | Naturaleza | Composición formal | Dominio |
|---|---|---|---|---|---|---|---|---|
| id | int unsigned | Monovalor | Almacenado | Obligatorio (Sistema vía AUTO_INCREMENT) | PK | Cuantitativa discreta | @id : int unsigned | No especificado |
| sku | varchar(50) | Monovalor | Almacenado | Obligatorio (Usuario) | UK (sku) | Cualitativa nominal | @sku : varchar(50) | No especificado |
| name | varchar(250) | Monovalor | Almacenado | Obligatorio (Usuario) | Ninguna | Cualitativa nominal | @name : varchar(250) | No especificado |
| description | text | Monovalor | Almacenado | Opcional (Usuario) | Ninguna | Cualitativa nominal | @description : text [opcional] | No especificado |
| current_price | decimal(10,2) | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @current_price : decimal(10,2) | No especificado |
| current_stock | int unsigned | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @current_stock : int unsigned | No especificado |
| status | bit(1) | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @status : bit(1) [opcional] | No especificado |
| creation_date | datetime | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @creation_date : datetime | No especificado |
| last_update | datetime | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @last_update : datetime | No especificado |

### tb_seller_orders

| Nombre | Tipo SQL | Valor | Origen | Obligatoriedad | Llave | Naturaleza | Composición formal | Dominio |
|---|---|---|---|---|---|---|---|---|
| ID | int unsigned | Monovalor | Almacenado | Obligatorio (Sistema vía AUTO_INCREMENT) | PK | Cuantitativa discreta | @ID : int unsigned | No especificado |
| seller_ID | int | Monovalor | Almacenado | Obligatorio (Usuario) | FK (tb_users.ID) | Cuantitativa discreta | @seller_ID : int | No especificado |
| subtotal | decimal(12,2) | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @subtotal : decimal(12,2) | No especificado |
| shipping_cost | decimal(12,2) | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @shipping_cost : decimal(12,2) | No especificado |
| fulfillment_status | enum('Pending','Accepted','Preparing','Sent','Delivered','Canceled','Returned') | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cualitativa nominal | @fulfillment_status : enum('Pending','Accepted','Preparing','Sent','Delivered','Canceled','Returned') | No especificado |
| status | bit(1) | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @status : bit(1) | No especificado |
| creation_date | datetime | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @creation_date : datetime | No especificado |
| last_update | datetime | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @last_update : datetime [opcional] | No especificado |

### tb_user_addresses

| Nombre | Tipo SQL | Valor | Origen | Obligatoriedad | Llave | Naturaleza | Composición formal | Dominio |
|---|---|---|---|---|---|---|---|---|
| ID | bigint unsigned | Monovalor | Almacenado | Obligatorio (Sistema vía AUTO_INCREMENT) | PK | Cuantitativa discreta | @ID : bigint unsigned | No especificado |
| user_ID | int | Monovalor | Almacenado | Obligatorio (Usuario) | FK (tb_users.ID) | Cuantitativa discreta | @user_ID : int | No especificado |
| address_label | varchar(100) | Monovalor | Almacenado | Obligatorio (Usuario) | Ninguna | Cualitativa nominal | @address_label : varchar(100) | No especificado |
| recipient_name | varchar(150) | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cualitativa nominal | @recipient_name : varchar(150) [opcional] | No especificado |
| recipient_phone | varchar(25) | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cualitativa nominal | @recipient_phone : varchar(25) [opcional] | No especificado |
| delivery_instructions | varchar(500) | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cualitativa nominal | @delivery_instructions : varchar(500) [opcional] | No especificado |
| latitude | decimal(10,7) | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @latitude : decimal(10,7) [opcional] | No especificado |
| longitude | decimal(10,7) | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @longitude : decimal(10,7) [opcional] | No especificado |
| is_default | tinyint(1) | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @is_default : tinyint(1) | No especificado |
| status | bit(1) | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @status : bit(1) | No especificado |
| creation_date | datetime | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @creation_date : datetime | No especificado |
| last_update | datetime | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @last_update : datetime [opcional] | No especificado |

### tb_users

| Nombre | Tipo SQL | Valor | Origen | Obligatoriedad | Llave | Naturaleza | Composición formal | Dominio |
|---|---|---|---|---|---|---|---|---|
| ID | int | Monovalor | Almacenado | Obligatorio (Sistema vía AUTO_INCREMENT) | PK | Cuantitativa discreta | @ID : int | No especificado |
| email | varchar(80) | Monovalor | Almacenado | Obligatorio (Usuario) | UK (email) | Cualitativa nominal | @email : varchar(80) | No especificado |
| nickname | varchar(100) | Monovalor | Almacenado | Obligatorio (Usuario) | UK (nickname) | Cualitativa nominal | @nickname : varchar(100) | No especificado |
| password | varchar(255) | Monovalor | Almacenado | Obligatorio (Usuario) | Ninguna | Cualitativa nominal | @password : varchar(255) | No especificado |
| creation_date | datetime | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @creation_date : datetime | No especificado |
| last_update | datetime | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @last_update : datetime [opcional] | No especificado |
| last_login | datetime | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @last_login : datetime [opcional] | No especificado |
| status | bit(1) | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @status : bit(1) | No especificado |

### tbc_categories

| Nombre | Tipo SQL | Valor | Origen | Obligatoriedad | Llave | Naturaleza | Composición formal | Dominio |
|---|---|---|---|---|---|---|---|---|
| ID | int unsigned | Monovalor | Almacenado | Obligatorio (Sistema vía AUTO_INCREMENT) | PK | Cuantitativa discreta | @ID : int unsigned | No especificado |
| name | varchar(120) | Monovalor | Almacenado | Obligatorio (Usuario) | UK (name) | Cualitativa nominal | @name : varchar(120) | No especificado |
| description | text | Monovalor | Almacenado | Opcional (Usuario) | Ninguna | Cualitativa nominal | @description : text [opcional] | No especificado |
| sup_id_category | int unsigned | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | FK (tbc_categories.ID) | Cuantitativa discreta | @sup_id_category : int unsigned [opcional] | No especificado |
| status | bit(1) | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @status : bit(1) | No especificado |
| creation_date | datetime | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @creation_date : datetime | No especificado |
| last_update | datetime | Monovalor | Almacenado | Obligatorio (Usuario) | Ninguna | Cuantitativa temporal | @last_update : datetime | No especificado |

### tbc_payment_methods_types

| Nombre | Tipo SQL | Valor | Origen | Obligatoriedad | Llave | Naturaleza | Composición formal | Dominio |
|---|---|---|---|---|---|---|---|---|
| ID | int unsigned | Monovalor | Almacenado | Obligatorio (Sistema vía AUTO_INCREMENT) | PK | Cuantitativa discreta | @ID : int unsigned | No especificado |
| code | varchar(30) | Monovalor | Almacenado | Obligatorio (Usuario) | UK (code_UNIQUE) | Cualitativa nominal | @code : varchar(30) | No especificado |
| description | text | Monovalor | Almacenado | Obligatorio (Usuario) | Ninguna | Cualitativa nominal | @description : text | No especificado |
| status | bit(1) | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @status : bit(1) | No especificado |
| creation_date | datetime | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @creation_date : datetime | No especificado |
| last_update | datetime | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @last_update : datetime [opcional] | No especificado |

### tbd_address_components

| Nombre | Tipo SQL | Valor | Origen | Obligatoriedad | Llave | Naturaleza | Composición formal | Dominio |
|---|---|---|---|---|---|---|---|---|
| ID | bigint unsigned | Monovalor | Almacenado | Obligatorio (Sistema vía AUTO_INCREMENT) | PK; UK (uk_address_component) | Cuantitativa discreta | @ID : bigint unsigned | No especificado |
| address_ID | bigint unsigned | Monovalor | Almacenado | Obligatorio (Usuario) | FK (tb_user_addresses.ID); FK (tbd_address_components.address_ID); UK (uk_address_component) | Cuantitativa discreta | @address_ID : bigint unsigned | No especificado |
| value | varchar(255) | Monovalor | Almacenado | Obligatorio (Usuario) | Ninguna | Cualitativa nominal | @value : varchar(255) | No especificado |
| component_type | varchar(50) | Monovalor | Almacenado | Obligatorio (Usuario) | Ninguna | Cualitativa nominal | @component_type : varchar(50) | No especificado |
| status | bit(1) | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @status : bit(1) | No especificado |
| address_sup_ID | bigint unsigned | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | FK (tbd_address_components.ID) | Cuantitativa discreta | @address_sup_ID : bigint unsigned [opcional] | No especificado |
| creation_date | datetime | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @creation_date : datetime | No especificado |
| last_update | datetime | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @last_update : datetime [opcional] | No especificado |

### tbd_cart_items

| Nombre | Tipo SQL | Valor | Origen | Obligatoriedad | Llave | Naturaleza | Composición formal | Dominio |
|---|---|---|---|---|---|---|---|---|
| cart_ID | int unsigned | Monovalor | Almacenado | Obligatorio (Usuario) | PK compuesta; FK (tb_carts.ID) | Cuantitativa discreta | @cart_ID : int unsigned | No especificado |
| provider_ID | int | Monovalor | Almacenado | Obligatorio (Usuario) | PK compuesta; FK (tbd_products_users_providers.user_ID) | Cuantitativa discreta | @provider_ID : int | No especificado |
| product_ID | int unsigned | Monovalor | Almacenado | Obligatorio (Usuario) | PK compuesta; FK (tbd_products_users_providers.product_ID) | Cuantitativa discreta | @product_ID : int unsigned | No especificado |
| quantity | int unsigned | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @quantity : int unsigned | No especificado |
| creation_date | datetime | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @creation_date : datetime | No especificado |

### tbd_order_items

| Nombre | Tipo SQL | Valor | Origen | Obligatoriedad | Llave | Naturaleza | Composición formal | Dominio |
|---|---|---|---|---|---|---|---|---|
| ID | int unsigned | Monovalor | Almacenado | Obligatorio (Sistema vía AUTO_INCREMENT) | PK | Cuantitativa discreta | @ID : int unsigned | No especificado |
| seller_order_ID | int unsigned | Monovalor | Almacenado | Obligatorio (Usuario) | FK (tb_seller_orders.ID) | Cuantitativa discreta | @seller_order_ID : int unsigned | No especificado |
| product_ID | int unsigned | Monovalor | Almacenado | Obligatorio (Usuario) | FK (tbd_products_users_providers.product_ID) | Cuantitativa discreta | @product_ID : int unsigned | No especificado |
| provider_ID | int | Monovalor | Almacenado | Obligatorio (Usuario) | FK (tbd_products_users_providers.user_ID) | Cuantitativa discreta | @provider_ID : int | No especificado |
| product_name | varchar(255) | Monovalor | Almacenado | Obligatorio (Usuario) | Ninguna | Cualitativa nominal | @product_name : varchar(255) | No especificado |
| quantity | int unsigned | Monovalor | Almacenado | Obligatorio (Usuario) | Ninguna | Cuantitativa discreta | @quantity : int unsigned | No especificado |
| unit_price | decimal(12,2) | Monovalor | Almacenado | Obligatorio (Usuario) | Ninguna | Cuantitativa discreta | @unit_price : decimal(12,2) | No especificado |
| subtotal | decimal(12,2) | Monovalor | Almacenado | Opcional (Usuario) | Ninguna | Cuantitativa discreta | @subtotal : decimal(12,2) [opcional] | No especificado |
| creation_date | datetime | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @creation_date : datetime | No especificado |

### tbd_products_categories

| Nombre | Tipo SQL | Valor | Origen | Obligatoriedad | Llave | Naturaleza | Composición formal | Dominio |
|---|---|---|---|---|---|---|---|---|
| category_ID | int unsigned | Monovalor | Almacenado | Obligatorio (Usuario) | PK compuesta; FK (tbc_categories.ID) | Cuantitativa discreta | @category_ID : int unsigned | No especificado |
| product_ID | int unsigned | Monovalor | Almacenado | Obligatorio (Usuario) | PK compuesta; FK (tb_products.id) | Cuantitativa discreta | @product_ID : int unsigned | No especificado |
| status | bit(1) | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @status : bit(1) | No especificado |
| creation_date | datetime | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @creation_date : datetime | No especificado |
| last_update | datetime | Monovalor | Almacenado | Obligatorio (Usuario) | Ninguna | Cuantitativa temporal | @last_update : datetime | No especificado |

### tbd_products_users_providers

| Nombre | Tipo SQL | Valor | Origen | Obligatoriedad | Llave | Naturaleza | Composición formal | Dominio |
|---|---|---|---|---|---|---|---|---|
| user_ID | int | Monovalor | Almacenado | Obligatorio (Usuario) | PK compuesta; FK (tb_users.ID) | Cuantitativa discreta | @user_ID : int | No especificado |
| product_ID | int unsigned | Monovalor | Almacenado | Obligatorio (Usuario) | PK compuesta; FK (tb_products.id) | Cuantitativa discreta | @product_ID : int unsigned | No especificado |
| type_ownership | enum('Owner','Reseller','Distributor') | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cualitativa nominal | @type_ownership : enum('Owner','Reseller','Distributor') [opcional] | No especificado |
| status | bit(1) | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @status : bit(1) | No especificado |
| available_date | datetime | Monovalor | Almacenado | Obligatorio (Usuario) | Ninguna | Cuantitativa temporal | @available_date : datetime | No especificado |
| creation_date | datetime | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @creation_date : datetime | No especificado |
| last_update | datetime | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @last_update : datetime | No especificado |

### tbd_user_payment_methods

| Nombre | Tipo SQL | Valor | Origen | Obligatoriedad | Llave | Naturaleza | Composición formal | Dominio |
|---|---|---|---|---|---|---|---|---|
| ID | bigint unsigned | Monovalor | Almacenado | Obligatorio (Sistema vía AUTO_INCREMENT) | PK | Cuantitativa discreta | @ID : bigint unsigned | No especificado |
| user_ID | int | Monovalor | Almacenado | Obligatorio (Usuario) | FK (tb_users.ID) | Cuantitativa discreta | @user_ID : int | No especificado |
| payment_method_type_ID | int unsigned | Monovalor | Almacenado | Obligatorio (Usuario) | FK (tbc_payment_methods_types.ID) | Cuantitativa discreta | @payment_method_type_ID : int unsigned | No especificado |
| provider | varchar(60) | Monovalor | Almacenado | Obligatorio (Usuario) | UK (uk_provider_method) | Cualitativa nominal | @provider : varchar(60) | No especificado |
| provider_method_ref | varchar(255) | Monovalor | Almacenado | Obligatorio (Usuario) | UK (uk_provider_method) | Cualitativa nominal | @provider_method_ref : varchar(255) | No especificado |
| label | varchar(100) | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cualitativa nominal | @label : varchar(100) [opcional] | No especificado |
| last_four | char(4) | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cualitativa nominal | @last_four : char(4) [opcional] | No especificado |
| is_default | tinyint(1) | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @is_default : tinyint(1) | No especificado |
| status | bit(1) | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @status : bit(1) | No especificado |
| creation_date | datetime | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @creation_date : datetime | No especificado |
| last_update | datetime | Monovalor | Almacenado | Opcional (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @last_update : datetime [opcional] | No especificado |

### tbd_users_wishlist_products

| Nombre | Tipo SQL | Valor | Origen | Obligatoriedad | Llave | Naturaleza | Composición formal | Dominio |
|---|---|---|---|---|---|---|---|---|
| user_ID | int | Monovalor | Almacenado | Obligatorio (Usuario) | PK compuesta; FK (tb_users.ID) | Cuantitativa discreta | @user_ID : int | No especificado |
| product_ID | int unsigned | Monovalor | Almacenado | Obligatorio (Usuario) | PK compuesta; FK (tb_products.id) | Cuantitativa discreta | @product_ID : int unsigned | No especificado |
| status | bit(1) | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa discreta | @status : bit(1) | No especificado |
| creation_date | datetime | Monovalor | Almacenado | Obligatorio (Sistema vía DEFAULT) | Ninguna | Cuantitativa temporal | @creation_date : datetime | No especificado |
| last_update | datetime | Monovalor | Almacenado | Obligatorio (Usuario) | Ninguna | Cuantitativa temporal | @last_update : datetime | No especificado |

## Relaciones

| Tabla | Columnas | Referencia |
|---|---|---|
| tb_carts | user_ID | tb_users (ID) |
| tb_seller_orders | seller_ID | tb_users (ID) |
| tb_user_addresses | user_ID | tb_users (ID) |
| tbc_categories | sup_id_category | tbc_categories (ID) |
| tbd_address_components | address_ID | tb_user_addresses (ID) |
| tbd_address_components | address_ID, address_sup_ID | tbd_address_components (address_ID, ID) |
| tbd_cart_items | cart_ID | tb_carts (ID) |
| tbd_cart_items | provider_ID | tbd_products_users_providers (user_ID) |
| tbd_cart_items | product_ID | tbd_products_users_providers (product_ID) |
| tbd_order_items | seller_order_ID | tb_seller_orders (ID) |
| tbd_order_items | product_ID | tbd_products_users_providers (product_ID) |
| tbd_order_items | provider_ID | tbd_products_users_providers (user_ID) |
| tbd_products_categories | category_ID | tbc_categories (ID) |
| tbd_products_categories | product_ID | tb_products (id) |
| tbd_products_users_providers | product_ID | tb_products (id) |
| tbd_products_users_providers | user_ID | tb_users (ID) |
| tbd_user_payment_methods | user_ID | tb_users (ID) |
| tbd_user_payment_methods | payment_method_type_ID | tbc_payment_methods_types (ID) |
| tbd_users_wishlist_products | product_ID | tb_products (id) |
| tbd_users_wishlist_products | user_ID | tb_users (ID) |

## Vistas

- **vw_total_products_by_category**: `SELECT   1 AS `category_ID`,  1 AS `category_path`,  1 AS `category_level`,  1 AS `total_products`,  1 AS `total_active_products`,  1 AS `total_inactive_products`,  1 AS `total_uncategorized_products``
- **vw_total_products_by_category1**: `SELECT   1 AS `category_ID`,  1 AS `category_path`,  1 AS `category_level`,  1 AS `total_products`,  1 AS `total_active_products`,  1 AS `total_inactive_products`,  1 AS `total_uncategorized_products``
- **vw_trazabilidad_address_components**: `SELECT   1 AS `ID`,  1 AS `table_name`,  1 AS `operation`,  1 AS `db_user`,  1 AS `description`,  1 AS `operation_date`,  1 AS `operation_status``
- **vw_trazabilidad_cart_items**: `SELECT   1 AS `ID`,  1 AS `table_name`,  1 AS `operation`,  1 AS `db_user`,  1 AS `description`,  1 AS `operation_date`,  1 AS `operation_status``
- **vw_trazabilidad_carts**: `SELECT   1 AS `ID`,  1 AS `table_name`,  1 AS `operation`,  1 AS `db_user`,  1 AS `description`,  1 AS `operation_date`,  1 AS `operation_status``
- **vw_trazabilidad_categorias**: `SELECT   1 AS `ID`,  1 AS `table_name`,  1 AS `operation`,  1 AS `db_user`,  1 AS `description`,  1 AS `operation_date`,  1 AS `operation_status``
- **vw_trazabilidad_order_items**: `SELECT   1 AS `ID`,  1 AS `table_name`,  1 AS `operation`,  1 AS `db_user`,  1 AS `description`,  1 AS `operation_date`,  1 AS `operation_status``
- **vw_trazabilidad_payment_methods_types**: `SELECT   1 AS `ID`,  1 AS `table_name`,  1 AS `operation`,  1 AS `db_user`,  1 AS `description`,  1 AS `operation_date`,  1 AS `operation_status``
- **vw_trazabilidad_productos**: `SELECT   1 AS `ID`,  1 AS `table_name`,  1 AS `operation`,  1 AS `db_user`,  1 AS `description`,  1 AS `operation_date`,  1 AS `operation_status``
- **vw_trazabilidad_products_categories**: `SELECT   1 AS `ID`,  1 AS `table_name`,  1 AS `operation`,  1 AS `db_user`,  1 AS `description`,  1 AS `operation_date`,  1 AS `operation_status``
- **vw_trazabilidad_products_users_providers**: `SELECT   1 AS `ID`,  1 AS `table_name`,  1 AS `operation`,  1 AS `db_user`,  1 AS `description`,  1 AS `operation_date`,  1 AS `operation_status``
- **vw_trazabilidad_seller_orders**: `SELECT   1 AS `ID`,  1 AS `table_name`,  1 AS `operation`,  1 AS `db_user`,  1 AS `description`,  1 AS `operation_date`,  1 AS `operation_status``
- **vw_trazabilidad_user_addresses**: `SELECT   1 AS `ID`,  1 AS `table_name`,  1 AS `operation`,  1 AS `db_user`,  1 AS `description`,  1 AS `operation_date`,  1 AS `operation_status``
- **vw_trazabilidad_user_payment_methods**: `SELECT   1 AS `ID`,  1 AS `table_name`,  1 AS `operation`,  1 AS `db_user`,  1 AS `description`,  1 AS `operation_date`,  1 AS `operation_status``
- **vw_trazabilidad_users_wishlist_products**: `SELECT   1 AS `ID`,  1 AS `table_name`,  1 AS `operation`,  1 AS `db_user`,  1 AS `description`,  1 AS `operation_date`,  1 AS `operation_status``
- **vw_trazabilidad_usuarios**: `SELECT   1 AS `ID`,  1 AS `table_name`,  1 AS `operation`,  1 AS `db_user`,  1 AS `description`,  1 AS `operation_date`,  1 AS `operation_status``

## Triggers

- **trg_tb_carts_after_insert**: AFTER INSERT en `tb_carts`.
- **trg_tb_carts_after_update**: AFTER UPDATE en `tb_carts`.
- **trg_tb_carts_after_delete**: AFTER DELETE en `tb_carts`.
- **trg_products_after_insert**: AFTER INSERT en `tb_products`.
- **trg_tb_products_after_insert**: AFTER INSERT en `tb_products`.
- **trg_products_after_update**: AFTER UPDATE en `tb_products`.
- **trg_tb_products_after_update**: AFTER UPDATE en `tb_products`.
- **trg_products_before_delete**: BEFORE DELETE en `tb_products`.
- **trg_tb_products_after_delete**: AFTER DELETE en `tb_products`.
- **trg_tb_seller_orders_after_insert**: AFTER INSERT en `tb_seller_orders`.
- **trg_tb_seller_orders_after_update**: AFTER UPDATE en `tb_seller_orders`.
- **trg_tb_seller_orders_after_delete**: AFTER DELETE en `tb_seller_orders`.
- **trg_tb_user_addresses_after_insert**: AFTER INSERT en `tb_user_addresses`.
- **trg_tb_user_addresses_after_update**: AFTER UPDATE en `tb_user_addresses`.
- **trg_tb_user_addresses_after_delete**: AFTER DELETE en `tb_user_addresses`.
- **trg_users_after_insert**: AFTER INSERT en `tb_users`.
- **trg_tb_users_after_insert**: AFTER INSERT en `tb_users`.
- **trg_users_after_update**: AFTER UPDATE en `tb_users`.
- **trg_tb_users_after_update**: AFTER UPDATE en `tb_users`.
- **trg_users_after_delete**: AFTER DELETE en `tb_users`.
- **trg_tb_users_after_delete**: AFTER DELETE en `tb_users`.
- **trg_tbc_categories_after_insert**: AFTER INSERT en `tbc_categories`.
- **trg_tbc_categories_after_update**: AFTER UPDATE en `tbc_categories`.
- **trg_tbc_categories_after_delete**: AFTER DELETE en `tbc_categories`.
- **trg_tbc_payment_methods_types_after_insert**: AFTER INSERT en `tbc_payment_methods_types`.
- **trg_tbc_payment_methods_types_after_update**: AFTER UPDATE en `tbc_payment_methods_types`.
- **trg_tbc_payment_methods_types_after_delete**: AFTER DELETE en `tbc_payment_methods_types`.
- **trg_tbd_address_components_after_insert**: AFTER INSERT en `tbd_address_components`.
- **trg_tbd_address_components_after_update**: AFTER UPDATE en `tbd_address_components`.
- **trg_tbd_address_components_after_delete**: AFTER DELETE en `tbd_address_components`.
- **trg_tbd_cart_items_after_insert**: AFTER INSERT en `tbd_cart_items`.
- **trg_tbd_cart_items_after_update**: AFTER UPDATE en `tbd_cart_items`.
- **trg_tbd_cart_items_after_delete**: AFTER DELETE en `tbd_cart_items`.
- **trg_tbd_order_items_after_insert**: AFTER INSERT en `tbd_order_items`.
- **trg_tbd_order_items_after_update**: AFTER UPDATE en `tbd_order_items`.
- **trg_tbd_order_items_after_delete**: AFTER DELETE en `tbd_order_items`.
- **trg_tbd_products_categories_after_insert**: AFTER INSERT en `tbd_products_categories`.
- **trg_tbd_products_categories_after_update**: AFTER UPDATE en `tbd_products_categories`.
- **trg_tbd_products_categories_after_delete**: AFTER DELETE en `tbd_products_categories`.
- **trg_products_users_providers_after_insert**: AFTER INSERT en `tbd_products_users_providers`.
- **trg_products_users_providers_after_update**: AFTER UPDATE en `tbd_products_users_providers`.
- **trg_products_users_providers_after_delete**: AFTER DELETE en `tbd_products_users_providers`.
- **trg_tbd_user_payment_methods_after_insert**: AFTER INSERT en `tbd_user_payment_methods`.
- **trg_tbd_user_payment_methods_after_update**: AFTER UPDATE en `tbd_user_payment_methods`.
- **trg_tbd_user_payment_methods_after_delete**: AFTER DELETE en `tbd_user_payment_methods`.
- **trg_tbd_users_wishlist_products_after_insert**: AFTER INSERT en `tbd_users_wishlist_products`.
- **trg_tbd_users_wishlist_products_after_update**: AFTER UPDATE en `tbd_users_wishlist_products`.
- **trg_tbd_users_wishlist_products_after_delete**: AFTER DELETE en `tbd_users_wishlist_products`.

## Procedimientos

- **sp_restore_product** `(IN p_product_id INT UNSIGNED)`: `BEGIN     IF NOT EXISTS (         SELECT 1         FROM tb_products         WHERE ID = p_product_id     ) THEN         SIGNAL SQLSTATE '45000'         SET MESSAGE_TEXT = 'El producto especificado no existe';`
- **sp_soft_delete_product** `(IN p_product_id INT UNSIGNED)`: `BEGIN     IF NOT EXISTS (         SELECT 1          FROM tb_products          WHERE ID = p_product_id     ) THEN         SIGNAL SQLSTATE '45000'         SET MESSAGE_TEXT = 'El producto especificado no existe';`
- **sp_soft_delete_user** `(
    IN p_user_id INT UNSIGNED
)`: `MODIFIES SQL DATA BEGIN     DECLARE v_db_user VARCHAR(32);`

## Calidad de diseño

- Las columnas no documentan dominios CHECK explícitos en el DDL procesado; se indica “No especificado”.
- El DDL distingue PK, FK y UK; relaciones sin restricción declarada no se infieren.
- Las categorías nominal/discreta/temporal se infieren del tipo SQL; son una clasificación técnica.
