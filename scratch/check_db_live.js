const { Pool } = require('pg');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.join(__dirname, 'z01-backend', '.env') });

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

async function checkData() {
  try {
    console.log('Connecting to database...');
    const tables = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
    `);
    console.log('Tables:', tables.rows.map(r => r.table_name).join(', '));

    const listings = await pool.query('SELECT * FROM vendor_listings LIMIT 5');
    console.log('\nListing Columns:', Object.keys(listings.rows[0] || {}));
    console.log('\nSample Listings:', JSON.stringify(listings.rows, null, 2));

    await pool.end();
  } catch (err) {
    console.error('Error:', err);
  }
}

checkData();
