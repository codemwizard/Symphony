import process from "node:process";
import { register } from "node:module";

if (!process.env.NODE_ENV) {
    process.env.NODE_ENV = 'test';
}
if (!process.env.DB_HOST) {
    process.env.DB_HOST = 'localhost';
}
if (!process.env.DB_PORT) {
    process.env.DB_PORT = '5432';
}
if (!process.env.DB_USER) {
    process.env.DB_USER = process.env.CI ? 'symphony' : 'test_user';
}
if (!process.env.DB_PASSWORD) {
    process.env.DB_PASSWORD = process.env.CI ? 'symphony' : 'test_password';
}
if (!process.env.DB_NAME) {
    process.env.DB_NAME = process.env.CI ? 'symphony' : 'test_db';
}

register("ts-node/esm", import.meta.url);
