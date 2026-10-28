/**
 * SOS Dispatch API — flota real + SQLite + elección de unidad.
 *
 * GET  /health
 * GET  /v1/ambulances?latitude=&longitude=
 * POST /v1/emergencies   { assignmentMode: "closest"|"manual", ambulanceId?, ... }
 * GET  /v1/emergencies/:id
 * GET  /v1/emergencies/:id/chat
 * POST /v1/emergencies/:id/chat
 *
 * Auth (solo servidor ↔ app, no UI de usuario): Authorization Bearer SOS_API_KEY
 */
const path = require("path");
const fs = require("fs");
const express = require("express");
const cors = require("cors");
const { randomUUID } = require("crypto");
const { DatabaseSync } = require("node:sqlite");

const PORT = Number(process.env.PORT || 3000);
const API_KEY = process.env.SOS_API_KEY || "sos-dev-key";
const REQUIRE_AUTH = process.env.SOS_REQUIRE_AUTH !== "false";
const DATA_DIR = path.join(__dirname, "data");
const DB_PATH = path.join(DATA_DIR, "dispatch.sqlite");

fs.mkdirSync(DATA_DIR, { recursive: true });
const db = new DatabaseSync(DB_PATH);
db.exec("PRAGMA journal_mode = WAL;");
db.exec("PRAGMA foreign_keys = ON;");

db.exec(`
  CREATE TABLE IF NOT EXISTS ambulances (
    id TEXT PRIMARY KEY,
    unit_number TEXT NOT NULL UNIQUE,
    call_sign TEXT NOT NULL,
    base_name TEXT NOT NULL,
    hospital TEXT NOT NULL,
    level TEXT NOT NULL,
    equipment TEXT NOT NULL,
    crew_size INTEGER NOT NULL,
    status TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL
  );

  CREATE TABLE IF NOT EXISTS tickets (
    id TEXT PRIMARY KEY,
    ambulance_id TEXT NOT NULL,
    unit_number TEXT NOT NULL,
    eta_minutes INTEGER NOT NULL,
    initial_eta INTEGER NOT NULL,
    status TEXT NOT NULL,
    emergency_type TEXT NOT NULL,
    address_label TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    ambulance_latitude REAL NOT NULL,
    ambulance_longitude REAL NOT NULL,
    route_json TEXT NOT NULL,
    health_json TEXT,
    created_at TEXT NOT NULL,
    FOREIGN KEY (ambulance_id) REFERENCES ambulances(id)
  );

  CREATE TABLE IF NOT EXISTS chat_messages (
    id TEXT PRIMARY KEY,
    ticket_id TEXT NOT NULL,
    text TEXT NOT NULL,
    is_from_user INTEGER NOT NULL,
    created_at TEXT NOT NULL,
    FOREIGN KEY (ticket_id) REFERENCES tickets(id)
  );
	CREATE TABLE IF NOT EXISTS phone_otps (
    phone TEXT PRIMARY KEY,
    code TEXT NOT NULL,
    expires_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS auth_users (
    id TEXT PRIMARY KEY,
    provider TEXT NOT NULL,
    subject TEXT NOT NULL,
    full_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    created_at TEXT NOT NULL,
    UNIQUE(provider, subject)
  );
`);

const countAmbulances = db.prepare("SELECT COUNT(*) AS c FROM ambulances").get().c;
if (countAmbulances === 0) {
  const insert = db.prepare(`
    INSERT INTO ambulances
    (id, unit_number, call_sign, base_name, hospital, level, equipment, crew_size, status, latitude, longitude)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);
  const seed = [
    ["amb-01", "A-08", "Águila 8", "Base Equipetrol", "Clínica Foianini", "Avanzada", "Desfibrilador, oxígeno, trauma", 3, "available", -17.7610, -63.1780],
    ["amb-02", "A-17", "Águila 17", "Base Centro", "Hospital Japonés", "Básica", "Oxígeno, inmovilización", 2, "available", -17.7836, -63.1811],
    ["amb-03", "A-31", "Águila 31", "Base Norte", "Clínica Alemana", "Avanzada", "UCI móvil, monitor, bomba de infusión", 3, "available", -17.7550, -63.1650],
    ["amb-04", "A-42", "Águila 42", "Base Plan 3000", "Hospital San Juan de Dios", "Básica", "Oxígeno, botiquín avanzado", 2, "available", -17.8160, -63.1450],
    ["amb-05", "A-55", "Águila 55", "Base Urubó", "Clínica Los Olivos", "Avanzada", "Neonatal, oxígeno, trauma", 3, "available", -17.7700, -63.2200],
    ["amb-06", "A-63", "Águila 63", "Base El Bajío", "Caja Petrolera", "Básica", "Oxígeno, camilla, férulas", 2, "busy", -17.7900, -63.2000],
  ];
  for (const row of seed) insert.run(...row);
  console.log(`Semilla: ${seed.length} ambulancias en SQLite`);
}

const app = express();
app.use(cors());
app.use(express.json({ limit: "256kb" }));

function nowISO() {
  return new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
}

function error(res, status, message) {
  return res.status(status).json({ message });
}

function auth(req, res, next) {
  if (!REQUIRE_AUTH) return next();
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7).trim() : "";
  if (token !== API_KEY) {
    return error(res, 401, "No autorizado.");
  }
  return next();
}

function haversineKm(lat1, lon1, lat2, lon2) {
  const toRad = (d) => (d * Math.PI) / 180;
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function etaFromKm(km) {
  // ~28 km/h promedio urbano Santa Cruz + mínimo 4 min
  return Math.max(4, Math.round((km / 28) * 60) + 2);
}

function buildRoute(fromLat, fromLon, toLat, toLon) {
  return [
    { latitude: fromLat, longitude: fromLon },
    {
      latitude: fromLat + (toLat - fromLat) * 0.33,
      longitude: fromLon + (toLon - fromLon) * 0.33,
    },
    {
      latitude: fromLat + (toLat - fromLat) * 0.66,
      longitude: fromLon + (toLon - fromLon) * 0.66,
    },
    { latitude: toLat, longitude: toLon },
  ];
}

function interpolate(route, progress) {
  if (!route.length) return { latitude: 0, longitude: 0 };
  if (route.length === 1) return route[0];
  const clamped = Math.min(Math.max(progress, 0), 1);
  const segmentCount = route.length - 1;
  const scaled = clamped * segmentCount;
  const index = Math.min(Math.floor(scaled), segmentCount - 1);
  const fraction = scaled - index;
  const start = route[index];
  const end = route[index + 1];
  return {
    latitude: start.latitude + (end.latitude - start.latitude) * fraction,
    longitude: start.longitude + (end.longitude - start.longitude) * fraction,
  };
}

function mapAmbulance(row, userLat, userLon) {
  const distanceKm = haversineKm(userLat, userLon, row.latitude, row.longitude);
  return {
    id: row.id,
    unitNumber: row.unit_number,
    callSign: row.call_sign,
    baseName: row.base_name,
    hospital: row.hospital,
    level: row.level,
    equipment: row.equipment,
    crewSize: row.crew_size,
    status: row.status,
    latitude: row.latitude,
    longitude: row.longitude,
    distanceKm: Math.round(distanceKm * 10) / 10,
    etaMinutes: etaFromKm(distanceKm),
  };
}

function ticketToDTO(row) {
  const route = JSON.parse(row.route_json);
  let status = row.status;
  let etaMinutes = row.eta_minutes;
  let ambLat = row.ambulance_latitude;
  let ambLon = row.ambulance_longitude;

  if (status !== "arrived" && status !== "closed") {
    const created = new Date(row.created_at).getTime();
    const durationMs = Math.max(row.initial_eta, 1) * 45 * 1000;
    const progress = Math.min(1, (Date.now() - created) / durationMs);
    const point = interpolate(route, progress);
    ambLat = point.latitude;
    ambLon = point.longitude;
    etaMinutes = Math.max(0, Math.ceil(row.initial_eta * (1 - progress)));
    if (progress >= 1) {
      status = "arrived";
      etaMinutes = 0;
    } else if (progress >= 0.85) status = "arriving";
    else if (progress >= 0.55) status = "nearby";
    else status = "en_route";

    db.prepare(
      `UPDATE tickets SET status = ?, eta_minutes = ?, ambulance_latitude = ?, ambulance_longitude = ? WHERE id = ?`
    ).run(status, etaMinutes, ambLat, ambLon, row.id);
  }

  return {
    id: row.id,
    unitNumber: row.unit_number,
    etaMinutes,
    status,
    emergencyType: row.emergency_type,
    addressLabel: row.address_label,
    latitude: row.latitude,
    longitude: row.longitude,
    ambulanceLatitude: ambLat,
    ambulanceLongitude: ambLon,
    route,
    createdAt: row.created_at,
  };
}

function autoReply(text, ticket) {
  const lower = String(text || "").toLowerCase();
  if (lower.includes("sangrado")) {
    return `Aplica presión firme. Unidad ${ticket.unitNumber} en ruta · ETA ${ticket.etaMinutes} min.`;
  }
  if (lower.includes("respir")) {
    return "Mantén al paciente erguido y con aire fresco. Avisa si labios o uñas se ponen azulados.";
  }
  if (lower.includes("consciente")) {
    return "Recibido. Quédate a su lado; no le des comida ni líquidos hasta que llegue la ambulancia.";
  }
  return `Despacho SOS · Unidad ${ticket.unitNumber} · ${ticket.status} · ETA ${ticket.etaMinutes} min.`;
}

app.get("/health", (_req, res) => {
  const ambulances = db.prepare("SELECT COUNT(*) AS c FROM ambulances").get().c;
  const tickets = db.prepare("SELECT COUNT(*) AS c FROM tickets").get().c;
  res.json({ ok: true, service: "sos-dispatch-api", database: "sqlite", ambulances, tickets });
});

function normalizePhone(raw) {
  return String(raw || "").replace(/[^\d+]/g, "");
}

app.post("/v1/auth/phone/request", auth, (req, res) => {
  const phone = normalizePhone(req.body && req.body.phone);
  if (phone.length < 8) {
    return error(res, 400, "Ingresa un número de celular válido.");
  }
  const code = String(Math.floor(100000 + Math.random() * 900000));
  const expires = new Date(Date.now() + 10 * 60 * 1000).toISOString().replace(/\.\d{3}Z$/, "Z");
  db.prepare(
    `INSERT INTO phone_otps (phone, code, expires_at) VALUES (?, ?, ?)
     ON CONFLICT(phone) DO UPDATE SET code = excluded.code, expires_at = excluded.expires_at`
  ).run(phone, code, expires);

  // En producción aquí iría el SMS (Twilio, etc.). En red local devolvemos el código para pruebas.
  console.log(`[otp] ${phone} → ${code}`);
  return res.json({
    ok: true,
    message: "Código enviado",
    expiresInSeconds: 600,
    debugCode: code,
  });
});

app.post("/v1/auth/phone/verify", auth, (req, res) => {
  const phone = normalizePhone(req.body && req.body.phone);
  const code = String((req.body && req.body.code) || "").trim();
  const row = db.prepare("SELECT * FROM phone_otps WHERE phone = ?").get(phone);
  if (!row || row.code !== code) {
    return error(res, 401, "Código incorrecto o vencido.");
  }
  if (new Date(row.expires_at).getTime() < Date.now()) {
    return error(res, 401, "El código venció. Solicita uno nuevo.");
  }
  db.prepare("DELETE FROM phone_otps WHERE phone = ?").run(phone);

  let user = db
    .prepare("SELECT * FROM auth_users WHERE provider = 'phone' AND subject = ?")
    .get(phone);
  if (!user) {
    const id = randomUUID();
    const createdAt = nowISO();
    db.prepare(
      `INSERT INTO auth_users (id, provider, subject, full_name, email, phone, created_at)
       VALUES (?, 'phone', ?, ?, NULL, ?, ?)`
    ).run(id, phone, `Usuario ${phone.slice(-4)}`, phone, createdAt);
    user = db.prepare("SELECT * FROM auth_users WHERE id = ?").get(id);
  }

  return res.json({
    id: user.id,
    provider: user.provider,
    fullName: user.full_name,
    email: user.email,
    phone: user.phone,
  });
});

app.get("/v1/ambulances", auth, (req, res) => {
  const latitude = Number(req.query.latitude);
  const longitude = Number(req.query.longitude);
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    return error(res, 400, "latitude y longitude son obligatorios.");
  }

  const onlyAvailable = String(req.query.available || "true") !== "false";
  const rows = onlyAvailable
    ? db.prepare("SELECT * FROM ambulances WHERE status = 'available'").all()
    : db.prepare("SELECT * FROM ambulances").all();

  const list = rows
    .map((row) => mapAmbulance(row, latitude, longitude))
    .sort((a, b) => a.distanceKm - b.distanceKm);

  res.json({ ambulances: list });
});

app.post("/v1/emergencies", auth, (req, res) => {
  const body = req.body || {};
  const latitude = Number(body.latitude);
  const longitude = Number(body.longitude);
  const mode = body.assignmentMode === "manual" ? "manual" : "closest";

  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    return error(res, 400, "latitude y longitude son obligatorios.");
  }
  if (!body.emergencyType || !body.addressLabel) {
    return error(res, 400, "emergencyType y addressLabel son obligatorios.");
  }

  const available = db
    .prepare("SELECT * FROM ambulances WHERE status = 'available'")
    .all()
    .map((row) => mapAmbulance(row, latitude, longitude))
    .sort((a, b) => a.distanceKm - b.distanceKm);

  if (!available.length) {
    return error(res, 409, "No hay ambulancias disponibles en este momento. Llama al 911.");
  }

  let chosen = available[0];
  if (mode === "manual") {
    if (!body.ambulanceId) {
      return error(res, 400, "ambulanceId es obligatorio en modo manual.");
    }
    chosen = available.find((a) => a.id === body.ambulanceId);
    if (!chosen) {
      return error(res, 404, "La ambulancia elegida no está disponible.");
    }
  }

  const route = buildRoute(chosen.latitude, chosen.longitude, latitude, longitude);
  const id = randomUUID();
  const createdAt = nowISO();
  const health =
    body.shareHealthProfile
      ? {
          userName: body.userName || null,
          bloodType: body.bloodType || null,
          allergies: body.allergies || [],
          medications: body.medications || [],
        }
      : null;

  db.prepare(
    `INSERT INTO tickets
     (id, ambulance_id, unit_number, eta_minutes, initial_eta, status, emergency_type, address_label,
      latitude, longitude, ambulance_latitude, ambulance_longitude, route_json, health_json, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
  ).run(
    id,
    chosen.id,
    chosen.unitNumber,
    chosen.etaMinutes,
    chosen.etaMinutes,
    "assigned",
    String(body.emergencyType),
    String(body.addressLabel),
    latitude,
    longitude,
    chosen.latitude,
    chosen.longitude,
    JSON.stringify(route),
    health ? JSON.stringify(health) : null,
    createdAt
  );

  db.prepare(`UPDATE ambulances SET status = 'busy' WHERE id = ?`).run(chosen.id);

  const welcomeId = randomUUID();
  db.prepare(
    `INSERT INTO chat_messages (id, ticket_id, text, is_from_user, created_at) VALUES (?, ?, ?, 0, ?)`
  ).run(
    welcomeId,
    id,
    `Despacho SOS. Unidad ${chosen.unitNumber} (${chosen.callSign}) asignada · ETA ${chosen.etaMinutes} min · Base ${chosen.baseName}.`,
    createdAt
  );

  console.log(`[dispatch] ${id} · ${chosen.unitNumber} · mode=${mode} · ${body.emergencyType}`);

  const row = db.prepare("SELECT * FROM tickets WHERE id = ?").get(id);
  return res.status(201).json(ticketToDTO(row));
});

app.get("/v1/emergencies/:id", auth, (req, res) => {
  const row = db.prepare("SELECT * FROM tickets WHERE id = ?").get(req.params.id);
  if (!row) return error(res, 404, "Pedido no encontrado.");
  const dto = ticketToDTO(row);
  if (dto.status === "arrived") {
    db.prepare(`UPDATE ambulances SET status = 'available' WHERE id = ?`).run(row.ambulance_id);
  }
  return res.json(dto);
});

app.get("/v1/emergencies/:id/chat", auth, (req, res) => {
  const exists = db.prepare("SELECT id FROM tickets WHERE id = ?").get(req.params.id);
  if (!exists) return error(res, 404, "Pedido no encontrado.");
  const rows = db
    .prepare(
      `SELECT id, text, is_from_user AS isFromUser, created_at AS createdAt
       FROM chat_messages WHERE ticket_id = ? ORDER BY created_at ASC`
    )
    .all(req.params.id)
    .map((m) => ({
      id: m.id,
      text: m.text,
      isFromUser: !!m.isFromUser,
      createdAt: m.createdAt,
    }));
  return res.json(rows);
});

app.post("/v1/emergencies/:id/chat", auth, (req, res) => {
  const row = db.prepare("SELECT * FROM tickets WHERE id = ?").get(req.params.id);
  if (!row) return error(res, 404, "Pedido no encontrado.");

  const text = String((req.body && req.body.text) || "").trim();
  if (!text) return error(res, 400, "text es obligatorio.");

  const createdAt = nowISO();
  db.prepare(
    `INSERT INTO chat_messages (id, ticket_id, text, is_from_user, created_at) VALUES (?, ?, ?, 1, ?)`
  ).run(randomUUID(), req.params.id, text, createdAt);

  const ticket = ticketToDTO(row);
  const reply = {
    id: randomUUID(),
    text: autoReply(text, ticket),
    isFromUser: false,
    createdAt: nowISO(),
  };
  db.prepare(
    `INSERT INTO chat_messages (id, ticket_id, text, is_from_user, created_at) VALUES (?, ?, ?, 0, ?)`
  ).run(reply.id, req.params.id, reply.text, reply.createdAt);

  return res.status(201).json(reply);
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`SOS Dispatch API + SQLite → http://0.0.0.0:${PORT}`);
  console.log(`DB: ${DB_PATH}`);
});
