import jwt from "jsonwebtoken";
import { config } from "./config.js";

export function signToken(payload, options = {}) {
  return jwt.sign(payload, config.JWT_SECRET, { expiresIn: config.JWT_EXPIRES_IN, ...options });
}

export function verifyToken(token) {
  return jwt.verify(token, config.JWT_SECRET);
}
