# SOS — Emergencias Santa Cruz

Aplicación iOS nativa para seguimiento de ambulancias y perfil de salud de emergencia en **Santa Cruz de la Sierra, Bolivia**.

## Requisitos

- Xcode 16+
- iOS 17.0+
- Swift 5 / SwiftUI

## Abrir el proyecto

```bash
open SOS.xcodeproj
```

Selecciona un simulador iPhone (recomendado: iPhone 15 o superior) y presiona **Run** (⌘R).

## Arquitectura (MVVM)

```
SOS/
├── Models/          # Datos de emergencia y perfil médico
├── ViewModels/      # Lógica de mapa, ETA y perfil
├── Views/           # Pantallas: Mapa, Perfil, Noticias, Ajustes
├── Components/      # UI reutilizable (cabecera, ETA, bloques críticos)
├── Services/        # CoreLocation
└── Theme/           # Paleta rojo/blanco
```

## Funcionalidades

### Mapa interactivo
- MapKit con ubicación del usuario (punto azul nativo)
- Ruta roja hacia la ambulancia unidad **A-31**
- Marcadores de referencia: Plaza 24 de Septiembre, Catedral, Av. Monseñor Rivero, Equipetrol
- Panel flotante con ETA en tiempo real (simulado)
- Botones: Llamar operador, Chat, Primeros auxilios

### Perfil de salud
- Grupo sanguíneo, alergias y medicamentos en bloques rojos de alto contraste
- Contactos de emergencia con llamada directa
- Guía práctica mientras llega la ayuda

### Navegación
Tab bar nativa: **Mapa · Perfil · Noticias · Ajustes**

## Stack tecnológico

| Componente | Framework |
|---|---|
| UI | SwiftUI |
| Mapas | MapKit |
| Ubicación | CoreLocation |
| Estado async | Combine |
| Animaciones | SwiftUI nativo (pulso en ambulancia y ETA) |

> **Nota sobre Lottie:** Las micro-interacciones (pulso del usuario, icono de ambulancia) están implementadas con animaciones nativas de SwiftUI (`symbolEffect`, `withAnimation`). Para añadir Lottie vía SPM: File → Add Package Dependencies → `https://github.com/airbnb/lottie-ios`

## Permisos

La app solicita acceso a ubicación *While Using* para centrar el mapa en Santa Cruz y mostrar tu posición.

## Próximos pasos (producción)

- Conectar API real de despacho de ambulancias
- Autenticación y sincronización del perfil médico
- Push notifications cuando la unidad esté cerca
- Integración con HealthKit
