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
export default async function handler(req, res) {
  // CORS
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();

  if (req.method !== "GET") {
    return res.status(405).json({ ok: false, msg: "Method not allowed" });
  }

  try {
    const db = getPool();
    const { status, driverId, assignedOnly } = req.query;
    let sql = `
      SELECT 
        t.*,
        u.name AS user_name,
        u.email AS user_email
      FROM trips t
      JOIN users u ON u.id = t.user_id
    `;

    const where = [];
    const params = [];

    if (status) {
      where.push(`t.status = ?`);
      params.push(status);
    }

    //filter by driverId (for Driver page)
    if (driverId) {
      where.push(`t.driver_id = ?`);
      params.push(driverId);
    }

    //only trips that have a driver assigned
    if (assignedOnly === "1") {
      where.push(`t.driver_id IS NOT NULL`);
    }

    if (where.length) {
      sql += ` WHERE ` + where.join(" AND ");
    }

    sql += ` ORDER BY t.created_at DESC`;

    const [rows] = await db.query(sql, params);

    return res.status(200).json({ ok: true, trips: rows });
  } catch (err) {
    console.error("ADMIN ALL TRIPS ERROR:", err);
    return res.status(500).json({ ok: false, error: err.message });
  }
}