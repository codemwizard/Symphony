import pg from 'pg';
import { pool } from './pool.js';

if (process.env.NODE_ENV !== 'test') {
    throw new Error('testOnly helpers must not be imported outside NODE_ENV=test');
}

export async function queryNoRole<T extends pg.QueryResultRow = pg.QueryResultRow>(
    text: string,
    params?: unknown[]
): Promise<pg.QueryResult<T>> {
    const client = await pool.connect();
    try {
        return await client.query<T>(text, params);
    } finally {
        client.release();
    }
}
