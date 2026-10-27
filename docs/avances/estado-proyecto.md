# Estado real del proyecto U-Track

Notas sobre qué tanto de cada pantalla ya funciona de verdad contra Firebase y qué es todavía solo interfaz visual. Revisado directamente en el código, no contra lo que decía el plan original.

## Persona A, Splash, Login, Registro, Home

El Splash reproduce el video de bienvenida y cuando termina manda directo al Login. No revisa si ya hay una sesión abierta, así que aunque ya hayas iniciado sesión antes, siempre vuelve a pedirte que entres de nuevo.

Login y Registro por ahora son solo la pantalla, ningún botón hace nada todavía (ni el de Google ni el de Ingresar/Crear cuenta), no hay ni un import de Firebase Auth en esos dos archivos. Falta conectar la autenticación real ahí.

El Home ya navega bien entre pestañas, eso se conectó esta semana, pero los números que muestra (materias, pendientes, próximo examen) y la lista de próximas entregas son datos de ejemplo escritos directo en el código, no vienen de Firestore.

## Persona B, Materias

La lista de materias tiene tres materias de ejemplo escritas en el código (Matemáticas, Programación, Bases de Datos), no lee nada de Firestore.

El detalle de materia recibe todo por parámetros, no busca nada por su cuenta. La tarjeta que dice cuánto necesitas en el examen final tiene el número fijo, "4.1", siempre igual sin importar la materia que abras, no es un cálculo real todavía.

Crear materia y agregar nota son formularios que validan bien (por ejemplo que los porcentajes sumen 100, o que la nota esté entre 0 y 5), pero al presionar guardar no se escribe nada en Firestore, solo se cierra la pantalla.

## Persona C, Registrar actividad, Calculadora, Configuración

Registrar actividad sí lee las materias desde Firestore para el dropdown. El único pendiente ahí es que el usuario todavía es uno de prueba fijo, porque el login real de la parte A no está conectado.

La Calculadora es independiente a propósito, no toca Firestore para nada, así debía ser según la especificación.

Configuración, notificaciones ya pide el permiso real del sistema y revisa si ya lo tenías dado. Anticipación y hora de recordatorio se pueden elegir pero todavía no programan ninguna notificación real. Tema e idioma se dejaron con un aviso de próximamente en vez de implementarlos completos, porque un tema oscuro real tocaría los colores de las nueve pantallas, no solo las de esta parte.

## El dato que más importa para destrabar esto

Ya existen SubjectModel, SubjectService, GradeModel y GradeService, completos y funcionando de verdad contra Firestore, con las rutas correctas y hasta con recálculo automático de la nota. El problema es que las pantallas de materias de la parte B no los usan, tienen su propia clase local y no llaman a esos servicios en ningún punto. Por eso el dropdown de materias en Registrar actividad nunca va a mostrar nada real hasta que se conecte uno de los dos lados.

## Qué falta

- Conectar Firebase Auth de verdad en Login y Registro.
- Que las pantallas de materias usen los servicios que ya existen en vez de su estado local.
- Cambiar los datos de ejemplo del Home y del detalle de materia por datos reales una vez lo anterior esté conectado.
- Programar los recordatorios como notificaciones locales de verdad.
- Decidir si vale la pena meterle tema oscuro e idiomas reales con el tiempo que queda. **