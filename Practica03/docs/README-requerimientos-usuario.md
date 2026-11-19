# Requerimientos de Usuario

Qué necesita cada tipo de usuario del sistema MarathonHub Enterprise.

## Matriz de roles y autenticación

| Rol | Autenticación | Alcance |
|---|---|---|
| SuperAdmin | JWT + TOTP (2FA obligatorio) | Control total, organizaciones, auditoría y métricas financieras |
| DirectorCarrera | JWT + 2FA recomendado (SMS/Email) | Creación de carreras, categorías, presupuesto y patrocinadores |
| EncargadoCategoria | JWT estándar con sesión activa | Cupos, oleadas (waves) y requisitos por categoría |
| CronometradorJuez | JWT + IP Whitelist / Device Token | Lecturas RFID, correcciones de tiempos, DNS/DNF/DSQ |
| StaffKitGuardarropa | PIN / QR Auth | Entrega de kits y guardarropa |
| MedicoSeguridad | 2FA sensible + cifrado AES-256 | Fichas médicas e incidentes en ruta |
| Voluntario | Magic Link / token temporal | Asistencia y check-in de turnos |
| AtletaParticipante | OAuth2 (Google/Apple) o OTP passwordless | Inscripción, pago, responsiva, diploma y seguimiento |
| Patrocinador | JWT de solo lectura | Métricas de marca |

## Requerimientos por usuario

### Atleta / Participante
- **RU-01** Quiero buscar carreras por distancia, ciudad y fecha para elegir la que me convenga.
- **RU-02** Quiero ver el detalle de la carrera con mapa, categorías y cuotas.
- **RU-03** Quiero inscribirme, elegir categoría y talla, y pagar en línea.
- **RU-04** Quiero firmar la carta responsiva de forma digital.
- **RU-05** Quiero registrar mis datos médicos y mi contacto de emergencia.
- **RU-06** Quiero un código QR personal para recoger mi kit.
- **RU-07** Quiero ver mi tiempo, mi ritmo y mi posición durante y después de la carrera.
- **RU-08** Quiero descargar mi diploma o certificado digital.
- **RU-09** Quiero elegir tema claro, oscuro o del sistema, y el idioma.

### Director de Carrera / SuperAdmin
- **RU-10** Quiero crear carreras con un asistente paso a paso (fechas, cupos, precios).
- **RU-11** Quiero definir categorías y puntos de control sobre un mapa.
- **RU-12** Quiero ver inscritos, ingresos, kits entregados y corredores en pista.
- **RU-13** Quiero administrar patrocinadores y ver sus impresiones.
- **RU-14** Quiero consultar la bitácora de auditoría de acciones críticas.

### Encargado de Categoría
- **RU-15** Quiero controlar cupos, horarios de oleada y requisitos de mi categoría.

### Cronometrador / Juez
- **RU-16** Quiero cargar lecturas RFID de forma masiva y ver el leaderboard en vivo.
- **RU-17** Quiero buscar por dorsal o chip y marcar DNS, DNF o DSQ con justificación.

### Staff de Kits y Guardarropa
- **RU-18** Quiero escanear el QR del atleta y ver su estatus de pago y responsiva.
- **RU-19** Quiero registrar el dorsal y el chip RFID y confirmar la entrega del kit.
- **RU-20** Quiero recibir y devolver bultos indicando el estante.

### Médico / Seguridad
- **RU-21** Quiero buscar por dorsal y ver al instante tipo de sangre, alergias y padecimientos.
- **RU-22** Quiero llamar al contacto de emergencia con un toque.
- **RU-23** Quiero reportar incidentes con gravedad y traslado a hospital.

### Voluntario
- **RU-24** Quiero entrar con un enlace temporal y registrar mi asistencia en mi área.

### Patrocinador
- **RU-25** Quiero ver en modo lectura las métricas de impacto de mi marca.
