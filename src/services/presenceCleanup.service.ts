import { redis as pub } from "../plugins/redis";
import { prisma } from "../plugins/prisma";

const CHECK_INTERVAL_MS = 60 * 1000; // har 60s

async function cleanupExpiredPresence(app: any): Promise<void> {
  try {
    const userIds = await pub.smembers("online_user_ids");
    if (userIds.length === 0) return;

    for (const userId of userIds) {
      const stillOnline = await pub.exists(`presence:${userId}`);
      if (!stillOnline) {
        await pub.srem("online_user_ids", userId);
        await prisma.user
          .update({
            where: { id: userId },
            data: { isOnline: false, lastSeen: new Date() },
          })
          .catch(() => {});
        app.broadcastAll({ type: "USER_OFFLINE", userId });
      }
    }
  } catch (err) {
    console.error("[presenceCleanup] Failed:", err);
  }
}

export function startPresenceCleanupJob(app: any): void {
  setInterval(() => cleanupExpiredPresence(app), CHECK_INTERVAL_MS);
  console.log(`[presenceCleanup] Job started — runs every ${CHECK_INTERVAL_MS / 1000}s.`);
}
