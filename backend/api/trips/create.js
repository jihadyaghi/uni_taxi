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
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }

  if (req.method !== "POST") {
    return res.status(405).json({ ok: false, msg: "Method not allowed" });
  }

  try {
    const body = await readBody(req);
    const {
      userId,
      pickupLocation,
      dropLocation,
      university,
      rideTime,        
      paymentMethod,
      price,
    } = body;
    if (!userId || !pickupLocation || !dropLocation || !university || !rideTime || !paymentMethod || price == null) {
      return res.status(400).json({
        ok: false,
        msg: "Missing required fields",
        required: ["userId","pickupLocation","dropLocation","university","rideTime","paymentMethod","price"],
      });
    }
    const db = getPool();
    const [result] = await db.query(
      `INSERT INTO trips
       (user_id, pickup_location, drop_location, university, ride_time, payment_method, price)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [userId, pickupLocation, dropLocation, university, rideTime, paymentMethod, price]
    );
    return res.status(201).json({
      ok: true,
      tripId: result.insertId,
      status: "pending",
    });
  } catch (err) {
    console.error("CREATE TRIP ERROR:", err);
    return res.status(500).json({ ok: false, error: err.message });
  }
}