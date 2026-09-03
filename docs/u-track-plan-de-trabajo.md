# U-Track — Plan de trabajo (6 semanas, equipo de 3)

Reparto de referencia por bloques:

- **Persona A** — Splash / Onboarding, Login + Registro (Firebase Auth), Home / Dashboard
- **Persona B** — Lista de materias, Detalle de materia, Crear/editar materia y notas
- **Persona C** — Registrar trabajo/actividad, Calculadora de notas independiente, Recordatorios / Configuración

---

## Semana 1 — Diseño completo en Figma

**Objetivo:** las 9 pantallas navegables en modo Prototype (aunque sea básico), con componentes reutilizables ya definidos.

| Persona | Tarea |
|---|---|
| A | Diseña sus 3 pantallas (Splash, Login, Home) + ayuda a definir los Color Styles y Text Styles globales |
| B | Diseña sus 3 pantallas (Materias, Detalle, Crear materia) + arma el componente de tarjeta de materia reutilizable |
| C | Diseña sus 3 pantallas (Actividad, Calculadora, Config) + arma el componente de Bottom Navigation Bar |

Se trabaja en el **mismo archivo de Figma**, no en copias separadas.

---

## Semana 2 — Setup del proyecto y base técnica

**Objetivo:** proyecto Flutter creado, Firebase conectado, modelos base y navegación vacía definidos.

Trabajo **conjunto, los 3 juntos** — no se reparte esta semana, para evitar que cada quien invente su propia versión de los modelos de datos:

- Crear el proyecto Flutter en Android Studio
- Conectar Firebase (Authentication + Firestore o Realtime Database)
- Acordar la estructura de carpetas del proyecto
- Definir los modelos base: `Usuario`, `Materia`, `Tarea`
- Crear las 9 rutas de navegación, vacías

---

## Semanas 3-4 — Desarrollo por pantallas (reparto 3-3-3)

**Objetivo:** cada quien construye sus 3 pantallas, conectadas a datos reales de Firebase (no solo UI estática).

| Persona | Construye |
|---|---|
| A | Splash + Login (Firebase Auth) + Home/Dashboard |
| B | Lista de materias + Detalle de materia + Crear/editar materia, con lectura/escritura en Firestore |
| C | Registrar actividad + Calculadora independiente + Recordatorios/Config |

### Checkpoints durante estas semanas

- Sync corto de 15-20 min cada 2-3 días (no reunión larga) para destrabar dudas
- Canal de chat para compartir soluciones a errores comunes de Flutter/Firebase

### 3 puntos de dependencia que sí o sí deben comunicarse

1. **A necesita** que B avise cómo estructuró Firestore para materias, ya que el Home de A debe leer esos datos
2. **B necesita** que A tenga lista la autenticación, ya que las materias se guardan asociadas al usuario
3. **A necesita** que C avise cuando tenga lista la lógica de cálculo de notas, para el resumen del Dashboard

---

## Semana 5 — Integración y pruebas cruzadas

**Objetivo:** las 3 partes funcionando juntas en una sola rama, sin bugs de integración.

| Persona | Prueba |
|---|---|
| A | Que su Home muestre correctamente materias creadas por B y tareas creadas por C |
| B | Que sus pantallas reciban bien los datos que A crea en Login/registro |
| C | Que su Calculadora funcione con el mismo esquema de evaluación que B definió en "Crear materia" |

Flujo completo a validar: registro → crear materia → agregar notas → ver cálculo → crear tarea → recordatorio.

---

## Semana 6 — Pulido y notificaciones

**Objetivo:** consistencia visual entre las 9 pantallas y funcionalidades faltantes si el tiempo alcanza.

| Persona | Tarea |
|---|---|
| A | Revisa consistencia visual de sus 3 pantallas contra el documento de specs |
| B | Revisa consistencia visual de las suyas + ayuda con estados vacíos/error |
| C | Implementa notificaciones locales (la parte técnicamente más compleja) si el tiempo alcanza |

---

## Notas generales

- Este plan asume ~6 semanas de trabajo constante; ajustar según fecha de entrega real
- La **Semana 2** es la más importante de todo el plan — si se saltan la definición conjunta de modelos, la Semana 5 (integración) se vuelve mucho más dolorosa
- Trabajar en **ramas de Git separadas por persona**, con commits pequeños y frecuentes
