# newsapp

# Documentación Técnica — InfoPulse (App de Noticias)
---

## 6. Documentación de arquitectura

### 6.1 Resumen del stack

| Capa | Tecnología |
|---|---|
| Aplicación móvil | Flutter (Dart), compatible con Android |
| Autenticación | Firebase Authentication (email/contraseña, Google Sign-In) |
| Base de datos | Cloud Firestore (NoSQL, gestionado por Firebase) |
| Biometría | `local_auth` (BiometricPrompt nativo de Android) |
| Fuente de noticias | NewsAPI.org ([newsapi.org/docs](https://newsapi.org/docs)) |
| Almacenamiento seguro local | `flutter_secure_storage` |
| Persistencia local auxiliar | `sqflite` |

### 6.2 Justificación de la elección de stack

Se eligió Flutter + Firebase priorizando velocidad de desarrollo dado un tiempo de entrega corto. Firebase actúa como backend gestionado (BaaS), lo que evita la necesidad de construir y desplegar un servidor propio, cumpliendo igualmente los requerimientos de autenticación segura, almacenamiento de datos y control de acceso mediante reglas de seguridad declarativas (Firestore Security Rules), alineadas con el principio de defensa en profundidad solicitado en el documento de requerimientos.

### 6.3 Diagrama de arquitectura (alto nivel)

```
┌─────────────────────┐
│   App Flutter        │
│   (Android)          │
│                       │
│  ┌─────────────────┐ │
│  │ AuthGate         │ │◄──── StreamBuilder sobre authStateChanges()
│  │ (StreamBuilder)  │ │
│  └────────┬─────────┘ │
│           │            │
│  ┌────────▼─────────┐ │        ┌───────────────────────┐
│  │ Login/Registro    │─┼───────►│ Firebase Authentication│
│  │ Feed de noticias  │ │        │ (email/pass, Google)   │
│  │ Favoritos/Votos   │─┼───────►│ Cloud Firestore         │
│  │ Perfil            │ │        │ (favorites, votes,      │
│  │ Biometría (local)  │ │        │  securityEvents)        │
│  └────────┬─────────┘ │        └───────────────────────┘
│           │            │
│  ┌────────▼─────────┐ │        ┌───────────────────────┐
│  │ NewsService        │─┼───────►│ API externa de noticias │
│  │ (Retrofit/http)    │ │        │ NewsAPI.org              │
│  └───────────────────┘ │        │                           │
└─────────────────────┘        └───────────────────────┘
```

### 6.4 Modelo de datos (Firestore)

```
users/{uid}
  └── favorites/{newsId}
        - title, source, imageUrl, url, addedAt (serverTimestamp)
  └── votes/{newsId}
        - type: "like" | "dislike"
  └── securityEvents/{eventId}
        - type: "password_changed"
        - timestamp (serverTimestamp)
```

### 6.5 Flujo de autenticación

1. Registro con nombre, correo, contraseña → `createUserWithEmailAndPassword`
2. Envío automático de correo de verificación → `sendEmailVerification()`
3. Bloqueo de acceso mientras `emailVerified == false`
4. Login con correo/contraseña o con Google (`GoogleSignIn` + `GoogleAuthProvider`)
5. `AuthGate` (StreamBuilder sobre `authStateChanges()`) redirige automáticamente entre pantallas de autenticación y la app principal
6. Biometría disponible solo después de un login exitoso y activación explícita del usuario
7. Cierre de sesión automático tras periodo de inactividad configurado

---

## 7. Manual técnico de instalación y despliegue

### 7.1 Requisitos previos

- Flutter SDK (canal estable) — [flutter.dev/get-started/install](https://flutter.dev/get-started/install)
- Android Studio con Android SDK configurado
- Cuenta de Firebase con proyecto creado
- Node.js (para `flutterfire_cli`, si se requiere reconfigurar Firebase)
- Cuenta activa en [NewsAPI.org](https://newsapi.org) con API Key generada

### 7.2 Clonar el repositorio

```bash
git clone https://github.com/munoz437/newsapp.git
cd newsapp
```

### 7.3 Instalar dependencias

```bash
flutter pub get
```

### 7.4 Configurar Firebase

El proyecto ya incluye `firebase_options.dart` generado con FlutterFire CLI. Si necesitas regenerarlo contra tu propio proyecto de Firebase:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Esto sobrescribirá `lib/firebase_options.dart` y `android/app/google-services.json` con la configuración de tu proyecto.

**Requisitos adicionales en Firebase Console:**
- Habilitar proveedores **Email/Password** y **Google** en `Authentication > Sign-in method`
- Registrar el SHA-1 y SHA-256 del keystore usado para compilar (ver sección 7.6) en `Project Settings > tu app Android`
- Publicar las Firestore Security Rules (ver `firestore.rules` en el repositorio)

### 7.5 Configurar variables de entorno

Ver numeral 10 (Configuración de variables de entorno) para el detalle completo. Resumen rápido:

```bash
flutter run --dart-define=NEWS_API_KEY=tu_api_key_aqui
```

### 7.6 Compilar el APK de release

```bash
flutter clean
flutter pub get
flutter build apk --release --dart-define=NEWS_API_KEY=tu_api_key_aqui
```

El archivo resultante queda en:
```
build/app/outputs/flutter-apk/app-release.apk
```

Para obtener el SHA-1/SHA-256 de la firma usada (necesario para configurar Google Sign-In en Firebase):

```bash
cd android
./gradlew signingReport
```

### 7.7 Instalación en dispositivo

**Por USB (con depuración USB activada):**
```bash
flutter install
```

**Manual:** transferir el archivo `.apk` al dispositivo e instalarlo directamente (requiere permitir "instalar apps de origen desconocido" para el instalador usado).

**Distribución vía Firebase App Distribution:**
```bash
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app 1:676907295918:android:ea859c99443b91e135393f \
  --groups "testers"
```


---

## 8. Manual básico de usuario

### 8.1 Crear una cuenta

1. Abre la app y selecciona **"Regístrate"**
2. Completa nombre completo, correo electrónico, contraseña (mínimo 12 caracteres, con mayúscula, minúscula, número y carácter especial) y confirma la contraseña
3. Acepta los términos y condiciones y la política de privacidad
4. Revisa tu correo electrónico y haz clic en el enlace de verificación
5. Regresa a la app e inicia sesión

### 8.2 Iniciar sesión

- Con correo y contraseña, o
- Con el botón **"Continuar con Google"**

> Nota: no es posible iniciar sesión si la cuenta no ha sido verificada por correo.

### 8.3 Activar inicio de sesión con biometría

1. Inicia sesión normalmente al menos una vez
2. Ve a **Perfil**
3. Activa el switch **"Inicio de sesión biométrico"**
4. Confirma con tu huella o rostro cuando el sistema lo solicite

### 8.4 Ver noticias

- La pantalla principal muestra un banner con la noticia destacada y un listado general
- Usa los chips de categoría (General, Tecnología, Deportes, Negocios, Salud) para filtrar
- Toca cualquier noticia para ver el detalle completo

### 8.5 Favoritos y votos

- Toca el ícono de corazón para agregar o quitar una noticia de favoritos
- En el detalle de la noticia, usa los botones de "Me gusta" / "No me gusta" para votar (solo puede haber un voto activo por noticia)
- Accede a tus noticias guardadas desde **"Favoritas"** en el menú principal

### 8.6 Gestionar tu perfil

Desde la pantalla de **Perfil** puedes:
- Ver tus datos
- Cambiar tu contraseña
- Activar/desactivar biometría
- Ver y eliminar tus noticias favoritas
- Cerrar sesión

### 8.7 Recuperar tu contraseña

1. En la pantalla de inicio de sesión, toca **"Olvidé mi contraseña"**
2. Ingresa tu correo electrónico
3. Revisa tu bandeja de entrada y sigue el enlace recibido para definir una nueva contraseña

### 8.8 Cierre de sesión automático

Por seguridad, la app cierra la sesión automáticamente tras **5 minutos** de inactividad. Deberás iniciar sesión nuevamente (con contraseña, Google o biometría) para continuar.

---

## 9. Documentación de APIs

> El proyecto no expone un backend propio con endpoints REST — toda la lógica de servidor está delegada a Firebase (BaaS). Este numeral documenta: (a) el consumo de la API externa de noticias, y (b) el acceso a datos vía Firebase SDK, que cumple el rol de "API" de la aplicación.

### 9.1 API externa de noticias

**Proveedor:** NewsAPI.org — [documentación oficial](https://newsapi.org/docs)

**Endpoint base:** `https://newsapi.org/v2/top-headlines`

**Autenticación:** API Key enviada como parámetro de consulta (`apiKey`), inyectada en tiempo de compilación vía `--dart-define=NEWS_API_KEY=...`, nunca hardcodeada en el código fuente.

**Parámetros usados:**

| Parámetro | Descripción |
|---|---|
| `category` | Categoría de noticias (general, technology, sports, business, health) |
| `language` | Idioma de resultados (`es`) |
| `country` | País de resultados |
| `apiKey` | Clave de autenticación (ver numeral 10) |



**Respuesta (estructura simplificada):**
```json
{
  "articles": [
    {
      "title": "string",
      "description": "string",
      "url": "string",
      "image": "string",
      "publishedAt": "ISO8601 datetime",
      "source": { "name": "string" }
    }
  ]
}
```

**Manejo de errores:** la app distingue y muestra al usuario los estados de carga, error de red/API (con opción de reintentar) y lista vacía.

### 9.2 Acceso a datos vía Firebase (equivalente a "API interna")

**Autenticación (Firebase Authentication SDK):**

| Operación | Método |
|---|---|
| Registro | `createUserWithEmailAndPassword(email, password)` |
| Verificación de correo | `sendEmailVerification()` |
| Login | `signInWithEmailAndPassword(email, password)` |
| Login social | `signInWithCredential(GoogleAuthProvider.credential(idToken))` |
| Cambio de contraseña | `updatePassword(newPassword)` (requiere reautenticación previa) |
| Recuperación de contraseña | `sendPasswordResetEmail(email)` |
| Cierre de sesión | `signOut()` |

**Firestore (colecciones expuestas a la app, protegidas por Security Rules):**

| Colección | Operaciones | Regla de acceso |
|---|---|---|
| `users/{uid}/favorites/{newsId}` | Crear, leer, eliminar | Solo `request.auth.uid == uid` |
| `users/{uid}/votes/{newsId}` | Crear, leer, actualizar | Solo `request.auth.uid == uid` |
| `users/{uid}/securityEvents/{eventId}` | Crear, leer | Solo `request.auth.uid == uid` |

Todas las demás rutas están denegadas por defecto (`allow read, write: if false;`).

---

comando para ejecutar con api key

flutter run --dart-define=NEWS_API_KEY=d4c19d76827f4659a8e59b05eb30d002

flutter run -d emulator-5554


Comando para crear el apk:

flutter build apk --release --dart-define=NEWS_API_KEY=d4c19d76827f4659a8e59b05eb30d002

flutter build apk --release --dart-define-from-file=dart_define.json

