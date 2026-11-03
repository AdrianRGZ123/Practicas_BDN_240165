# Requerimientos No Funcionales

## Seguridad
- **RNF-01** Autenticación con JWT y rotación de refresh tokens.
- **RNF-02** 2FA/MFA obligatorio para SuperAdmin y recomendado para Director.
- **RNF-03** Cifrado AES-256 de los datos médicos sensibles (padecimientos, ficha médica).
- **RNF-04** Contraseñas guardadas solo como hash (`password_hash`).
- **RNF-05** Protección con helmet, CORS, `express-rate-limit` y sanitización contra inyección SQL y XSS.
- **RNF-06** Validación de entradas con Zod o Joi.
- **RNF-07** Restricción por IP Whitelist o Device Token para cronometradores.
- **RNF-08** Los secretos y credenciales viven en variables de entorno (`.env`), nunca en el código.
- **RNF-09** Auditoría de acciones críticas.

## Rendimiento
- **RNF-10** Endpoint de ingesta RFID de alto volumen y baja latencia.
- **RNF-11** Actualización de tiempos en vivo en milisegundos mediante WebSocket.
- **RNF-12** Índices en dorsal, chip RFID y llaves foráneas para lecturas rápidas el día del evento.
- **RNF-13** Caché con Redis.
- **RNF-14** Compresión GZIP/Brotli de las respuestas.
- **RNF-15** Marca de tiempo de lectura RFID con precisión de milisegundos.

## Disponibilidad y confiabilidad
- **RNF-16** Soporte para miles de participantes concurrentes (por ejemplo, 25,000 inscritos).
- **RNF-17** Transacciones atómicas en inscripción y asignación de dorsales para evitar condiciones de carrera.
- **RNF-18** Reintentos y soporte ante conexiones inestables en campo (TanStack Query, modo optimista).
- **RNF-19** Borrado lógico (`paranoid: true`) en todas las entidades.

## Usabilidad
- **RNF-20** Interfaz 100% responsiva: móvil (<640px), tableta (640–1024px) y escritorio (>1024px).
- **RNF-21** Modo oscuro, claro y de sistema, con contraste adaptado a uso en exteriores.
- **RNF-22** Botones táctiles de al menos 48 px en vistas de campo.
- **RNF-23** Interfaz moderna, profesional y accesible (Headless UI o Radix).
- **RNF-24** Soporte de idiomas español e inglés.
- **RNF-25** Alertas visuales de alta visibilidad en emergencias médicas.

## Mantenibilidad y arquitectura
- **RNF-26** Arquitectura modular (Clean Architecture) con controladores, servicios, modelos y rutas separados.
- **RNF-27** Código en TypeScript en el frontend, con tipado estricto.
- **RNF-28** Documentación de la API con Swagger/OpenAPI 3.0.
- **RNF-29** Migraciones de base de datos versionadas.

## Compatibilidad y tecnología
- **RNF-30** Base de datos MySQL con Sequelize ORM.
- **RNF-31** Backend en Node.js/Express y frontend en React 18.
- **RNF-32** Funcionamiento en navegadores modernos y en dispositivos móviles y tabletas.

## Cumplimiento y datos
- **RNF-33** Protección de datos personales y médicos conforme a la normativa de privacidad aplicable.
- **RNF-34** Respuestas con formato JSON uniforme para facilitar el consumo desde web y móvil.
