# SOS Dispatch API

Servidor de despacho con **SQLite**, flota de ambulancias y elección de unidad.

```bash
cd dispatch-api
npm install
npm start
```

Base de datos: `dispatch-api/data/dispatch.sqlite`

## App iOS

La URL y la API key van en `Info.plist` (`SOSDispatchBaseURL`, `SOSDispatchAPIKey`) — **no** en Ajustes del usuario.

## Endpoints

- `GET /v1/ambulances?latitude=&longitude=`
- `POST /v1/emergencies` con `assignmentMode`: `closest` | `manual` (+ `ambulanceId`)
- `GET /v1/emergencies/:id`
- `GET|POST /v1/emergencies/:id/chat`
