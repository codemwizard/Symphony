# NVM + Node Test Run Process (WSL2)

This document captures the exact process used to run tests in WSL2 when Node is installed via `nvm`.

## Preconditions
- WSL2 Ubuntu environment
- `nvm` installed under `~/.nvm`
- Node version `20.19.6` available via `nvm`

## One‑time or per‑shell setup
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
```

## Ensure the correct Node version
```bash
nvm install 20.19.6
nvm use 20.19.6
```

## Run the full test suite
```bash
npm test
```

## Notes
- If `npm` resolves to Windows (`/mnt/c/Program Files/nodejs/npm`), ensure `nvm` is sourced in the current shell so the Linux Node is used.
- This project’s `npm test` runs both `test:node` (Node test runner) and `test:jest`.
