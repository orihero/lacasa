// Loading src/lib/config.js (transitively, via app.js) validates the
// environment and fails fast — before anything else in this process runs —
// with one readable message listing every missing required var at once.
import { createApp } from "./app.js";
import { config } from "./lib/config.js";
import { createPrismaClient } from "./lib/prisma.js";
import { createMinioClient } from "./lib/minio.js";
import { createLlmClient } from "./lib/llm.js";
import { scheduleIgTokenRefresh } from "./lib/igTokenRefresh.js";

const prisma = createPrismaClient();
const minio = createMinioClient();
const llm = createLlmClient();

const app = createApp({ prisma, minio, llm });

scheduleIgTokenRefresh(prisma);

app.listen(config.PORT, () => console.log(`API listening on http://localhost:${config.PORT}`));
