# MarathonHub Enterprise

Sistema integral de gestión de carreras, maratones, triatlones y eventos deportivos masivos.

## Descripción

MarathonHub Enterprise cubre todo el ciclo de vida de un evento deportivo: planeación, logística de rutas, inscripción y pago en línea, asignación de dorsales y chips RFID, entrega de kits, cronometraje en tiempo real, atención médica, guardarropa, voluntariado, patrocinadores y emisión de diplomas digitales.

El sistema tiene una API REST (backend) y una aplicación web responsiva (frontend) con modo claro, oscuro y de sistema. Cada usuario ve una interfaz distinta según su rol, y el método de autenticación depende del nivel de responsabilidad de ese rol.

## Objetivos

- Centralizar la gestión de carreras, categorías, cupos y puntos de control.
- Automatizar la inscripción, el pago, la firma de responsiva y la asignación de dorsales.
- Publicar tiempos y posiciones en vivo a partir de lecturas RFID.
- Atender emergencias médicas con acceso inmediato a la ficha del corredor.
- Dar trazabilidad y auditoría a las acciones críticas.

## Módulos principales

| Módulo | Descripción |
|---|---|
| Autenticación y roles | RBAC + ABAC, JWT con refresh token, 2FA/TOTP, Magic Link, OTP, OAuth2 y PIN/QR |
| Carreras y rutas | Alta de carreras, categorías, cuotas, cupos y puntos de control GPS/RFID |
| Inscripciones y pagos | Checkout, firma digital de responsiva y control de cupos con transacciones |
| Kits y dorsales | Verificación por QR, entrega de kit y vinculación del chip RFID |
| Cronometraje | Ingesta masiva de lecturas RFID, leaderboard en vivo, DNS/DNF/DSQ |
| Guardarropa | Check-in y check-out de bultos por dorsal y estante |
| Atención médica | Búsqueda por dorsal, ficha médica cifrada y registro de incidentes |
| Voluntarios | Asignación de áreas y registro de asistencia |
| Patrocinadores | Niveles de patrocinio, logos e impresiones de banner |
| Auditoría | Registro de acciones con datos anteriores y nuevos |

## Roles del sistema

SuperAdmin, DirectorCarrera, EncargadoCategoria, CronometradorJuez, StaffKitGuardarropa, MedicoSeguridad, Voluntario, AtletaParticipante y Patrocinador.

## Stack tecnológico

**Backend**
- Node.js + Express
- Sequelize ORM con MySQL
- Swagger/OpenAPI 3.0
- Redis, JWT, helmet, cors, express-rate-limit

**Frontend**
- React 18 + TypeScript (Vite o Next.js)
- Tailwind CSS (`darkMode: 'class'`)
- Zustand, TanStack Query, Socket.io-client
- Leaflet, Recharts, Framer Motion, Lucide Icons

## Modelo de datos (entidades)

`usuarios`, `roles`, `usuario_roles`, `preferencias_usuario`, `carreras`, `categorias`, `rutas_puntos_control`, `inscripciones`, `asignacion_dorsales`, `tiempos_rfid`, `estado_corredor_carrera`, `guardarropa`, `incidentes_medicos`, `voluntarios_logistica`, `patrocinadores`, `auditoria_eventos`.

Todas usan borrado lógico (`paranoid: true`).

## Estructura del backend

```
src/
├── config/
├── controllers/
├── middlewares/
├── models/
├── routes/
├── services/
├── utils/
└── app.js
```

## Formato estándar de respuesta de la API

```json
{
  "success": true,
  "statusCode": 200,
  "message": "Operación ejecutada correctamente",
  "data": {},
  "meta": { "page": 1, "limit": 20, "totalRecords": 1500, "themeHint": "dark" }
}
```
