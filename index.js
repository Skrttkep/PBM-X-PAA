const express = require("express");
const cors = require("cors");
const swaggerUi = require("swagger-ui-express");

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// =======================
// DATABASE SEMENTARA
// =======================
// Untuk awal belajar, kita pakai array dulu.
// Nanti kalau sudah paham, baru pindah ke MySQL/PostgreSQL.

let users = [
  {
    id: 1,
    name: "Mario",
    email: "mario@gmail.com",
    password: "123456",
    weight: 60,
    height: 170
  }
];

let activities = [];

let dailyTargets = [
  {
    id: 1,
    user_id: 1,
    target_calories: 500,
    date: "2026-05-16"
  }
];

// =======================
// SWAGGER DOCUMENTATION
// =======================

const swaggerDocument = {
  openapi: "3.0.0",
  info: {
    title: "Smart Activity & Calorie Burn Tracker API",
    version: "1.0.0",
    description: "API untuk mendeteksi aktivitas, menghitung kalori, target harian, dan warning sedentary."
  },
  servers: [
    {
      url: "http://localhost:3000",
      description: "Local server"
    }
  ],
  paths: {
    "/": {
      get: {
        summary: "Cek apakah API berjalan",
        responses: {
          200: {
            description: "API berjalan"
          }
        }
      }
    },
    "/api/register": {
      post: {
        summary: "Register user baru",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  name: { type: "string" },
                  email: { type: "string" },
                  password: { type: "string" },
                  weight: { type: "number" },
                  height: { type: "number" }
                },
                example: {
                  name: "Budi",
                  email: "budi@gmail.com",
                  password: "123456",
                  weight: 65,
                  height: 172
                }
              }
            }
          }
        },
        responses: {
          201: {
            description: "Register berhasil"
          }
        }
      }
    },
    "/api/login": {
      post: {
        summary: "Login user",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                example: {
                  email: "mario@gmail.com",
                  password: "123456"
                }
              }
            }
          }
        },
        responses: {
          200: {
            description: "Login berhasil"
          },
          401: {
            description: "Email atau password salah"
          }
        }
      }
    },
    "/api/activities": {
      post: {
        summary: "Menambahkan data aktivitas",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                example: {
                  user_id: 1,
                  activity_type: "walking",
                  duration_minutes: 30
                }
              }
            }
          }
        },
        responses: {
          201: {
            description: "Aktivitas berhasil disimpan"
          }
        }
      }
    },
    "/api/activities/{user_id}": {
      get: {
        summary: "Mengambil riwayat aktivitas user",
        parameters: [
          {
            name: "user_id",
            in: "path",
            required: true,
            schema: {
              type: "integer"
            }
          }
        ],
        responses: {
          200: {
            description: "Data aktivitas user"
          }
        }
      }
    },
    "/api/activities/today/{user_id}": {
      get: {
        summary: "Mengambil total kalori user hari ini",
        parameters: [
          {
            name: "user_id",
            in: "path",
            required: true,
            schema: {
              type: "integer"
            }
          }
        ],
        responses: {
          200: {
            description: "Total kalori hari ini"
          }
        }
      }
    },
    "/api/daily-target": {
      post: {
        summary: "Menambahkan atau mengubah target kalori harian",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                example: {
                  user_id: 1,
                  target_calories: 500
                }
              }
            }
          }
        },
        responses: {
          200: {
            description: "Target berhasil disimpan"
          }
        }
      }
    },
    "/api/daily-target/{user_id}": {
      get: {
        summary: "Mengambil progress target harian user",
        parameters: [
          {
            name: "user_id",
            in: "path",
            required: true,
            schema: {
              type: "integer"
            }
          }
        ],
        responses: {
          200: {
            description: "Progress target harian"
          }
        }
      }
    },
    "/api/sedentary-warning/{user_id}": {
      get: {
        summary: "Mengecek apakah user terlalu lama diam",
        parameters: [
          {
            name: "user_id",
            in: "path",
            required: true,
            schema: {
              type: "integer"
            }
          }
        ],
        responses: {
          200: {
            description: "Status sedentary user"
          }
        }
      }
    }
  }
};

app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerDocument));

// =======================
// HELPER FUNCTION
// =======================

function getTodayDate() {
  return new Date().toISOString().split("T")[0];
}

function calculateCalories(activityType, weight, durationMinutes) {
  let met = 1.0;

  if (activityType === "idle") {
    met = 1.0;
  } else if (activityType === "walking") {
    met = 3.5;
  } else if (activityType === "running") {
    met = 7.0;
  }

  const durationHours = durationMinutes / 60;
  const calories = met * weight * durationHours;

  return Math.round(calories);
}

// =======================
// ROUTES
// =======================

app.get("/", (req, res) => {
  res.json({
    message: "Smart Activity & Calorie Burn Tracker API berjalan"
  });
});

// REGISTER
app.post("/api/register", (req, res) => {
  const { name, email, password, weight, height } = req.body;

  if (!name || !email || !password || !weight || !height) {
    return res.status(400).json({
      message: "Semua field wajib diisi"
    });
  }

  const existingUser = users.find((user) => user.email === email);

  if (existingUser) {
    return res.status(400).json({
      message: "Email sudah terdaftar"
    });
  }

  const newUser = {
    id: users.length + 1,
    name,
    email,
    password,
    weight,
    height
  };

  users.push(newUser);

  res.status(201).json({
    message: "Register berhasil",
    data: newUser
  });
});

// LOGIN
app.post("/api/login", (req, res) => {
  const { email, password } = req.body;

  const user = users.find(
    (user) => user.email === email && user.password === password
  );

  if (!user) {
    return res.status(401).json({
      message: "Email atau password salah"
    });
  }

  res.json({
    message: "Login berhasil",
    data: {
      id: user.id,
      name: user.name,
      email: user.email,
      weight: user.weight,
      height: user.height
    }
  });
});

// TAMBAH AKTIVITAS
app.post("/api/activities", (req, res) => {
  const { user_id, activity_type, duration_minutes } = req.body;

  if (!user_id || !activity_type || !duration_minutes) {
    return res.status(400).json({
      message: "user_id, activity_type, dan duration_minutes wajib diisi"
    });
  }

  const user = users.find((user) => user.id === Number(user_id));

  if (!user) {
    return res.status(404).json({
      message: "User tidak ditemukan"
    });
  }

  const allowedActivities = ["idle", "walking", "running"];

  if (!allowedActivities.includes(activity_type)) {
    return res.status(400).json({
      message: "activity_type hanya boleh idle, walking, atau running"
    });
  }

  const caloriesBurned = calculateCalories(
    activity_type,
    user.weight,
    duration_minutes
  );

  const newActivity = {
    id: activities.length + 1,
    user_id: Number(user_id),
    activity_type,
    duration_minutes,
    calories_burned: caloriesBurned,
    date: getTodayDate(),
    created_at: new Date().toISOString()
  };

  activities.push(newActivity);

  res.status(201).json({
    message: "Aktivitas berhasil disimpan",
    data: newActivity
  });
});

// RIWAYAT AKTIVITAS USER
app.get("/api/activities/:user_id", (req, res) => {
  const userId = Number(req.params.user_id);

  const userActivities = activities.filter(
    (activity) => activity.user_id === userId
  );

  res.json({
    message: "Data aktivitas berhasil diambil",
    data: userActivities
  });
});

// TOTAL KALORI HARI INI
app.get("/api/activities/today/:user_id", (req, res) => {
  const userId = Number(req.params.user_id);
  const today = getTodayDate();

  const todayActivities = activities.filter(
    (activity) => activity.user_id === userId && activity.date === today
  );

  const totalCalories = todayActivities.reduce(
    (total, activity) => total + activity.calories_burned,
    0
  );

  const totalDuration = todayActivities.reduce(
    (total, activity) => total + activity.duration_minutes,
    0
  );

  res.json({
    message: "Total aktivitas hari ini berhasil diambil",
    data: {
      user_id: userId,
      date: today,
      total_duration_minutes: totalDuration,
      total_calories_burned: totalCalories,
      activities: todayActivities
    }
  });
});

// SIMPAN TARGET HARIAN
app.post("/api/daily-target", (req, res) => {
  const { user_id, target_calories } = req.body;
  const today = getTodayDate();

  if (!user_id || !target_calories) {
    return res.status(400).json({
      message: "user_id dan target_calories wajib diisi"
    });
  }

  const existingTarget = dailyTargets.find(
    (target) => target.user_id === Number(user_id) && target.date === today
  );

  if (existingTarget) {
    existingTarget.target_calories = target_calories;

    return res.json({
      message: "Target harian berhasil diperbarui",
      data: existingTarget
    });
  }

  const newTarget = {
    id: dailyTargets.length + 1,
    user_id: Number(user_id),
    target_calories,
    date: today
  };

  dailyTargets.push(newTarget);

  res.json({
    message: "Target harian berhasil disimpan",
    data: newTarget
  });
});

// CEK TARGET HARIAN
app.get("/api/daily-target/:user_id", (req, res) => {
  const userId = Number(req.params.user_id);
  const today = getTodayDate();

  const target = dailyTargets.find(
    (target) => target.user_id === userId && target.date === today
  );

  const todayActivities = activities.filter(
    (activity) => activity.user_id === userId && activity.date === today
  );

  const burnedCalories = todayActivities.reduce(
    (total, activity) => total + activity.calories_burned,
    0
  );

  const targetCalories = target ? target.target_calories : 0;
  const remainingCalories = Math.max(targetCalories - burnedCalories, 0);

  res.json({
    message: "Progress target harian berhasil diambil",
    data: {
      user_id: userId,
      date: today,
      target_calories: targetCalories,
      burned_calories: burnedCalories,
      remaining_calories: remainingCalories,
      status:
        targetCalories === 0
          ? "Target belum diatur"
          : burnedCalories >= targetCalories
          ? "Target tercapai"
          : "Target belum tercapai"
    }
  });
});

// WARNING SEDENTARY
app.get("/api/sedentary-warning/:user_id", (req, res) => {
  const userId = Number(req.params.user_id);
  const today = getTodayDate();

  const todayIdleActivities = activities.filter(
    (activity) =>
      activity.user_id === userId &&
      activity.date === today &&
      activity.activity_type === "idle"
  );

  const totalIdleMinutes = todayIdleActivities.reduce(
    (total, activity) => total + activity.duration_minutes,
    0
  );

  const isSedentary = totalIdleMinutes >= 60;

  res.json({
    message: "Status sedentary berhasil dicek",
    data: {
      user_id: userId,
      idle_minutes: totalIdleMinutes,
      is_sedentary: isSedentary,
      warning_message: isSedentary
        ? "Kamu sudah terlalu lama diam. Ayo jalan sebentar!"
        : "Aktivitas kamu masih aman."
    }
  });
});

// JALANKAN SERVER
app.listen(PORT, () => {
  console.log(`Server berjalan di http://localhost:${PORT}`);
  console.log(`Swagger tersedia di http://localhost:${PORT}/api-docs`);
});