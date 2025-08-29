\c market_db;

-- Tablo oluşturma script'leri (SQLAlchemy otomatik oluşturacak ama manuel için)

-- Ürünler tablosu
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    barcode VARCHAR(100) UNIQUE,
    price DECIMAL(10, 2) NOT NULL,
    current_stock DECIMAL(10, 2) DEFAULT 0,
    critical_stock_level DECIMAL(10, 2) DEFAULT 10,
    unit VARCHAR(50) DEFAULT 'adet',
    category VARCHAR(100),
    description TEXT,
    expiry_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Satışlar tablosu
CREATE TABLE IF NOT EXISTS sales (
    id SERIAL PRIMARY KEY,
    total_amount DECIMAL(10, 2) NOT NULL,
    sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Satış kalemleri tablosu
CREATE TABLE IF NOT EXISTS sale_items (
    id SERIAL PRIMARY KEY,
    sale_id INTEGER REFERENCES sales(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id) ON DELETE RESTRICT,
    quantity DECIMAL(10, 2) NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL
);

-- İndeksler
CREATE INDEX idx_products_barcode ON products(barcode) WHERE barcode IS NOT NULL;
CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_category ON products(category) WHERE category IS NOT NULL;
CREATE INDEX idx_products_expiry ON products(expiry_date) WHERE expiry_date IS NOT NULL;
CREATE INDEX idx_sales_date ON sales(sale_date);
CREATE INDEX idx_sale_items_sale_id ON sale_items(sale_id);
CREATE INDEX idx_sale_items_product_id ON sale_items(product_id);

-- Örnek veriler
INSERT INTO products (name, barcode, price, current_stock, critical_stock_level, unit, category, description) VALUES
('Ekmek', '1234567890001', 3.50, 100, 20, 'adet', 'Unlu Mamuller', 'Günlük taze ekmek'),
('Süt 1Lt', '1234567890002', 8.75, 50, 10, 'adet', 'Süt Ürünleri', 'Tam yağlı süt'),
('Domates', '1234567890003', 12.50, 25.5, 5, 'kg', 'Sebze', 'Taze domates'),
('Peynir Beyaz', '1234567890004', 45.00, 15, 3, 'kg', 'Süt Ürünleri', 'Tam yağlı beyaz peynir'),
('Yumurta', '1234567890005', 25.00, 30, 10, 'adet', 'Kümes Ürünleri', '10\''lu yumurta'),
('Elma', '1234567890006', 15.00, 20.3, 5, 'kg', 'Meyve', 'Starking elma'),
('Çay', '1234567890007', 22.50, 40, 8, 'adet', 'İçecek', 'Bergamot çayı 500gr'),
('Şeker', '1234567890008', 18.00, 25, 5, 'kg', 'Temel Gıda', 'Kristal şeker'),
('Makarna', '1234567890009', 6.75, 60, 15, 'adet', 'Tahıl Ürünleri', 'Spagetti makarna 500gr'),
('Zeytin Yağı', '1234567890010', 85.00, 12, 3, 'adet', 'Yağ', 'Sızma zeytinyağı 1Lt');

-- Son kullanma tarihi olan ürünler için güncelleme
UPDATE products SET expiry_date = CURRENT_DATE + INTERVAL '30 days' WHERE name IN ('Süt 1Lt', 'Peynir Beyaz', 'Yumurta');
UPDATE products SET expiry_date = CURRENT_DATE + INTERVAL '7 days' WHERE name = 'Ekmek';
UPDATE products SET expiry_date = CURRENT_DATE + INTERVAL '3 days' WHERE name = 'Domates';
UPDATE products SET expiry_date = CURRENT_DATE + INTERVAL '365 days' WHERE name IN ('Çay', 'Şeker', 'Makarna', 'Zeytin Yağı');

-- Görünümler (Views)
-- Kritik stok seviyesindeki ürünler
CREATE OR REPLACE VIEW low_stock_view AS
SELECT * FROM products 
WHERE current_stock <= critical_stock_level AND is_active = TRUE;

-- Son kullanma tarihi yaklaşan ürünler
CREATE OR REPLACE VIEW expiring_products_view AS
SELECT * FROM products 
WHERE expiry_date IS NOT NULL 
AND expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days'
AND is_active = TRUE;

-- Günlük satış özeti
CREATE OR REPLACE VIEW daily_sales_summary AS
SELECT 
    DATE(sale_date) as sale_date,
    COUNT(*) as total_transactions,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_transaction_amount
FROM sales
GROUP BY DATE(sale_date)
ORDER BY DATE(sale_date) DESC;

-- En çok satan ürünler
CREATE OR REPLACE VIEW top_selling_products AS
SELECT 
    p.id,
    p.name,
    p.category,
    SUM(si.quantity) as total_sold,
    SUM(si.total_price) as total_revenue
FROM products p
JOIN sale_items si ON p.id = si.product_id
JOIN sales s ON si.sale_id = s.id
WHERE s.sale_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.id, p.name, p.category
ORDER BY total_sold DESC;

-- Stored Procedures (Saklı Yordamlar)

-- Stok güncelleme prosedürü
CREATE OR REPLACE FUNCTION update_stock(
    product_id_param INTEGER,
    quantity_change DECIMAL(10,2),
    operation_type VARCHAR(10) -- 'add' veya 'subtract'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $
DECLARE
    current_stock_val DECIMAL(10,2);
BEGIN
    -- Mevcut stoku al
    SELECT current_stock INTO current_stock_val 
    FROM products 
    WHERE id = product_id_param;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ürün bulunamadı: %', product_id_param;
    END IF;
    
    -- İşlem tipine göre stok güncelle
    IF operation_type = 'add' THEN
        UPDATE products 
        SET current_stock = current_stock + quantity_change 
        WHERE id = product_id_param;
    ELSIF operation_type = 'subtract' THEN
        -- Stok kontrolü
        IF current_stock_val < quantity_change THEN
            RAISE EXCEPTION 'Yetersiz stok. Mevcut: %, İstenilen: %', current_stock_val, quantity_change;
        END IF;
        
        UPDATE products 
        SET current_stock = current_stock - quantity_change 
        WHERE id = product_id_param;
    ELSE
        RAISE EXCEPTION 'Geçersiz işlem tipi: %', operation_type;
    END IF;
    
    RETURN TRUE;
END;
$;

-- Toplu stok güncelleme prosedürü
CREATE OR REPLACE FUNCTION bulk_stock_update(
    products_json JSON
)
RETURNS TABLE(product_id INTEGER, success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $
DECLARE
    product_record RECORD;
BEGIN
    FOR product_record IN 
        SELECT * FROM json_to_recordset(products_json) 
        AS x(id INTEGER, quantity DECIMAL(10,2), operation VARCHAR(10))
    LOOP
        BEGIN
            PERFORM update_stock(product_record.id, product_record.quantity, product_record.operation);
            
            product_id := product_record.id;
            success := TRUE;
            message := 'Başarılı';
            RETURN NEXT;
            
        EXCEPTION WHEN OTHERS THEN
            product_id := product_record.id;
            success := FALSE;
            message := SQLERRM;
            RETURN NEXT;
        END;
    END LOOP;
END;
$;

-- Satış raporu prosedürü
CREATE OR REPLACE FUNCTION generate_sales_report(
    start_date DATE,
    end_date DATE
)
RETURNS TABLE(
    product_name VARCHAR,
    total_quantity DECIMAL,
    total_revenue DECIMAL,
    avg_price DECIMAL
)
LANGUAGE plpgsql
AS $
BEGIN
    RETURN QUERY
    SELECT 
        p.name,
        SUM(si.quantity)::DECIMAL as total_quantity,
        SUM(si.total_price)::DECIMAL as total_revenue,
        AVG(si.unit_price)::DECIMAL as avg_price
    FROM products p
    JOIN sale_items si ON p.id = si.product_id
    JOIN sales s ON si.sale_id = s.id
    WHERE DATE(s.sale_date) BETWEEN start_date AND end_date
    GROUP BY p.id, p.name
    ORDER BY total_revenue DESC;
END;
$;

-- Triggers (Tetikleyiciler)

-- Satış sonrası stok otomatik düşürme tetikleyicisi
CREATE OR REPLACE FUNCTION auto_decrease_stock()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $
BEGIN
    -- Yeni satış kalemi eklendiğinde stoku düşür
    UPDATE products 
    SET current_stock = current_stock - NEW.quantity
    WHERE id = NEW.product_id;
    
    -- Stok kontrolü
    IF (SELECT current_stock FROM products WHERE id = NEW.product_id) < 0 THEN
        RAISE EXCEPTION 'Stok negatif olamaz. Ürün ID: %', NEW.product_id;
    END IF;
    
    RETURN NEW;
END;
$;

-- Tetikleyiciyi aktifleştir
DROP TRIGGER IF EXISTS trigger_auto_decrease_stock ON sale_items;
CREATE TRIGGER trigger_auto_decrease_stock
    AFTER INSERT ON sale_items
    FOR EACH ROW
    EXECUTE FUNCTION auto_decrease_stock();

-- Satış iptal edildiğinde stoku geri yükleme tetikleyicisi
CREATE OR REPLACE FUNCTION auto_restore_stock()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $
BEGIN
    -- Satış kalemi silindiğinde stoku geri yükle
    UPDATE products 
    SET current_stock = current_stock + OLD.quantity
    WHERE id = OLD.product_id;
    
    RETURN OLD;
END;
$;

-- Tetikleyiciyi aktifleştir
DROP TRIGGER IF EXISTS trigger_auto_restore_stock ON sale_items;
CREATE TRIGGER trigger_auto_restore_stock
    AFTER DELETE ON sale_items
    FOR EACH ROW
    EXECUTE FUNCTION auto_restore_stock();

-- Son kullanma tarihi uyarıları için fonksiyon
CREATE OR REPLACE FUNCTION get_expiry_alerts(days_ahead INTEGER DEFAULT 7)
RETURNS TABLE(
    product_id INTEGER,
    product_name VARCHAR,
    expiry_date DATE,
    days_remaining INTEGER,
    alert_level VARCHAR
)
LANGUAGE plpgsql
AS $
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.name,
        p.expiry_date,
        (p.expiry_date - CURRENT_DATE)::INTEGER as days_remaining,
        CASE 
            WHEN p.expiry_date < CURRENT_DATE THEN 'EXPIRED'
            WHEN p.expiry_date <= CURRENT_DATE + 1 THEN 'CRITICAL'
            WHEN p.expiry_date <= CURRENT_DATE + 3 THEN 'WARNING'
            ELSE 'INFO'
        END as alert_level
    FROM products p
    WHERE p.expiry_date IS NOT NULL 
    AND p.expiry_date <= CURRENT_DATE + days_ahead
    AND p.is_active = TRUE
    ORDER BY p.expiry_date ASC;
END;
$;

-- Barkod doğrulama fonksiyonu
CREATE OR REPLACE FUNCTION validate_barcode(barcode_input VARCHAR)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $
BEGIN
    -- Basit barkod doğrulaması (sadece rakam ve minimum uzunluk kontrolü)
    IF barcode_input IS NULL OR LENGTH(barcode_input) < 8 THEN
        RETURN FALSE;
    END IF;
    
    IF barcode_input !~ '^[0-9]+' THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$;

-- Barkod benzersizlik kontrolü tetikleyicisi
CREATE OR REPLACE FUNCTION check_barcode_uniqueness()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $
BEGIN
    IF NEW.barcode IS NOT NULL THEN
        -- Barkod doğrulaması
        IF NOT validate_barcode(NEW.barcode) THEN
            RAISE EXCEPTION 'Geçersiz barkod formatı: %', NEW.barcode;
        END IF;
        
        -- Benzersizlik kontrolü (mevcut kaydın kendisi hariç)
        IF EXISTS (
            SELECT 1 FROM products 
            WHERE barcode = NEW.barcode 
            AND id != COALESCE(NEW.id, 0)
        ) THEN
            RAISE EXCEPTION 'Bu barkod zaten kullanılıyor: %', NEW.barcode;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$;

-- Tetikleyiciyi aktifleştir
DROP TRIGGER IF EXISTS trigger_check_barcode ON products;
CREATE TRIGGER trigger_check_barcode
    BEFORE INSERT OR UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION check_barcode_uniqueness();

-- Veritabanı yedekleme scripti
-- pg_dump kullanarak yedek alma komutu:
-- pg_dump -U market_user -h localhost -d market_db -f market_backup_$(date +%Y%m%d_%H%M%S).sql

-- Veritabanı geri yükleme scripti
-- psql -U market_user -h localhost -d market_db -f market_backup_YYYYMMDD_HHMMSS.sql

-- İstatistik görünümleri
CREATE OR REPLACE VIEW inventory_status AS
SELECT 
    COUNT(*) as total_products,
    SUM(CASE WHEN current_stock <= critical_stock_level THEN 1 ELSE 0 END) as low_stock_count,
    SUM(CASE WHEN expiry_date IS NOT NULL AND expiry_date <= CURRENT_DATE THEN 1 ELSE 0 END) as expired_count,
    SUM(CASE WHEN expiry_date IS NOT NULL AND expiry_date BETWEEN CURRENT_DATE AND CURRENT_DATE + 7 THEN 1 ELSE 0 END) as expiring_soon_count,
    SUM(current_stock * price) as total_inventory_value
FROM products
WHERE is_active = TRUE;

-- Haftalık satış trendi
CREATE OR REPLACE VIEW weekly_sales_trend AS
SELECT 
    DATE_TRUNC('week', sale_date)::DATE as week_start,
    COUNT(*) as transaction_count,
    SUM(total_amount) as total_sales,
    AVG(total_amount) as avg_transaction
FROM sales
WHERE sale_date >= CURRENT_DATE - INTERVAL '12 weeks'
GROUP BY DATE_TRUNC('week', sale_date)
ORDER BY week_start DESC;

-- Kategori bazında satış analizi
CREATE OR REPLACE VIEW category_sales_analysis AS
SELECT 
    COALESCE(p.category, 'Kategori Yok') as category,
    COUNT(DISTINCT si.sale_id) as transaction_count,
    SUM(si.quantity) as total_quantity,
    SUM(si.total_price) as total_revenue,
    AVG(si.unit_price) as avg_unit_price
FROM products p
JOIN sale_items si ON p.id = si.product_id
JOIN sales s ON si.sale_id = s.id
WHERE s.sale_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Kullanıcı yetkilerini tekrar düzenle
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO market_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO market_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO market_user;

-- Son olarak istatistikleri güncelle
ANALYZE;