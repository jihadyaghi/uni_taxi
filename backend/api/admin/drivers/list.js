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
  res.setHeader("Access-Control-Allow-Methods", "GET,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (req.method === "OPTIONS") return res.status(200).end();

  if (req.method !== "GET") {
    return res.status(405).json({ ok: false });
  }

  try {
    const db = getPool();
    const [drivers] = await db.query(`
      SELECT id,name,phone,car_model,plate_number,is_active
      FROM users
      WHERE role='driver'
    `);

    res.json({ ok: true, drivers });
  } catch (e) {
    res.status(500).json({ ok: false, msg: e.message });
  }
}