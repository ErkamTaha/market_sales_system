# test_database.py
import os
import sys
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# Database bağlantı testi
def test_database_connection():
    print("🔍 Database bağlantısını test ediyorum...")
    
    # .env dosyasından DATABASE_URL'yi okuma
    try:
        from dotenv import load_dotenv
        load_dotenv()
        DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://market_user:market_password_2024@localhost:5432/market_db")
    except:
        DATABASE_URL = "postgresql://market_user:market_password_2024@localhost:5432/market_db"
    
    print(f"📡 Bağlantı URL'si: {DATABASE_URL}")
    
    try:
        # Engine oluştur
        engine = create_engine(DATABASE_URL)
        
        # Bağlantıyı test et
        with engine.connect() as connection:
            result = connection.execute(text("SELECT version();"))
            version = result.fetchone()[0]
            print(f"✅ PostgreSQL bağlantısı başarılı!")
            print(f"📊 PostgreSQL versiyonu: {version}")
            
            # Tabloları kontrol et
            result = connection.execute(text("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public'
            """))
            tables = [row[0] for row in result.fetchall()]
            
            if tables:
                print(f"📋 Bulunan tablolar: {', '.join(tables)}")
                
                # Products tablosu var mı kontrol et
                if 'products' in tables:
                    result = connection.execute(text("SELECT COUNT(*) FROM products"))
                    count = result.fetchone()[0]
                    print(f"📦 Products tablosunda {count} kayıt var")
                    
                    # İlk 3 ürünü göster
                    if count > 0:
                        result = connection.execute(text("SELECT id, name, price FROM products LIMIT 3"))
                        products = result.fetchall()
                        print("🛍️  Örnek ürünler:")
                        for product in products:
                            print(f"   - ID: {product[0]}, İsim: {product[1]}, Fiyat: {product[2]}")
                else:
                    print("⚠️  Products tablosu bulunamadı!")
                    return False
            else:
                print("⚠️  Hiç tablo bulunamadı!")
                return False
                
        return True
        
    except Exception as e:
        print(f"❌ Database bağlantı hatası: {e}")
        print("\n🔧 Çözüm önerileri:")
        print("1. PostgreSQL servisinin çalıştığından emin olun")
        print("2. Kullanıcı adı ve şifrenizi kontrol edin")
        print("3. Database'in oluşturulduğundan emin olun")
        print("4. .env dosyasındaki DATABASE_URL'yi kontrol edin")
        return False

def test_models_import():
    print("\n🔍 Models dosyasını test ediyorum...")
    try:
        import models
        print("✅ Models başarıyla import edildi")
        
        # Model sınıflarını kontrol et
        if hasattr(models, 'Product'):
            print("✅ Product model'i bulundu")
        else:
            print("❌ Product model'i bulunamadı")
            return False
            
        if hasattr(models, 'Sale'):
            print("✅ Sale model'i bulundu")
        else:
            print("❌ Sale model'i bulunamadı")
            return False
            
        return True
    except Exception as e:
        print(f"❌ Models import hatası: {e}")
        return False

def test_schemas_import():
    print("\n🔍 Schemas dosyasını test ediyorum...")
    try:
        import schemas
        print("✅ Schemas başarıyla import edildi")
        
        # Schema sınıflarını kontrol et
        if hasattr(schemas, 'ProductCreate'):
            print("✅ ProductCreate schema'sı bulundu")
        else:
            print("❌ ProductCreate schema'sı bulunamadı")
            return False
            
        return True
    except Exception as e:
        print(f"❌ Schemas import hatası: {e}")
        return False

def create_sample_product():
    print("\n🔍 Örnek ürün oluşturmayı test ediyorum...")
    try:
        import models, database
        from sqlalchemy.orm import sessionmaker
        
        # Session oluştur
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=database.engine)
        db = SessionLocal()
        
        # Örnek ürün oluştur
        test_product = models.Product(
            name="Test Ürünü",
            barcode="TEST123456789",
            price=10.50,
            current_stock=100,
            unit="adet",
            category="Test"
        )
        
        # Veritabanına ekle
        db.add(test_product)
        db.commit()
        db.refresh(test_product)
        
        print(f"✅ Test ürünü oluşturuldu: ID {test_product.id}")
        
        # Temizlik
        db.delete(test_product)
        db.commit()
        db.close()
        
        print("✅ Test ürünü temizlendi")
        return True
        
    except Exception as e:
        print(f"❌ Ürün oluşturma hatası: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Market Sistemi Database Testi Başlıyor...\n")
    
    # Testleri sırayla çalıştır
    tests = [
        ("Database Bağlantısı", test_database_connection),
        ("Models Import", test_models_import),
        ("Schemas Import", test_schemas_import),
        ("Örnek Ürün Oluşturma", create_sample_product)
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"\n{'='*50}")
        print(f"TEST: {test_name}")
        print('='*50)
        
        if test_func():
            passed += 1
            print(f"✅ {test_name} BAŞARILI")
        else:
            print(f"❌ {test_name} BAŞARISIZ")
    
    print(f"\n{'='*50}")
    print(f"SONUÇ: {passed}/{total} test başarılı")
    print('='*50)
    
    if passed == total:
        print("🎉 Tüm testler başarılı! Backend çalışmaya hazır.")
    else:
        print("⚠️  Bazı testler başarısız. Lütfen hataları düzeltin.")