import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

const STRICT_TS = {
    "no-console": "error",
    "no-eval": "error",
    "no-implied-eval": "error",
    "no-new-func": "error",

    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-unused-vars": [
        "error",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
    ],
};

export default tseslint.config(
    eslint.configs.recommended,

    // TypeScript configs
    ...tseslint.configs.recommended,

    // Type-aware parser config (TS files only)
    {
        files: ["**/*.ts", "**/*.tsx"],
        languageOptions: {
            parserOptions: {
                project: ["./tsconfig.json"],
                tsconfigRootDir: import.meta.dirname,
            },
        },
    },

    // Ignore build outputs + JS artifacts (TS-only governance)
    {
        ignores: [
            "node_modules/**",
            "dist/**",
            "coverage/**",
            "**/*.js",
            "**/*.cjs",
        ],
    },

    // ----------------- DEFAULT STRICT (all TS unless overridden) -----------------
    {
        files: ["**/*.ts", "**/*.tsx"],
        rules: { ...STRICT_TS },
    },

    // ----------------- TESTS: STRICT BUT CONSOLE OK -----------------
    {
        files: ["**/*.spec.ts", "**/*.test.ts", "**/__tests__/**/*.ts"],
        rules: {
            ...STRICT_TS,
            "no-console": "off",
        },
    },

    // ----------------- OPERATIONAL GLUE: CONSOLE OK, SECURITY STILL HARD -----------------
    {
        files: [
            ".ci/**/*.{ts,tsx}",
            "ci/**/*.{ts,tsx}",
            "scripts/**/*.{ts,tsx}",
            ".github/**/*.{ts,tsx,js}",
        ],
        rules: {
            ...STRICT_TS,
            "no-console": "off",
        },
    }
);
