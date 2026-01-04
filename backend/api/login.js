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
  /*  CORS HEADERS */
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  // preflight
  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }
  if (req.method !== "POST") {
    return res.status(405).json({ ok: false, msg: "Method not allowed" });
  }
  try {
    const { email, password } = await readBody(req);
    if (!email || !password) {
      return res.status(400).json({
        ok: false,
        msg: "Missing email/password",
      });
    }
    const db = getPool();
    const [rows] = await db.query(
      `SELECT id, name, email, role 
       FROM users 
       WHERE email=? AND password=? 
       LIMIT 1`,
      [email, password]
    );

    if (!rows.length) {
      return res.status(401).json({
        ok: false,
        msg: "Invalid credentials",
      });
    }

    return res.status(200).json({
      ok: true,
      user: rows[0],
    });
  } catch (e) {
    console.error("LOGIN ERROR:", e);
    return res.status(500).json({
      ok: false,
      error: e.message,
    });
  }
}