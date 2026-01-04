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
  //CORS
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  //Preflight request
  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }

  if (req.method !== "GET") {
    return res.status(405).json({ ok: false, msg: "Method not allowed" });
  }

  try {
    const { userId } = req.query;

    if (!userId) {
      return res.status(400).json({ ok: false, msg: "Missing userId" });
    }

    const db = getPool();

    const [rows] = await db.query(
      `SELECT *
       FROM trips
       WHERE user_id = ?
       ORDER BY created_at DESC`,
      [userId]
    );
    return res.status(200).json({
      ok: true,
      trips: rows,
    });
  } catch (err) {
    console.error("MY TRIPS ERROR:", err);
    return res.status(500).json({
      ok: false,
      error: err.message,
    });
  }
}