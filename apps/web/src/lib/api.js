// Deprecated: the axios instance + localStorage token helpers now live in
// ./httpTransport.js, which also adapts them to @lacasa/api-client's
// Transport/TokenStorage contracts for ./apiClient.js (see agentsStore.js
// and useStatisticsStore.js for the first two callers migrated onto it).
// Re-exported here unchanged so every other call site — still on raw
// api.get/post/patch/delete — keeps working without touching each one.
export { api, getAuthToken, setAuthToken } from "./httpTransport";
