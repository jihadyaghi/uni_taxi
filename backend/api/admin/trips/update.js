import mysql from "mysql2/promise";
let pool;
function getPool() {
  if (!pool) {
    pool = mysql.createPool({
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT),
      user: process.env.DB_USER,
      password: process.env.DB_PASS,
      database: process.env.DB_NAME,
      waitForConnections: true,
      connectionLimit: 2,
      connectTimeout: 10000,
    });
  }
  return pool;
}
// read body for vercel
async function readBody(req) {
  return new Promise((resolve) => {
    let data = "";
    req.on("data", (chunk) => (data += chunk));
    req.on("end", () => {
      try {
        resolve(JSON.parse(data || "{}"));
      } catch {
        resolve({});
      }
    });
  });
}
export default async function handler(req, res) {
  // CORS
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();

  if (req.method !== "POST") {
    return res.status(405).json({ ok: false, msg: "Method not allowed" });
  }

  try {
    const body = await readBody(req);

    //  driverId optional
    const { tripId, status, adminNote, driverId } = body;

    if (!tripId || !status) {
      return res.status(400).json({ ok: false, msg: "Missing tripId/status" });
    }

    //added "assigned"
    const allowed = ["pending", "approved", "assigned", "rejected", "completed", "cancelled"];
    if (!allowed.includes(status)) {
      return res.status(400).json({ ok: false, msg: "Invalid status" });
    }
    if (status === "assigned" && !driverId) {
      return res.status(400).json({ ok: false, msg: "Missing driverId for assigned status" });
    }

    const db = getPool();
    let result;

    if (driverId) {
      // Assign driver (and update status/note)
      [result] = await db.query(
        `UPDATE trips
         SET status = ?,
             admin_note = ?,
             driver_id = ?,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = ?`,
        [status, adminNote ?? null, driverId, tripId]
      );
    } else {
      // Normal update (no driver assignment)
      [result] = await db.query(
        `UPDATE trips
         SET status = ?,
             admin_note = ?,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = ?`,
        [status, adminNote ?? null, tripId]
      );
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({ ok: false, msg: "Trip not found" });
    }

    return res.status(200).json({
      ok: true,
      msg: driverId ? "Trip updated & driver assigned" : "Trip updated",
    });
  } catch (err) {
    console.error("ADMIN UPDATE TRIP ERROR:", err);
    return res.status(500).json({ ok: false, error: err.message });
  }
}