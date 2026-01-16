# Tasks List: ESLint Error Remediation

1) Update `eslint.config.mjs` to apply `parserOptions.project` only to TS files.
2) Add `test-parity.ts` to `tsconfig.json` include list.
3) Replace `any` with `unknown`/typed mocks in tests and scripts.
4) Rename unused functions/params with `_` or remove unused imports.
5) Remove unused eslint-disable directives in scripts.
6) Re-run ESLint and confirm zero errors/warnings.

## Verification Runs

- Unit tests (node:test): `/home/mwiza/.nvm/versions/node/v20.19.6/bin/node --loader ts-node/esm --test tests/unit/*.spec.ts`
  - Result: all unit specs passed.
- ESLint (explicit node): `/home/mwiza/.nvm/versions/node/v20.19.6/bin/node ./node_modules/eslint/bin/eslint.js . --ignore-pattern "_Legacy_V1/**"`
  - Result: zero errors/warnings.
