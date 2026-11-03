# Requerimientos Funcionales

## 1. Autenticación y usuarios
- **RF-01** Registrar participantes (`POST /api/v1/auth/register`).
- **RF-02** Iniciar sesión multi-rol y devolver JWT, refresh token y matriz de permisos.
- **RF-03** Verificar segundo factor (TOTP/SMS/Email) para admins y directores.
- **RF-04** Autenticar staff y voluntarios con Magic Link, PIN o QR.
- **RF-05** Autenticar atletas con OAuth2 (Google/Apple) u OTP.
- **RF-06** Aplicar control de acceso por rol (RBAC) y por atributos (ABAC).
- **RF-07** Consultar el perfil propio y actualizar preferencias (tema claro/oscuro/sistema, idioma, notificaciones).
- **RF-08** Consultar la ficha médica propia de forma segura.

## 2. Carreras, categorías y rutas
- **RF-09** Crear carreras (solo Director/SuperAdmin) con estado: borrador, inscripciones abiertas/cerradas, en curso, finalizado o cancelado.
- **RF-10** Listar carreras públicas con filtros por ciudad, fecha y estado, con paginación.
- **RF-11** Consultar el detalle de una carrera por `slug`: ruta, categorías y patrocinadores.
- **RF-12** Crear categorías con distancia, rango de edad, género, cuota y cupo.
- **RF-13** Registrar puntos de control GPS y alfombras RFID de split con su orden.

## 3. Inscripciones y pagos
- **RF-14** Procesar el checkout de inscripción y el webhook de confirmación de pago.
- **RF-15** Validar cupos por categoría y evitar sobreventa con transacciones.
- **RF-16** Firmar la carta responsiva de forma digital.
- **RF-17** Registrar talla de playera y certificado médico.
- **RF-18** Gestionar estados de pago: pendiente, completado, reembolsado y cancelado.

## 4. Kits y dorsales
- **RF-19** Asignar dorsal único y chip RFID único por inscripción, sin duplicados.
- **RF-20** Verificar el QR del atleta y devolver pago, responsiva y dorsal.
- **RF-21** Registrar la entrega del kit con fecha y staff responsable.

## 5. Cronometraje y resultados
- **RF-22** Ingerir de forma masiva lecturas RFID desde las antenas de pista.
- **RF-23** Calcular tiempo transcurrido y ritmo (min/km) por punto de control.
- **RF-24** Mostrar leaderboard en vivo filtrable por categoría, género, splits y ritmo.
- **RF-25** Permitir al juez marcar DNS, DNF o DSQ con motivo.
- **RF-26** Calcular tiempo oficial neto y posición general y por categoría.
- **RF-27** Generar los datos del diploma o certificado digital de finalista.
- **RF-28** Enviar actualizaciones en tiempo real por WebSocket.

## 6. Operaciones de campo
- **RF-29** Registrar la recepción de bultos en guardarropa con etiqueta y estante.
- **RF-30** Registrar la devolución de bultos escaneando el dorsal.
- **RF-31** Buscar por dorsal el expediente médico (sangre, alergias, contacto de emergencia).
- **RF-32** Registrar incidentes médicos con gravedad, punto de ruta y traslado a hospital.
- **RF-33** Asignar voluntarios a áreas y confirmar su asistencia.

## 7. Patrocinadores y auditoría
- **RF-34** Gestionar patrocinadores por nivel (title, gold, silver, bronze) con logo y sitio web.
- **RF-35** Contabilizar impresiones de banner.
- **RF-36** Registrar auditoría de acciones críticas con IP, usuario, datos anteriores y nuevos.

## 8. Interfaz
- **RF-37** Dar vistas distintas por rol: atleta, admin, cronometraje, campo y médico.
- **RF-38** Alternar modo claro, oscuro y sistema, guardando la preferencia en el perfil o en localStorage.
- **RF-39** Escanear QR con la cámara en las vistas de campo.
- **RF-40** Capturar la firma digital en un canvas.
- **RF-41** Mostrar mapas interactivos con ruta y puntos de control.
- **RF-42** Mostrar gráficas de ritmo, edades, géneros e ingresos.
- **RF-43** Mostrar notificaciones toast.

## 9. API
- **RF-44** Documentar todos los endpoints con Swagger/OpenAPI 3.0.
- **RF-45** Responder todos los endpoints con la estructura estándar `success`, `statusCode`, `message`, `data` y `meta`.
