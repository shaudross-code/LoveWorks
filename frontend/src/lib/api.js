import axios from "axios";
import { Capacitor } from "@capacitor/core";
import { toast } from "sonner";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;
export const API_BASE = `${BACKEND_URL}/api`;

const TOKEN_KEY = "access_token";
// The website signs in with httpOnly cookies; only the native shell (or a cross-origin host) needs a Bearer token.
const USE_BEARER = Capacitor.isNativePlatform() || new URL(API_BASE, window.location.href).origin !== window.location.origin;
if (!USE_BEARER) localStorage.removeItem(TOKEN_KEY);

export const authToken = {
  get: () => (USE_BEARER ? localStorage.getItem(TOKEN_KEY) : null),
  set: (token) => { if (USE_BEARER && token) localStorage.setItem(TOKEN_KEY, token); },
  clear: () => localStorage.removeItem(TOKEN_KEY),
};

// URL for a stored file (/api/files/...); cookies cover the website, ?auth= covers the native shell.
export function fileUrl(path) {
  if (!path) return null;
  const token = authToken.get();
  return `${BACKEND_URL}${path}${token ? `?auth=${encodeURIComponent(token)}` : ""}`;
}

// withCredentials stays false: the ingress answers with a wildcard origin, which browsers reject with credentials.
const api = axios.create({ baseURL: API_BASE, withCredentials: false });

api.interceptors.request.use((config) => {
  const token = authToken.get();
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

const SESSION_ERRORS = ["Not authenticated", "Token expired"];
const NO_REFRESH = ["/auth/login", "/auth/refresh", "/auth/logout"];
let refreshing = null;

// When the short-lived session runs out, renew it once from the refresh cookie and retry the request.
api.interceptors.response.use(undefined, async (error) => {
  const { config, response } = error;
  const expired = response?.status === 401 && SESSION_ERRORS.includes(response.data?.detail);
  if (!expired || !config || config._retried || NO_REFRESH.includes(config.url)) throw error;
  config._retried = true;
  refreshing = refreshing || api.post("/auth/refresh").finally(() => { refreshing = null; });
  try {
    const { data } = await refreshing;
    authToken.set(data?.access_token);
  } catch {
    throw error;
  }
  return api(config);
});

export function formatApiError(err) {
  const detail = err?.response?.data?.detail;
  if (detail == null) return err?.message || "Something went wrong";
  if (typeof detail === "string") return detail;
  if (Array.isArray(detail))
    return detail.map((e) => (e && typeof e.msg === "string" ? e.msg : JSON.stringify(e))).join(" ");
  if (detail && typeof detail.msg === "string") return detail.msg;
  return String(detail);
}

// Runs an API call, toasts the outcome, and resolves to the result (or null when it failed).
export async function attempt(call, successMessage) {
  try {
    const result = await call();
    if (successMessage) toast.success(successMessage);
    return result ?? true;
  } catch (e) {
    toast.error(formatApiError(e));
    return null;
  }
}

export const multipart = { headers: { "Content-Type": "multipart/form-data" } };

export default api;
