# U-Track — Especificaciones de UI por pantalla

Documento de referencia para diseño en Figma. Grid base: múltiplos de 8dp (4dp para ajustes finos). Frame de referencia: 375x812dp (tamaño móvil estándar).

## Paleta de colores (usar exactamente estos hex)

| Uso | Color | Hex |
|---|---|---|
| Fondo de página | Gris cálido | `#F1EFE8` |
| Color primario (botones, elementos activos) | Teal | `#0F6E56` |
| Fondo claro sobre primario (chips, fills suaves) | Teal claro | `#E1F5EE` |
| Texto sobre fondo teal claro | Teal oscuro | `#085041` |
| Color secundario (links, info) | Azul | `#185FA5` |
| Fondo claro azul | Azul claro | `#E6F1FB` |
| Texto sobre fondo azul claro | Azul oscuro | `#0C447C` |
| Estado "al día / aprobado" — fondo | Verde claro | `#EAF3DE` |
| Estado "al día / aprobado" — texto | Verde oscuro | `#27500A` |
| Estado "por vencer / atención" — fondo | Ámbar claro | `#FAEEDA` |
| Estado "por vencer / atención" — texto | Ámbar oscuro | `#854F0B` |
| Estado "vencido / en riesgo" — fondo | Rojo claro | `#FCEBEB` |
| Estado "vencido / en riesgo" — texto | Rojo oscuro | `#A32D2D` |
| Texto principal | Gris oscuro | `#2C2C2A` |
| Texto secundario | Gris medio | `#5F5E5A` |
| Bordes / divisores | Gris claro | `#D3D1C7` |
| Superficie de tarjeta | Blanco | `#FFFFFF` |

## Tipografía (Roboto, fuente por defecto de Material Design en Android)

| Estilo | Tamaño | Peso |
|---|---|---|
| Título de pantalla | 22sp | Medium (500) |
| Subtítulo / nombre de sección | 16sp | Medium (500) |
| Cuerpo | 14sp | Regular (400) |
| Caption / etiqueta pequeña | 12sp | Regular (400) |
| Número destacado (nota, resultado) | 32sp | Medium (500) |

## Iconografía

Usar Material Symbols (Outlined), consistente con `Icons.*` de Flutter. Tamaño estándar: 24dp. Tamaño en AppBar: 24dp. Tamaño decorativo dentro de tarjetas: 20dp.

---

## 1. Splash / Onboarding

**Objetivo:** primera pantalla al abrir la app, antes de autenticación.

**Layout (de arriba hacia abajo, todo centrado horizontalmente):**
- Fondo completo: `#0F6E56` (teal sólido, única pantalla con fondo de color completo)
- Centrado verticalmente en el 60% superior del frame:
  - Logo/ícono de la app: círculo blanco de 96dp de diámetro, con ícono `school` o `menu_book` en teal (`#0F6E56`), 48dp, centrado dentro del círculo
  - Espacio de 24dp
  - Texto "U-Track", 28sp, Medium, color blanco `#FFFFFF`
  - Espacio de 8dp
  - Texto "Tu asistente académico personal", 14sp, Regular, color `#E1F5EE` (teal claro, para contraste sutil sobre fondo teal)
- En el 20% inferior del frame, centrado:
  - Indicador de carga circular pequeño (24dp), color blanco, O 3 puntos de progreso de onboarding si se decide hacer swipe de 2-3 slides
- Margen inferior de seguridad: 48dp desde el borde inferior

**Comportamiento:** transición automática a pantalla de Login tras 2 segundos, o botón "Comenzar" si se opta por onboarding con más de 1 slide (en ese caso, botón blanco con texto teal, ancho 80% del frame, altura 48dp, radio de esquina 8dp, posicionado a 32dp del borde inferior).

**Sin AppBar. Sin bottom navigation.**

---

## 2. Login + Registro (Firebase Auth)

**Objetivo:** autenticación con toggle entre iniciar sesión y crear cuenta.

**Layout:**
- Fondo: `#F1EFE8`
- Sin AppBar tradicional; en su lugar, 64dp de espacio superior vacío
- Logo pequeño centrado: círculo teal de 56dp con ícono `school` blanco 28dp
- Espacio 16dp
- Título centrado: "Bienvenido a U-Track", 22sp Medium, color `#2C2C2A`
- Espacio 24dp
- **Toggle de dos pestañas** (ancho completo menos 32dp de margen lateral, altura 40dp, fondo `#E1F5EE`, radio 8dp):
  - Pestaña izquierda "Iniciar sesión" / pestaña derecha "Crear cuenta"
  - Pestaña activa: fondo `#0F6E56`, texto blanco. Pestaña inactiva: fondo transparente, texto `#085041`
- Espacio 24dp
- **Formulario** (margen lateral 24dp en ambos lados):
  - Si es "Crear cuenta": campo "Nombre completo" primero — input de 48dp de alto, borde 1px `#D3D1C7`, radio 8dp, ícono `person` a la izquierda dentro del campo (16dp de margen interno)
  - Campo "Correo electrónico" — mismo estilo, ícono `mail`
  - Espacio 12dp entre campos
  - Campo "Contraseña" — mismo estilo, ícono `lock`, ícono `visibility_off` a la derecha para mostrar/ocultar
  - Si es "Iniciar sesión": link alineado a la derecha debajo del campo contraseña, "¿Olvidaste tu contraseña?", 13sp, color `#185FA5`
- Espacio 24dp
- **Botón principal**, ancho completo (menos márgenes de 24dp), alto 48dp, fondo `#0F6E56`, texto blanco 16sp Medium, radio 8dp: "Iniciar sesión" o "Crear cuenta" según pestaña activa
- Espacio 16dp
- Divisor horizontal con texto centrado "o" en 12sp gris `#5F5E5A`
- Espacio 16dp
- Botón secundario outline (borde `#D3D1C7`, fondo blanco, texto `#2C2C2A`), mismo ancho/alto que el principal: "Continuar con Google" con ícono de Google a la izquierda (20dp)

**Estados de error:** mensaje en rojo `#A32D2D`, 12sp, debajo del campo correspondiente, con ícono `error_outline` 14dp a la izquierda del texto.

---

## 3. Home / Dashboard

**Objetivo:** vista principal tras iniciar sesión.

**AppBar:**
- Fondo `#F1EFE8` (sin elevación/sombra, estilo flat)
- Izquierda: texto "Hola, [Nombre]", 18sp Medium, color `#2C2C2A`
- Derecha: ícono `notifications` 24dp, color `#2C2C2A`, con badge rojo circular de 8dp en la esquina superior derecha del ícono si hay notificaciones pendientes

**Body (scroll vertical, márgenes laterales 16dp):**
- Espacio 16dp
- **Tarjeta resumen** (fondo `#0F6E56`, radio 12dp, padding 20dp, ancho completo):
  - Texto "Promedio general", 13sp, color `#E1F5EE`
  - Debajo, número grande "4.2", 32sp Medium, color blanco
  - Debajo, texto pequeño "3 materias en riesgo", 12sp, color `#FAC775` (ámbar claro) SOLO si aplica; si no hay materias en riesgo, mostrar "Vas al día" en `#C0DD97` (verde claro)
- Espacio 24dp
- Subtítulo de sección: "Próximas entregas", 16sp Medium, color `#2C2C2A`, con link "Ver todas" alineado a la derecha en la misma línea, 13sp, color `#185FA5`
- Espacio 12dp
- **Lista de tarjetas de tarea** (máximo 4 visibles, cada una):
  - Fondo blanco, radio 12dp, padding 12dp, margen inferior 8dp entre tarjetas
  - Layout horizontal: a la izquierda, ícono `assignment` (24dp) dentro de un círculo de 40dp con fondo según urgencia (verde/ámbar/rojo claro); al centro, nombre de la tarea (14sp Medium, `#2C2C2A`) y materia asociada debajo (12sp, `#5F5E5A`); a la derecha, chip de fecha (ej. "2 días", 12sp) con fondo y texto del color de estado correspondiente (verde/ámbar/rojo)
- Espacio 24dp
- Subtítulo: "Tus materias", 16sp Medium
- Espacio 12dp
- **Grid de 2 columnas** con mini-tarjetas de materia (fondo blanco, radio 12dp, padding 12dp, gap 8dp): nombre de materia (14sp Medium) arriba, nota acumulada grande debajo (20sp Medium, color según estado: verde si ≥3.5, ámbar si 3.0-3.4, rojo si <3.0)

**Bottom Navigation Bar** (fijo, altura 56dp, fondo blanco, borde superior 1px `#D3D1C7`):
- 4 íconos distribuidos uniformemente: `home` (activo, color `#0F6E56`), `menu_book` (Materias, color `#5F5E5A`), `calculate` (Calculadora, color `#5F5E5A`), `settings` (Configuración, color `#5F5E5A`)
- Etiqueta de texto debajo de cada ícono, 11sp

**Botón flotante (FAB):** esquina inferior derecha, 24dp de margen desde bordes, sobre el bottom nav (elevado), círculo 56dp, fondo `#0F6E56`, ícono `add` blanco 24dp. Al tocar, abre menú para elegir "Nueva tarea" o "Nueva materia".

---

## 4. Lista de materias

**AppBar:**
- Fondo `#F1EFE8`, sin sombra
- Título centrado "Materias", 18sp Medium
- Ícono derecho: `add` 24dp, color `#0F6E56` (acceso directo a crear materia)

**Body (márgenes laterales 16dp):**
- Espacio 16dp
- Barra de búsqueda opcional: input de 44dp alto, fondo blanco, radio 8dp, ícono `search` a la izquierda, placeholder "Buscar materia"
- Espacio 16dp
- **Lista vertical de tarjetas de materia** (una por fila, fondo blanco, radio 12dp, padding 16dp, margen inferior 10dp):
  - Layout horizontal: a la izquierda, círculo de 44dp con las iniciales de la materia (ej. "CN" para Cálculo Numérico), fondo `#E1F5EE`, texto `#085041` 14sp Medium
  - Al centro: nombre de la materia (15sp Medium, `#2C2C2A`), y debajo "Prof. [Nombre]" (12sp, `#5F5E5A`)
  - A la derecha: nota acumulada en número grande (20sp Medium), con color según rango (verde ≥3.5, ámbar 3.0-3.4, rojo <3.0), y debajo un ícono `chevron_right` 18dp gris para indicar que es tocable

**Estado vacío** (si no hay materias): ilustración simple centrada o ícono `menu_book` grande (64dp, color `#D3D1C7`) a la mitad de la pantalla, texto "Aún no tienes materias registradas" (14sp, `#5F5E5A`), botón "Agregar materia" debajo (mismo estilo que botón principal de login)

**Bottom Navigation Bar:** igual que Home, con "Materias" activo (color `#0F6E56`)

---

## 5. Detalle de materia

**AppBar:**
- Fondo `#F1EFE8`
- Izquierda: ícono `arrow_back` 24dp
- Centro: nombre de la materia, 18sp Medium
- Derecha: ícono `edit` 24dp (edita datos generales de la materia)

**Body (márgenes laterales 16dp):**
- Espacio 16dp
- **Tarjeta de nota principal** (fondo según estado — usar la versión clara: `#EAF3DE` si va bien, `#FAEEDA` si atención, `#FCEBEB` si riesgo; radio 12dp, padding 20dp, centrado):
  - Texto "Nota acumulada", 13sp, color oscuro correspondiente al estado
  - Número grande "3.8", 36sp Medium, mismo color oscuro
  - Barra de progreso horizontal debajo (8dp alto, radio 4dp) mostrando % de evaluación ya registrado vs. pendiente, en el mismo tono de color
- Espacio 20dp
- Subtítulo "Actividades evaluadas", 16sp Medium, con link "+ Agregar" alineado a la derecha (13sp, `#185FA5`)
- Espacio 12dp
- **Lista de filas de notas** (fondo blanco general en una sola tarjeta contenedora, radio 12dp, cada fila separada por divisor 1px `#D3D1C7`, padding interno 14dp por fila):
  - Layout horizontal: nombre de la actividad (14sp, `#2C2C2A`) y porcentaje que vale (12sp, `#5F5E5A`) a la izquierda; nota obtenida a la derecha (16sp Medium) — si aún no tiene nota, mostrar "Pendiente" en gris itálica en vez de número
- Espacio 20dp
- **Tarjeta "¿Qué necesito?"** (fondo `#E6F1FB`, radio 12dp, padding 16dp):
  - Ícono `calculate` 20dp, color `#0C447C`, alineado con el título "Para pasar con 3.0 necesitas:" (13sp, `#0C447C`)
  - Número grande debajo "4.1 en el examen final", 18sp Medium, color `#0C447C`

**FAB:** igual estilo que Home, ícono `add`, abre formulario para agregar una nueva nota/actividad evaluada a esta materia.

---

## 6. Crear/editar materia y notas

**AppBar:**
- Fondo `#F1EFE8`
- Izquierda: ícono `close` 24dp (cancela y regresa)
- Centro: título "Nueva materia" o "Nueva nota" según contexto, 18sp Medium
- Derecha: texto "Guardar", 15sp Medium, color `#0F6E56` (deshabilitado/gris `#D3D1C7` si el formulario no es válido)

**Body — variante "Nueva materia" (márgenes laterales 24dp):**
- Espacio 20dp
- Campo "Nombre de la materia" — label arriba (13sp, `#5F5E5A`), input debajo (48dp alto, borde `#D3D1C7`, radio 8dp)
- Espacio 16dp
- Campo "Profesor" — mismo estilo
- Espacio 16dp
- Campo "Grupo" — mismo estilo
- Espacio 24dp
- Subtítulo "Esquema de evaluación", 15sp Medium
- Espacio 8dp
- Texto de ayuda: "Agrega los cortes o actividades que componen la nota final", 12sp, `#5F5E5A`
- Espacio 12dp
- **Filas dinámicas** (cada una: input de nombre a la izquierda 60% ancho, input de porcentaje a la derecha 30% ancho con símbolo "%" fijo, ícono `delete_outline` 20dp gris al extremo derecho para eliminar la fila), separadas por 8dp
- Debajo de las filas: botón texto "+ Agregar corte" (14sp, color `#0F6E56`, sin fondo)
- Espacio 12dp
- **Indicador de suma total**, alineado a la derecha: "Total: 100%" en verde `#27500A` si suma exactamente 100, o en rojo `#A32D2D` con ícono `error_outline` si no suma 100

**Body — variante "Nueva nota" (dentro de una materia ya existente):**
- Campo "Selecciona la actividad" — dropdown con las actividades definidas en el esquema de evaluación de esa materia
- Campo "Nota obtenida" — input numérico, 48dp alto, teclado decimal

---

## 7. Registrar trabajo/actividad

**AppBar:**
- Fondo `#F1EFE8`
- Izquierda: ícono `close` 24dp
- Centro: título "Nueva actividad", 18sp Medium
- Derecha: texto "Guardar", 15sp Medium, color `#0F6E56`

**Body (márgenes laterales 24dp):**
- Espacio 20dp
- Campo "Título de la actividad" — label + input estándar (48dp, borde `#D3D1C7`, radio 8dp)
- Espacio 16dp
- Campo "Materia" — dropdown con ícono `menu_book` a la izquierda dentro del campo, muestra las materias ya registradas con su color/iniciales como en la lista de materias
- Espacio 16dp
- Campo "Tipo" — selector tipo chip horizontal con 3 opciones: "Tarea" / "Taller" / "Examen", cada chip 36dp alto, radio 18dp (pill), chip seleccionado con fondo `#0F6E56` y texto blanco, no seleccionados con borde `#D3D1C7` y texto `#5F5E5A`
- Espacio 16dp
- Campo "Fecha límite" — input tipo selector de fecha, ícono `calendar_today` a la izquierda, al tocar abre date picker nativo
- Espacio 16dp
- Campo "Hora" (opcional) — input tipo selector de hora, ícono `schedule`
- Espacio 16dp
- Campo "Notas adicionales" (opcional) — textarea de 3 líneas de alto, mismo estilo de borde
- Espacio 24dp
- Toggle "Recordarme antes de la entrega" — switch a la derecha, texto a la izquierda 14sp; si está activo, revela un dropdown adicional debajo: "Avisarme: 1 día antes / 3 días antes / 1 semana antes"

---

## 8. Calculadora de notas independiente

**AppBar:**
- Fondo `#F1EFE8`
- Título centrado "Calculadora de notas", 18sp Medium
- Sin ícono de acción a la derecha

**Body (márgenes laterales 24dp):**
- Espacio 12dp
- Texto informativo: "Calcula cualquier nota sin afectar tu cuenta", 13sp, `#5F5E5A`, con ícono `info_outline` 14dp a la izquierda del texto
- Espacio 20dp
- Subtítulo "Actividades", 15sp Medium, con link "+ Agregar" a la derecha (13sp, `#185FA5`)
- Espacio 12dp
- **Filas dinámicas** (idéntico estilo a las filas de esquema de evaluación de la pantalla 6): nombre de actividad (input libre) + porcentaje + nota obtenida (o vacío si es la actividad pendiente a calcular) + ícono eliminar
- Espacio 12dp
- Indicador "Total: 100%" igual que en pantalla 6
- Espacio 24dp
- Campo destacado "Nota que quiero alcanzar" — input numérico grande, centrado, 24sp, con borde `#0F6E56` de 2px, radio 8dp, ancho 50% del frame centrado
- Espacio 20dp
- Botón principal ancho completo, 48dp alto, fondo `#0F6E56`, texto blanco: "Calcular"
- Espacio 24dp
- **Tarjeta de resultado** (aparece tras calcular; fondo según viabilidad — verde claro `#EAF3DE` si es alcanzable con nota ≤5.0, rojo claro `#FCEBEB` si no es matemáticamente posible; radio 12dp, padding 20dp, centrado):
  - Texto "Necesitas obtener", 13sp
  - Número grande resultado, 32sp Medium
  - Si no es alcanzable: texto adicional "No es posible alcanzar esta nota con el porcentaje restante", 12sp, en rojo oscuro `#A32D2D`

**Bottom Navigation Bar:** igual que Home, con "Calculadora" activo.

---

## 9. Recordatorios / Configuración

**AppBar:**
- Fondo `#F1EFE8`
- Título centrado "Configuración", 18sp Medium

**Body (márgenes laterales 16dp), organizado en secciones agrupadas por tarjeta:**

**Sección "Cuenta"** (tarjeta blanca, radio 12dp, padding 16dp):
- Layout horizontal: avatar circular 56dp (foto o iniciales sobre fondo `#E1F5EE`) a la izquierda; a la derecha, nombre del estudiante (15sp Medium) y correo debajo (13sp, `#5F5E5A`)
- Ícono `chevron_right` 18dp al extremo derecho, toda la fila es tocable para editar nombre/foto

Espacio 16dp

**Sección "Recordatorios"** (subtítulo "Recordatorios", 14sp Medium, `#5F5E5A`, con margen inferior 8dp antes de la tarjeta):
- Tarjeta blanca, radio 12dp, cada fila con padding 14dp separada por divisor 1px `#D3D1C7`:
  - Fila 1: "Notificaciones activas" — texto a la izquierda, switch a la derecha (activado = fondo `#0F6E56`)
  - Fila 2: "Avisar con anticipación de" — texto a la izquierda, valor actual a la derecha ("1 día antes") con ícono `chevron_right`, abre selector
  - Fila 3: "Hora de recordatorio" — texto a la izquierda, hora a la derecha ("8:00 AM") con ícono `chevron_right`

Espacio 16dp

**Sección "Preferencias"**:
- Tarjeta blanca con filas divididas:
  - "Tema oscuro" — switch a la derecha
  - "Idioma" — valor "Español" a la derecha con `chevron_right`

Espacio 24dp

**Botón "Cerrar sesión"** — ancho completo, 48dp alto, borde `#A32D2D` (rojo), fondo transparente, texto rojo `#A32D2D` 15sp Medium, ícono `logout` a la izquierda del texto

**Bottom Navigation Bar:** igual que Home, con "Configuración" activo.
