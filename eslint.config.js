import js from "@eslint/js";
import { defineConfig, globalIgnores } from "eslint/config";
import reactHooks from "eslint-plugin-react-hooks";
import eslintConfigPrettier from "eslint-config-prettier";
import tseslint from "typescript-eslint";

export default defineConfig([
  globalIgnores([
    "node_modules/**",
    "public/**",
    "tmp/**",
    "log/**",
    "storage/**",
    "vendor/**",
    "coverage/**",
  ]),

  {
    files: ["app/javascript/**/*.{js,jsx,ts,tsx}"],

    extends: [
      js.configs.recommended,
      tseslint.configs.recommended,
    ],

    plugins: {
      "react-hooks": reactHooks,
    },

    rules: {
      "react-hooks/rules-of-hooks": "error",
      "react-hooks/exhaustive-deps": "warn",
    },
  },

  eslintConfigPrettier,
]);
