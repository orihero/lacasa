import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import LanguageDetector from "i18next-browser-languagedetector";

import en from "./locales/en.json";
import ru from "./locales/ru.json";
import uz from "./locales/uz.json";

i18n
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
    fallbackLng: "uz",
    interpolation: {
      escapeValue: false,
    },
    detection: {
      order: ["querystring", "cookie", "localStorage", "navigator", "htmlTag"],
      caches: ["cookie"],
    },
  });

export default i18n;
