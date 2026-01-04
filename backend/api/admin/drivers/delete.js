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
    });
  }
  return pool;
}
export default async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "DELETE,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();

  if (req.method !== "DELETE") return res.status(405).json({ ok: false });

  try {
    const driverId = req.query.driverId;
    const db = getPool();

    await db.query(
      `UPDATE users
       SET role='user',
           phone=NULL,
           car_model=NULL,
           plate_number=NULL,
           is_active=1
       WHERE id=?`,
      [driverId]
    );

    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ ok: false, msg: e.message });
  }
}