const { pool } = require('../config/db');

class Goods {
    static async create(data) {
        const { rows } = await pool.query(`
            INSERT INTO goods (
                hs_code, name, description, category, subcategory,
                unit_of_measure, weight_per_unit_kg, country_of_origin,
                base_duty_rate, vat_rate, is_hazardous, is_restricted,
                requires_license, risk_rating, status
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
            RETURNING *
        `, [
            data.hs_code, data.name, data.description, data.category, data.subcategory,
            data.unit_of_measure, data.weight_per_unit_kg, data.country_of_origin,
            data.base_duty_rate || 0, data.vat_rate || 0,
            data.is_hazardous || false, data.is_restricted || false,
            data.requires_license || false, data.risk_rating || 'LOW',
            data.status || 'ACTIVE'
        ]);
        return rows[0];
    }

    static async findAll(page = 1, limit = 20) {
        const offset = (page - 1) * limit;
        const { rows } = await pool.query(`
            SELECT * FROM goods 
            WHERE is_deleted = false 
            ORDER BY created_at DESC 
            LIMIT $1 OFFSET $2
        `, [limit, offset]);
        
        const countResult = await pool.query('SELECT COUNT(*) FROM goods WHERE is_deleted = false');
        const total = parseInt(countResult.rows[0].count);
        
        return {
            data: rows,
            pagination: { page, limit, total, totalPages: Math.ceil(total / limit) }
        };
    }

    static async findById(id) {
        const { rows } = await pool.query(
            'SELECT * FROM goods WHERE goods_id = $1 AND is_deleted = false',
            [id]
        );
        return rows[0];
    }

    static async update(id, data) {
        const { rows } = await pool.query(`
            UPDATE goods 
            SET name = $1, description = $2, category = $3, 
                unit_of_measure = $4, country_of_origin = $5, base_duty_rate = $6,
                updated_at = NOW()
            WHERE goods_id = $7 
            RETURNING *
        `, [data.name, data.description, data.category, data.unit_of_measure, 
            data.country_of_origin, data.base_duty_rate, id]);
        return rows[0];
    }

    static async delete(id) {
        const { rows } = await pool.query(`
            UPDATE goods 
            SET is_deleted = true, deleted_at = NOW() 
            WHERE goods_id = $1 
            RETURNING goods_id
        `, [id]);
        return rows[0];
    }
}

module.exports = Goods;
