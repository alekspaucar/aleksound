# Instalación y vista previa

Estado del 9 de octubre de 2026: **0.6.3+9 Release** instalada y abierta en el iPhone por actualización, conservando siete descargas y sus portadas. Los [tres ajustes de uso](ajustes-reproductor-biblioteca-portadas.md) y la [validación](validacion.md) documentan las comprobaciones y lo que aún queda pendiente. No es necesario reinstalar para usarla ahora.

## Usar Aleksound sin Xcode

Puedes cerrar Xcode y VS Code, desconectar el cable y apagar la Mac. Abre **Aleksound desde su icono en el iPhone**: la versión instalada es Release, no una sesión Debug/JIT ni un programa de pruebas. La Mac no sirve el audio; buscar y descargar necesitan internet en el teléfono, mientras que Biblioteca → Descargas utiliza archivos locales.

Mantén activado **Ajustes → Privacidad y seguridad → Modo desarrollador** para seguir usando esta instalación. La app está firmada para desarrollo con un Personal Team: compilar en Release permite ejecutarla sin depurador, pero no cambia el tipo de firma ni la convierte en una app distribuida por la App Store. Apple explica esta diferencia en [pruebas de una compilación Release](https://developer.apple.com/documentation/xcode/testing-a-release-build).

Si desactivas el modo desarrollador, esta app de desarrollo no podrá ejecutarse hasta volver a activarlo. Para recuperarlo, actívalo en Ajustes, reinicia y confirma la activación cuando iOS lo solicite. Cambiar esa opción no renueva una firma caducada. Consulta [Modo desarrollador, Apple](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).

### Vigencia de la instalación personal

Con la cuenta gratuita **Personal Team**, Apple establece que el perfil de aprovisionamiento vence **siete días después de su emisión**; después hay que volver a compilar, firmar e instalar. Esto no es una suscripción musical: es una condición de la instalación personal de iOS. La fecha exacta depende del perfil, no de cuándo descargaste una canción. [Cuenta personal y límites, Apple](https://developer.apple.com/help/account/basics/about-your-developer-account).

Por tanto, la reproducción cotidiana no necesita la Mac, pero las actualizaciones y la renovación de esta firma sí requieren volver a las herramientas de desarrollo. **No borrar Aleksound para renovar**: eliminar la app puede borrar sus archivos locales. El respaldo de metadatos no incluye los audios.

### Renovar o actualizar sin borrar la biblioteca

1. Conecta y desbloquea el iPhone; abre `ios/Runner.xcworkspace` en Xcode y selecciona Runner y tu iPhone.
2. En **Signing & Capabilities**, conserva el mismo Personal Team, la firma automática y `com.erickvzh.aleksound`. No cambies la identidad para crear una segunda app.
3. Prepara la entrada normal `lib/main.dart` en Release siguiendo la [guía de compilación](version-0.6-iphone.md#instalar-una-versión-independiente-de-la-mac); no instales un objetivo de integración o diagnóstico.
4. Si instalas con el botón de Xcode, en **Product → Scheme → Edit Scheme → Run → Info** elige **Release** y desmarca **Debug executable**. Ejecuta Runner en el iPhone para instalar sobre la app existente, sin desinstalarla antes.
5. Abre Aleksound desde el icono y comprueba **Biblioteca → Descargas**, portadas y álbumes. Después puedes cerrar Xcode y desconectar el cable otra vez.

Si aparece «Desarrollador no confiable», revisa **Ajustes → General → VPN y gestión de dispositivos** y confía únicamente en el certificado de tu propia cuenta. No elimines perfiles ni certificados para solucionar un error de canción; firma y acceso a YouTube son problemas distintos.

## Chrome en este Mac

```bash
cd /Users/erickvzh/Documents/alesound
export PATH="/Users/erickvzh/develop/flutter/bin:$PATH"
flutter pub get
flutter run -d chrome --web-port 7358
```

Amplía Chrome para ver el marco móvil. Toca una carátula para escuchar y el mini-reproductor para expandirlo. `r` actualiza cambios, `q` termina la sesión. El puerto fijo conserva el mismo origen para favoritos. Si está ocupado, cierra la sesión anterior o elige otro puerto; otro origen tendrá preferencias distintas.

La vista previa estática del asistente usa 7357; el modo de desarrollo usa 7358. Las bibliotecas de ambos orígenes son independientes.

Ya existe `web/`. No es necesario ejecutar otra vez `flutter create .`.

## VS Code

Abre la carpeta e instala la extensión oficial Flutter. Selecciona Chrome como dispositivo y ejecuta desde el editor o terminal. VS Code edita código; Xcode proporciona herramientas de iOS y un simulador separado. Para Chrome no necesitas Xcode.

## iPhone

Instala Xcode completo, ábrelo para configurar componentes y descarga el runtime iOS. Revisa `flutter doctor` y completa sus indicaciones.

```bash
open -a Simulator
flutter devices
flutter run -d ID_DEL_SIMULADOR
```

Sustituye el ID por el mostrado. En un iPhone físico configura confianza, modo desarrollador y firma. Aleksound 0.6.3 ya está instalada en el teléfono del usuario; esta preparación es para otra instalación o un dispositivo nuevo. Las descargas y pruebas físicas realizadas están en [Validación](validacion.md); llamadas, auriculares y cambios de salida siguen pendientes. Para el uso diario, consulta [Usar Aleksound sin Xcode](#usar-aleksound-sin-xcode).

## Android

Configura Android Studio, SDK y emulador o teléfono. Revisa `flutter doctor`, ejecuta `flutter devices` y luego `flutter run -d ID_DEL_DISPOSITIVO`. Puede esperar mientras se prueba Chrome.

## Problemas frecuentes

- Flutter no encontrado: usa el `export PATH` anterior o `/Users/erickvzh/develop/flutter/bin/flutter`.
- `Application finished`: reinicia la app con el comando de ejecución.
- No suena inicialmente: el navegador requiere pulsar reproducir.
- Favoritos ausentes: usa mismo navegador, perfil, dirección y puerto; evita incógnito.
- La app instalada no abre: comprueba modo desarrollador, confianza y vigencia de la firma; renueva sin desinstalar si venció. Cerrar Xcode por sí solo no impide abrir Release desde el icono.
- Una canción falla en el iPhone: revisa [Guía de uso](guia-de-uso.md#si-algo-falla). No borrar la app, las descargas ni el certificado para solucionar un fallo de YouTube.
- Una demo falla en desarrollo: confirma los archivos de `assets/audio/`, ejecuta `flutter pub get` y vuelve a intentar. Esto no diagnostica una canción remota.

Referencias oficiales: [instalación de Flutter](https://docs.flutter.dev/get-started/install) y [Flutter web](https://docs.flutter.dev/platform-integration/web/building).
