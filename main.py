from fastapi import FastAPI, Depends, HTTPException, status, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from datetime import datetime, date, timedelta
from typing import List, Optional
import models, schemas, database
from database import engine, get_db
import logging

# Logging ayarları
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Veritabanı tablolarını oluştur
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Market Satış Sistemi", version="1.0.0")

# CORS middleware - Vue.js frontend için
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Geçici olarak tümüne açık
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Middleware - request logging
@app.middleware("http")
async def log_requests(request, call_next):
    logger.info(f"Request: {request.method} {request.url}")
    try:
        response = await call_next(request)
        logger.info(f"Response: {response.status_code}")
        return response
    except Exception as e:
        logger.error(f"Request failed: {e}")
        raise

# ÜRÜN YÖNETİMİ
@app.post("/api/products/", response_model=schemas.Product)
def create_product(product: schemas.ProductCreate, db: Session = Depends(get_db)):
    """Yeni ürün ekle"""
    try:
        logger.info(f"Creating product: {product.model_dump()}")
        db_product = models.Product(**product.model_dump())
        db.add(db_product)
        db.commit()
        db.refresh(db_product)
        logger.info(f"Product created with ID: {db_product.id}")
        return db_product
    except Exception as e:
        logger.error(f"Error creating product: {e}")
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Ürün oluşturulurken hata: {str(e)}")

@app.get("/api/products/", response_model=List[schemas.Product])
def get_products(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Tüm ürünleri listele"""
    try:
        logger.info(f"Getting products with skip={skip}, limit={limit}")
        products = db.query(models.Product).offset(skip).limit(limit).all()
        logger.info(f"Found {len(products)} products")
        return products
    except Exception as e:
        logger.error(f"Error getting products: {e}")
        raise HTTPException(status_code=500, detail=f"Ürünler alınırken hata: {str(e)}")

@app.get("/api/products/{product_id}", response_model=schemas.Product)
def get_product(product_id: int, db: Session = Depends(get_db)):
    """ID ile ürün getir"""
    try:
        logger.info(f"Getting product with ID: {product_id}")
        product = db.query(models.Product).filter(models.Product.id == product_id).first()
        if not product:
            logger.warning(f"Product not found: {product_id}")
            raise HTTPException(status_code=404, detail="Ürün bulunamadı")
        return product
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting product {product_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Ürün alınırken hata: {str(e)}")

@app.get("/api/products/barcode/{barcode}", response_model=schemas.Product)
def get_product_by_barcode(barcode: str, db: Session = Depends(get_db)):
    """Barkod ile ürün getir"""
    try:
        logger.info(f"Getting product with barcode: {barcode}")
        product = db.query(models.Product).filter(models.Product.barcode == barcode).first()
        if not product:
            logger.warning(f"Product not found with barcode: {barcode}")
            raise HTTPException(status_code=404, detail=f"Barkod '{barcode}' ile ürün bulunamadı")
        logger.info(f"Found product: {product.name}")
        return product
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting product by barcode {barcode}: {e}")
        raise HTTPException(status_code=500, detail=f"Barkod ile ürün aranırken hata: {str(e)}")

@app.put("/api/products/{product_id}", response_model=schemas.Product)
def update_product(product_id: int, product_update: schemas.ProductUpdate, db: Session = Depends(get_db)):
    """Ürün güncelle"""
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Ürün bulunamadı")
    
    for key, value in product_update.dict(exclude_unset=True).items():
        setattr(product, key, value)
    
    db.commit()
    db.refresh(product)
    return product

@app.delete("/api/products/{product_id}")
def delete_product(product_id: int, db: Session = Depends(get_db)):
    """Ürün sil"""
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Ürün bulunamadı")
    
    db.delete(product)
    db.commit()
    return {"message": "Ürün başarıyla silindi"}

# STOK YÖNETİMİ
@app.get("/api/products/low-stock/")
def get_low_stock_products(db: Session = Depends(get_db)):
    """Kritik stok seviyesindeki ürünler"""
    products = db.query(models.Product).filter(
        models.Product.current_stock <= models.Product.critical_stock_level
    ).all()
    return products

@app.get("/api/products/expired/")
def get_expired_products(db: Session = Depends(get_db)):
    """Son kullanma tarihi geçmiş ürünler"""
    today = date.today()
    products = db.query(models.Product).filter(
        and_(
            models.Product.expiry_date.isnot(None),
            models.Product.expiry_date <= today
        )
    ).all()
    return products

@app.get("/api/products/expiring-soon/")
def get_expiring_products(days: int = 7, db: Session = Depends(get_db)):
    """Yakında son kullanma tarihi dolacak ürünler"""
    from datetime import timedelta
    future_date = date.today() + timedelta(days=days)
    products = db.query(models.Product).filter(
        and_(
            models.Product.expiry_date.isnot(None),
            models.Product.expiry_date <= future_date,
            models.Product.expiry_date > date.today()
        )
    ).all()
    return products

# SATIŞ İŞLEMLERİ
@app.post("/api/sales/", response_model=schemas.Sale)
def create_sale(sale: schemas.SaleCreate, db: Session = Depends(get_db)):
    """Yeni satış kaydı oluştur"""
    # Ürünlerin stok durumunu kontrol et
    for item in sale.items:
        product = db.query(models.Product).filter(models.Product.id == item.product_id).first()
        if not product:
            raise HTTPException(status_code=404, detail=f"Ürün bulunamadı: ID {item.product_id}")
        
        if product.current_stock < item.quantity:
            raise HTTPException(
                status_code=400, 
                detail=f"Yetersiz stok: {product.name} (Mevcut: {product.current_stock}, İstenilen: {item.quantity})"
            )
    
    # Satışı kaydet
    db_sale = models.Sale(
        total_amount=sale.total_amount,
        sale_date=datetime.utcnow()
    )
    db.add(db_sale)
    db.flush()  # ID'yi al
    
    # Satış kalemlerini kaydet ve stokları güncelle
    for item in sale.items:
        sale_item = models.SaleItem(
            sale_id=db_sale.id,
            product_id=item.product_id,
            quantity=item.quantity,
            unit_price=item.unit_price,
            total_price=item.total_price
        )
        db.add(sale_item)
        
        # Stok güncelle
        product = db.query(models.Product).filter(models.Product.id == item.product_id).first()
        product.current_stock -= item.quantity
    
    db.commit()
    db.refresh(db_sale)
    return db_sale

@app.get("/api/sales/", response_model=List[schemas.Sale])
def get_sales(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Satış geçmişi"""
    sales = db.query(models.Sale).offset(skip).limit(limit).all()
    return sales

@app.get("/api/sales/{sale_id}", response_model=schemas.Sale)
def get_sale(sale_id: int, db: Session = Depends(get_db)):
    """Satış detayı"""
    sale = db.query(models.Sale).filter(models.Sale.id == sale_id).first()
    if not sale:
        raise HTTPException(status_code=404, detail="Satış bulunamadı")
    return sale

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)