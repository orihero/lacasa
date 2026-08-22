/**
 * src/i18n — i18next, configured exactly as apps/web/src/i18n.js configures it:
 * the same detector, the same detection order, the same cookie cache, the same
 * `fallbackLng: "en"`, the same three eagerly-imported JSON files registered
 * under the default `translation` namespace.
 *
 * Keeping the detection order identical is not cosmetic. `querystring, cookie,
 * localStorage, navigator, htmlTag` with `caches: ["cookie"]` means an operator
 * who switches language in apps/web on the same host arrives here already in
 * that language — the three surfaces share the cookie, and a control room that
 * ignored it would be the odd one out.
 *
 * Imported for its side effect from main.tsx before anything renders.
 */
import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import LanguageDetector from "i18next-browser-languagedetector";

import en from "./locales/en.json";
import ru from "./locales/ru.json";
import uz from "./locales/uz.json";

void i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources: {
      en: {
        translation: en,
      },
      ru: {
        translation: ru,
      },
      uz: {
        translation: uz,
      },
    },
    fallbackLng: "en",
    interpolation: {
      // Off because React already escapes everything it renders; leaving it on
      // double-escapes any name with an apostrophe in it, and this surface is
      // full of interpolated people's names.
      escapeValue: false,
    },
    detection: {
      order: ["querystring", "cookie", "localStorage", "navigator", "htmlTag"],
      caches: ["cookie"],
    },
  });

export default i18n;
