# schemas.py - Pydantic v2 uyumlu
from pydantic import BaseModel, ConfigDict
from typing import List, Optional
from datetime import datetime, date

class ProductBase(BaseModel):
    name: str
    barcode: Optional[str] = None
    price: float
    current_stock: float = 0
    critical_stock_level: float = 10
    unit: str = "adet"
    category: Optional[str] = None
    description: Optional[str] = None
    expiry_date: Optional[date] = None
    is_active: bool = True
    is_barcode_easy: bool = True

class ProductCreate(ProductBase):
    pass

class ProductUpdate(BaseModel):
    name: Optional[str] = None
    barcode: Optional[str] = None
    price: Optional[float] = None
    current_stock: Optional[float] = None
    critical_stock_level: Optional[float] = None
    unit: Optional[str] = None
    category: Optional[str] = None
    description: Optional[str] = None
    expiry_date: Optional[date] = None
    is_active: Optional[bool] = None
    is_barcode_easy: Optional[bool] = None

class Product(ProductBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    created_at: datetime

class SaleItemBase(BaseModel):
    product_id: int
    quantity: float
    unit_price: float
    total_price: float

class SaleItemCreate(SaleItemBase):
    pass

class SaleItem(SaleItemBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    sale_id: int
    product: Optional[Product] = None

class SaleBase(BaseModel):
    total_amount: float

class SaleCreate(SaleBase):
    items: List[SaleItemCreate]

class Sale(SaleBase):
    model_config = ConfigDict(from_attributes=True)
    
    id: int
    sale_date: datetime
    items: List[SaleItem] = []