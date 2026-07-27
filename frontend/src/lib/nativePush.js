// Native (Capacitor iOS/Android) push — FCM/APNs token registration
import { Capacitor } from "@capacitor/core";
import api from "@/lib/api";

const TOKEN_KEY = "native_push_token";

export function isNative() {
  return Capacitor.isNativePlatform();
}

let bound = false;

async function plugin() {
  const { PushNotifications } = await import("@capacitor/push-notifications");
  return PushNotifications;
}

async function bindListeners(PushNotifications) {
  if (bound) return;
  bound = true;
  PushNotifications.addListener("registration", async (token) => {
    try {
      localStorage.setItem(TOKEN_KEY, token.value);
      await api.post("/push/register-device", { token: token.value, platform: Capacitor.getPlatform() });
    } catch (e) {
      console.warn("device token registration failed", e);
    }
  });
  PushNotifications.addListener("registrationError", (err) => console.warn("push registration error", err));
  PushNotifications.addListener("pushNotificationActionPerformed", (action) => {
    const link = action?.notification?.data?.link;
    if (link) window.location.href = link;
  });
}

export async function nativePushPermission() {
  if (!isNative()) return "unsupported";
  const PushNotifications = await plugin();
  const { receive } = await PushNotifications.checkPermissions();
  return receive; // "granted" | "denied" | "prompt" | "prompt-with-rationale"
}

export async function initNativePush() {
  if (!isNative()) return "unsupported";
  const PushNotifications = await plugin();
  await bindListeners(PushNotifications);
  let { receive } = await PushNotifications.checkPermissions();
  if (receive === "prompt" || receive === "prompt-with-rationale") {
    ({ receive } = await PushNotifications.requestPermissions());
  }
  if (receive !== "granted") return receive;
  await PushNotifications.register();
  return "granted";
}

// Silent re-register on login when permission already granted (FCM tokens rotate)
export async function syncNativePushToken() {
  if (!isNative()) return;
  try {
    const PushNotifications = await plugin();
    const { receive } = await PushNotifications.checkPermissions();
    if (receive !== "granted") return;
    await bindListeners(PushNotifications);
    await PushNotifications.register();
  } catch (e) {
    console.warn("native push sync failed", e);
  }
}

export async function disableNativePush() {
  if (!isNative()) return;
  const token = localStorage.getItem(TOKEN_KEY);
  if (token) {
    try { await api.post("/push/unregister-device", { token }); } catch { /* noop */ }
    localStorage.removeItem(TOKEN_KEY);
  }
}
