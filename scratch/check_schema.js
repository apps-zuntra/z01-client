const { Pool } = require('pg');
require('dotenv').config({ path: '../z01-backend/.env' });

async function checkSchema() {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
  });

  try {
    const users = await pool.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'users';
    `);
    console.log('USERS TABLE:');
    console.table(users.rows);

    const tables = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public';
    `);
    console.log('ALL TABLES:');
    console.table(tables.rows);

  } catch (err) {
    console.error(err);
  } finally {
    pool.end();
  }
}

checkSchema();
