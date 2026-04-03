import { MongoClient, ServerApiVersion } from 'mongodb';
import express from 'express';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const port = process.env.PORT_BACKEND || 3000;
const uri = process.env.MONGO_URI;

const client = new MongoClient(uri, {
    serverApi: {
        version: ServerApiVersion.v1,
        strict: true,
        deprecationErrors: true,
    }
});

async function startServer() {
    try {
        await client.connect();
        await client.db("admin").command({ ping: 1 });
        console.log("✅ Kết nối MongoDB Atlas thành công!");

        // Khởi động server Express sau khi đã kết nối DB
        app.listen(port, () => {
        console.log(`🚀 Server đang quẩy tại http://localhost:${port}`);
        });

    } catch (err) {
        console.error("❌ Lỗi khởi động hệ thống:", err);
        process.exit(1); // Thoát nếu không kết nối được DB
    }
}

startServer();