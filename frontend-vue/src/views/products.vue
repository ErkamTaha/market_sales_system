<template>
  <v-container>
    <v-row class="mb-4 justify-space-between align-center">
      <v-col>
        <h2>Kategori Yönetimi</h2>
        <p class="text-grey">Toplam {{ $store.state.categories.length }} kategori</p>
      </v-col>
      <v-col cols="auto">
        <v-btn color="primary" variant="flat" @click="openAddCategoryDialog" size="large">
          <v-icon>mdi-plus</v-icon>
          Kategori Ekle
        </v-btn>
      </v-col>
    </v-row>
    <!-- Kategori Tablosu -->
    <v-card class="mb-4">
      <v-card-title class="d-flex align-center">
        Kategori Listesi
        <v-spacer></v-spacer>
        <v-chip color="primary">{{ $store.state.categories.length }} kategori</v-chip>
      </v-card-title>
      <v-data-table :headers="categoryHeaders" :items="$store.state.categories"
        :loading="$store.state.loadingCategories" :items-per-page="5" item-value="id">
        <template v-slot:[`item.name`]="{ item }">
          <div class="d-flex align-center">
            <v-icon class="mr-2">mdi-image-area</v-icon>
            <div class="font-weight-medium">{{ item.name }}</div>
          </div>
        </template>

        <template v-slot:[`item.is_active`]="{ item }">
          <v-switch v-model="item.is_active" color="success" hide-details
            @change="toggleCategoryActiveness(item)"></v-switch>
        </template>

        <template v-slot:[`item.actions`]="{ item }">
          <div class="d-flex">
            <v-tooltip text="Edit Category" location="top">
              <template v-slot:activator="{ props }">
                <v-btn size="small" v-bind="props" variant="flat" color="primary" @click="editCategory(item)"
                  class="mr-1 custom-btn">
                  <v-icon>mdi-pencil</v-icon>
                </v-btn>
              </template>
            </v-tooltip>
            <v-tooltip text="Delete Category" location="top">
              <template v-slot:activator="{ props }">
                <v-btn size="small" v-bind="props" variant="flat" color="error" @click="confirmDeleteCategory(item)"
                  class="custom-btn">
                  <v-icon>mdi-delete</v-icon>
                </v-btn>
              </template>
            </v-tooltip>
          </div>
        </template>

        <template v-slot:[`no-data`]>
          <div class="text-center py-8">
            <p class="text-grey mt-4">Hiç kategori bulunamadı</p>
            <v-btn color="primary" variant="flat" @click="openAddCategoryDialog">
              İlk Kategoriyi Ekle
            </v-btn>
          </div>
        </template>
      </v-data-table>
    </v-card>
    <!-- Başlık ve İstatistikler -->
    <v-row class="mb-4 justify-space-between align-center">
      <v-col>
        <h2>Ürün Yönetimi</h2>
        <p class="text-grey">Toplam {{ $store.state.products.length }} ürün</p>
      </v-col>
      <v-col cols="auto">
        <v-btn color="primary" variant="flat" @click="openAddProductDialog" size="large">
          <v-icon>mdi-plus</v-icon>
          Ürün Ekle
        </v-btn>
      </v-col>
    </v-row>

    <!-- Hızlı İstatistikler -->
    <v-row class="mb-4">
      <v-col cols="12" md="3">
        <v-card hover @click=filterFromCards(0) :class="getCardClass(0)" color="success" dark>
          <v-card-text class="text-center">
            <v-icon>mdi-package</v-icon>
            <h3>{{ $store.state.products.length }}</h3>
            <p>Toplam Ürün</p>
          </v-card-text>
        </v-card>
      </v-col>
      <v-col cols="12" md="3">
        <v-card hover @click=filterFromCards(1) :class="getCardClass(1)" color="warning" dark>
          <v-card-text class="text-center">
            <v-icon>mdi-alert</v-icon>
            <h3>{{ $store.state.lowStockProducts.length }}</h3>
            <p>Kritik Stok</p>
          </v-card-text>
        </v-card>
      </v-col>
      <v-col cols="12" md="3">
        <v-card hover @click=filterFromCards(2) :class="getCardClass(2)" color="error" dark>
          <v-card-text class="text-center">
            <v-icon>mdi-calendar-clock</v-icon>
            <h3>{{ $store.state.expiredProducts.length }}</h3>
            <p>Süresi Geçmiş</p>
          </v-card-text>
        </v-card>
      </v-col>
      <v-col cols="12" md="3">
        <v-card hover @click=filterFromCards(3) :class="getCardClass(3)" color="info" dark>
          <v-card-text class="text-center">
            <v-icon>mdi-alarm</v-icon>
            <h3>{{ $store.state.expiringProducts.length }}</h3>
            <p>Yakında Tarihi Geçecek</p>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>

    <!-- Arama ve Filtreler -->
    <v-card class="mb-4">
      <v-card-text>
        <v-row>
          <v-col cols="12" md="4">
            <v-text-field v-model="productSearch" label="Ürün ara (ad, barkod)" clearable hide-details>
              <template v-slot:prepend>
                <v-icon>mdi-magnify</v-icon>
              </template>
            </v-text-field>
          </v-col>
          <v-col cols="12" md="3">
            <v-select v-model="categoryFilter" :items="$store.getters.categories" label="Kategori Filtresi" clearable
              hide-details></v-select>
          </v-col>
          <v-col cols="12" md="3">
            <v-select v-model="stockFilter" :items="stockFilterOptions" label="Stok Durumu" clearable
              hide-details></v-select>
          </v-col>
          <v-col cols="12" md="2">
            <v-btn color="secondary" style="font-size: 0.75rem;" block @click="resetFilters">
              Filtreleri Temizle
            </v-btn>
          </v-col>
        </v-row>
      </v-card-text>
    </v-card>

    <!-- Ürün Tablosu -->
    <v-card>
      <v-card-title class="d-flex align-center">
        Ürün Listesi
        <v-spacer></v-spacer>
        <v-chip color="primary">{{ filteredProducts.length }} ürün</v-chip>
      </v-card-title>
      <v-data-table :headers="productHeaders" :items="filteredProducts" :loading="$store.state.loadingProducts"
        :items-per-page="10" item-value="id">
        <template v-slot:[`item.name`]="{ item }">
          <div class="d-flex align-center">
            <v-icon class="mr-2">mdi-image-area</v-icon>
            <div>
              <div class="font-weight-medium">{{ item.name }}</div>
              <div class="text-caption text-grey">{{ categoryNameById(item.category_id) ||
                'Kategorisiz'
              }}
              </div>
            </div>
          </div>
        </template>

        <template v-slot:[`item.price`]="{ item }">
          <span class="font-weight-bold">{{ item.price.toFixed(2) }} ₺</span>
        </template>

        <template v-slot:[`item.current_stock`]="{ item }">
          <v-chip :color="getStockColor(item)" size="small">
            {{ item.current_stock }} {{ item.unit }}
          </v-chip>
        </template>

        <template v-slot:[`item.expiry_date`]="{ item }">
          <v-chip v-if="item.expiry_date" :color="getExpiryColor(item.expiry_date)" size="small">
            {{ formatDate(item.expiry_date) }}
          </v-chip>
          <span v-else class="text-grey">-</span>
        </template>

        <template v-slot:[`item.is_active`]="{ item }">
          <v-switch v-model="item.is_active" color="success" hide-details
            @change="toggleProductActiveness(item)"></v-switch>
        </template>

        <template v-slot:[`item.fast_select`]="{ item }">
          <v-switch v-model="item.fast_select" color="success" hide-details
            @change="toggleProductBarcode(item)"></v-switch>
        </template>

        <template v-slot:[`item.actions`]="{ item }">
          <div class="d-flex">
            <v-tooltip text="Edit Product" location="top">
              <template v-slot:activator="{ props }">
                <v-btn v-bind="props" size="small" variant="flat" color="primary" @click="editProduct(item)"
                  class="mr-1 custom-btn">
                  <v-icon>mdi-pencil</v-icon>
                </v-btn>
              </template>
            </v-tooltip>

            <v-tooltip text="Update Stock" location="top">
              <template v-slot:activator="{ props }">
                <v-btn v-bind="props" size="small" variant="flat" color="success" @click="openStockUpdateDialog(item)"
                  class="mr-1 custom-btn">
                  <v-icon>mdi-box-shadow</v-icon>
                </v-btn>
              </template>
            </v-tooltip>

            <v-tooltip text="Delete Product" location="top">
              <template v-slot:activator="{ props }">
                <v-btn v-bind="props" size="small" variant="flat" color="error" @click="confirmDeleteProduct(item)"
                  class="custom-btn">
                  <v-icon>mdi-delete</v-icon>
                </v-btn>
              </template>
            </v-tooltip>
          </div>
        </template>

        <template v-slot:[`no-data`]>
          <div class="text-center py-8">
            <p class="text-grey mt-4">Hiç ürün bulunamadı</p>
            <v-btn color="primary" @click="openAddProductDialog">
              İlk ürünü ekle
            </v-btn>
          </div>
        </template>
      </v-data-table>
    </v-card>

    <!-- Kategori Ekleme/Düzenleme Modal -->
    <v-dialog v-model="showAddCategory" max-width="800">
      <v-card>
        <v-card-title class="bg-primary text-white">
          <v-row>
            <v-col>
              {{ editingCategory ? 'Kategori Düzenle' : 'Yeni Kategori Ekle' }}
            </v-col>
            <v-spacer></v-spacer>
            <v-tooltip text="Close" location="top">
              <template v-slot:activator="{ props }">
                <v-btn v-bind="props" size="medium" variant="text" @click="cancelCategoryEdit" class="mr-1 custom-btn">
                  <v-icon>mdi-close</v-icon>
                </v-btn>
              </template>
            </v-tooltip>
          </v-row>
        </v-card-title>
        <v-card-text class="pa-6">
          <v-form ref="categoryForm" v-model="formValid">
            <v-row>
              <v-col cols="12" md="6">
                <v-text-field v-model="categoryForm.name" label="Kategori Adı *"
                  :rules="[v => !!v || 'Kategori adı gerekli']" required></v-text-field>
              </v-col>
              <v-col cols="12">
                <v-textarea v-model="categoryForm.description" label="Açıklama" rows="2"></v-textarea>
              </v-col>
            </v-row>
          </v-form>
        </v-card-text>
        <v-card-actions class="pa-4">
          <v-spacer></v-spacer>
          <v-btn @click="cancelCategoryEdit">İptal</v-btn>
          <v-btn color="primary" variant="outlined" @click="saveCategory" :loading="savingCategory">
            {{ editingCategory ? 'Güncelle' : 'Kaydet' }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Ürün Ekleme/Düzenleme Modal -->
    <v-dialog v-model="showAddProduct" max-width="800">
      <v-card>
        <v-card-title class="bg-primary text-white">
          <v-row>
            <v-col>
              {{ editingProduct ? 'Ürün Düzenle' : 'Yeni Ürün Ekle' }}
            </v-col>
            <v-spacer></v-spacer>
            <v-tooltip text="Close" location="top">
              <template v-slot:activator="{ props }">
                <v-btn v-bind="props" size="medium" variant="text" @click="cancelProductEdit" class="mr-1 custom-btn">
                  <v-icon>mdi-close</v-icon>
                </v-btn>
              </template>
            </v-tooltip>
          </v-row>
        </v-card-title>
        <v-card-text class="pa-6">
          <v-form ref="productForm" v-model="formValid">
            <v-row>
              <v-col cols="12">
                <h4 class="mb-3">Temel Bilgiler</h4>
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field v-model="productForm.name" label="Ürün Adı *" :rules="[v => !!v || 'Ürün adı gerekli']"
                  required></v-text-field>
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field v-model="productForm.barcode" @input="handleBarcodeInput" type="tel"
                  label="Barkod"></v-text-field>
              </v-col>
              <v-col cols="12" md="6">
                <v-select v-model="productForm.category_id" :items="$store.getters.categories" label="Kategori"
                  clearable hide-details></v-select>
              </v-col>
              <v-col cols="12" md="6">
                <v-select v-model="productForm.unit" :items="unitOptions" label="Birim"></v-select>
              </v-col>
              <v-col cols="12">
                <v-textarea v-model="productForm.description" label="Açıklama" rows="2"></v-textarea>
              </v-col>
              <v-col cols="12">
                <h4 class="mb-3">Fiyat ve Stok Bilgileri</h4>
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field v-model="productForm.price" label="Fiyat (₺) *" type="number" step="0.01" min="0"
                  :rules="[v => !!v || 'Fiyat gerekli', v => v > 0 || 'Fiyat 0\'dan büyük olmalı']"
                  required></v-text-field>
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field v-model="productForm.current_stock" label="Mevcut Stok" type="number" step="0.1"
                  min="0"></v-text-field>
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field v-model="productForm.critical_stock_level" label="Kritik Stok Seviyesi" type="number"
                  step="0.1" min="0"></v-text-field>
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field v-model="productForm.expiry_date" label="Son Kullanma Tarihi" type="date"></v-text-field>
              </v-col>
              <v-col cols="12">
                <v-switch v-model="productForm.is_active" label="Ürün aktif" color="success" inset hide-details
                  class="mb-3"></v-switch>
                <v-switch v-model="productForm.fast_select" label="Hızlı Seçim" color="success" inset
                  hide-details></v-switch>
              </v-col>
            </v-row>
          </v-form>
        </v-card-text>
        <v-card-actions class="pa-4">
          <v-spacer></v-spacer>
          <v-btn @click="cancelProductEdit">İptal</v-btn>
          <v-btn color="primary" variant="outlined" @click="saveProduct" :loading="savingProduct">
            {{ editingProduct ? 'Güncelle' : 'Kaydet' }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Ürün Detay Component -->
    <product-detail-component v-model="showProductDetail" :product="selectedProduct">

    </product-detail-component>

    <!-- Stok Güncelleme Modal -->
    <v-dialog v-model="showStockUpdate" max-width="400">
      <v-card>
        <v-card-title class="bg-success text-white">
          <v-row>
            <v-col>
              Stok Güncelle
            </v-col>
            <v-spacer></v-spacer>
            <v-tooltip text="Close" location="top">
              <template v-slot:activator="{ props }">
                <v-btn v-bind="props" size="medium" variant="text" @click="showStockUpdate = false"
                  class="mr-1 custom-btn">
                  <v-icon>mdi-close</v-icon>
                </v-btn>
              </template>
            </v-tooltip>
          </v-row>
        </v-card-title>
        <v-card-text class="pa-6" v-if="selectedProductForStock">
          <div class="text-center mb-4">
            <h3>{{ selectedProductForStock.name }}</h3>
            <p class="text-grey">Mevcut: {{ selectedProductForStock.current_stock }} {{ selectedProductForStock.unit }}
            </p>
          </div>
          <v-radio-group v-model="stockUpdateType">
            <v-radio label="Stok Ekle" value="add" color="success"></v-radio>
            <v-radio label="Stok Çıkar" value="remove" color="warning"></v-radio>
            <v-radio label="Stok Ayarla" value="set" color="info"></v-radio>
          </v-radio-group>
          <v-text-field v-model="stockUpdateAmount" :label="getStockUpdateLabel()" type="number"
            :step="selectedProductForStock.unit === 'adet' ? 1 : 0.1" min="0"
            :suffix="selectedProductForStock.unit"></v-text-field>
          <v-alert v-if="stockUpdateAmount && stockUpdateType !== 'set'"
            :type="stockUpdateType === 'add' ? 'success' : 'warning'" variant="tonal">
            Yeni Stok: {{ calculateNewStock() }} {{ selectedProductForStock.unit }}
          </v-alert>
        </v-card-text>
        <v-card-actions class="pa-4">
          <v-spacer></v-spacer>
          <v-btn @click="showStockUpdate = false">İptal</v-btn>
          <v-btn color="success" variant="outlined" @click="updateStock" :loading="updatingStock"
            :disabled="!stockUpdateAmount">
            Güncelle
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Silme Onay Modal -->
    <v-dialog v-model="showDeleteConfirm" @afterLeave="clearDeleteData" max-width="400">
      <v-card>
        <v-card-title class="bg-error text-white">
          <v-row>
            <v-col>
              {{ productToDelete ? "Ürünü Sil" : "Kategoriyi Sil" }}
            </v-col>
            <v-spacer></v-spacer>
            <v-tooltip text="Close" location="top">
              <template v-slot:activator="{ props }">
                <v-btn v-bind="props" size="medium" variant="text" @click="showDeleteConfirm = false"
                  class="mr-1 custom-btn">
                  <v-icon>mdi-close</v-icon>
                </v-btn>
              </template>
            </v-tooltip>
          </v-row>
        </v-card-title>
        <v-card-text class="pa-6" v-if="productToDelete">
          <div class="text-center">
            <h3 class="mt-3">Bu ürünü silmek istediğinizden emin misiniz?</h3>
            <p class="text-grey mt-2">{{ productToDelete.name }}</p>
            <v-alert type="warning" variant="tonal" class="mt-4">
              Bu işlem geri alınamaz!
            </v-alert>
          </div>
        </v-card-text>
        <v-card-text class="pa-6" v-if="categoryToDelete">
          <div class="text-center">
            <h3 class="mt-3">Bu kategoriyi silmek istediğinizden emin misiniz?</h3>
            <p class="text-grey mt-2">{{ categoryToDelete.name }}</p>
            <v-alert type="warning" variant="tonal" class="mt-4">
              Bu işlem geri alınamaz!
            </v-alert>
          </div>
        </v-card-text>
        <v-card-actions class="pa-4">
          <v-spacer></v-spacer>
          <v-btn @click="showDeleteConfirm = false">İptal</v-btn>
          <v-btn color="error" variant="outlined" @click="deleteCategory" :loading="deletingCategory">
            Sil
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<style scoped>
.mark-icon {
  position: absolute;
  top: 4px;
  /* distance from top */
  left: 4px;
  /* distance from left */
  z-index: 10;
  /* above other content */
}

.card-selected {
  --text-color: white;
  --text-opacity: 1;
  --bg-opacity: 1;
}

.card-unselected {
  --text-color: black;
  --text-opacity: 0.8;
  --bg-opacity: 0.2;
}

/* Apply background opacity using filter or background-color with alpha */
.card-unselected::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(255, 255, 255, 0.8);
  /* White overlay to reduce card opacity */
  pointer-events: none;
  border-radius: inherit;
}

/* Text styling */
.v-card .v-card-text,
.v-card .v-card-text .v-icon,
.v-card .v-card-text h3,
.v-card .v-card-text p {
  color: var(--text-color) !important;
  opacity: var(--text-opacity) !important;
  transition: color 0.3s ease, opacity 0.3s ease;
  position: relative;
  z-index: 1;
}

.card-unselected:hover {
  opacity: 0.7 !important;
}
</style>

<script>

export default {
  name: 'ProductsComponent',

  data() {
    return {
      selectedCard: 0,
      // Arama ve filtreler
      productSearch: '',
      categoryFilter: null,
      stockFilter: '',

      // Modal durumları
      showAddProduct: false,
      showAddCategory: false,
      showProductDetail: false,
      showCategoryDetail: false,
      showStockUpdate: false,
      showDeleteConfirm: false,

      // Form durumları
      editingProduct: false,
      savingProduct: false,
      deletingProduct: false,
      editingCategory: false,
      savingCategory: false,
      deletingCategory: false,
      updatingStock: false,
      formValid: false,

      // Seçili öğeler
      selectedProduct: null,
      productToDelete: null,
      categoryToDelete: null,
      selectedProductForStock: null,

      // Stok güncelleme
      stockUpdateType: 'add',
      stockUpdateAmount: '',

      // Product Form verileri
      productForm: {
        name: '',
        barcode: '',
        price: 0,
        current_stock: 0,
        critical_stock_level: 10,
        unit: 'adet',
        category_id: null,
        description: '',
        expiry_date: null,
        is_active: true,
        fast_select: false
      },

      // Category Form verileri
      categoryForm: {
        name: '',
        description: ''
      },

      // Seçenekler
      unitOptions: [
        { title: 'Adet', value: 'adet' },
        { title: 'Kilogram', value: 'kg' },
        { title: 'Litre', value: 'lt' },
        { title: 'Gram', value: 'gr' },
        { title: 'Mililitre', value: 'ml' }
      ],

      stockFilterOptions: [
        { title: 'Tümü', value: '' },
        { title: 'Kritik Stok', value: 'critical' },
        { title: 'Stokta Var', value: 'available' },
        { title: 'Stokta Yok', value: 'out_of_stock' }
      ],

      // Tablo başlıkları
      productHeaders: [
        { title: 'ID', key: 'id', width: '80px' },
        { title: 'Ürün', key: 'name' },
        { title: 'Barkod', key: 'barcode' },
        { title: 'Fiyat', key: 'price' },
        { title: 'Stok', key: 'current_stock' },
        { title: 'Birim', key: 'unit' },
        { title: 'Son Kullanma Tarihi', key: 'expiry_date' },
        { title: 'Aktif', key: 'is_active' },
        { title: 'Hızlı Seçim', key: 'fast_select' },
        { title: 'İşlemler', key: 'actions', sortable: false }
      ],

      categoryHeaders: [
        { title: 'ID', key: 'id', width: '80px' },
        { title: 'Kategori', key: 'name' },
        { title: 'Açıklama', key: 'description' },
        { title: 'Aktif', key: 'is_active' },
        { title: 'İşlemler', key: 'actions', sortable: false }
      ]
    }
  },
  computed: {
    filteredProducts() {
      let filtered = this.$store.state.products;

      if (this.selectedCard) {
        switch (this.selectedCard) {
          case 0:
            filtered = this.$store.state.products;
            break;
          case 1:
            filtered = this.$store.state.lowStockProducts;
            break;
          case 2:
            filtered = this.$store.state.expiredProducts;
            break;
          case 3:
            filtered = this.$store.state.expiringProducts;
            break;
        }
      }

      // Arama filtresi
      if (this.productSearch) {
        const searchTerm = this.productSearch.toLowerCase();
        filtered = filtered.filter(product =>
          product.name.toLowerCase().includes(searchTerm) ||
          (product.barcode && product.barcode.toLowerCase().includes(searchTerm)) ||
          (product.category && product.category.toLowerCase().includes(searchTerm))
        );
      }

      // Kategori filtresi
      if (this.categoryFilter) {
        filtered = filtered.filter(product => product.category_id === this.categoryFilter);
      }

      // Stok filtresi
      if (this.stockFilter) {
        switch (this.stockFilter) {
          case 'critical':
            filtered = filtered.filter(product =>
              product.current_stock <= product.critical_stock_level
            );
            break;
          case 'available':
            filtered = filtered.filter(product => product.current_stock > 0);
            break;
          case 'out_of_stock':
            filtered = filtered.filter(product => product.current_stock <= 0);
            break;
        }
      }

      return filtered;
    }
  },

  async mounted() {
    // Ürünleri ve stok uyarılarını yükle
    if (this.$store.state.categories.length === 0) {
      await this.$store.dispatch('loadCategories');
    }
    if (this.$store.state.products.length === 0) {
      await this.$store.dispatch('loadProducts');
    }
    if (this.$store.state.lowStockProducts.length === 0) {
      await this.$store.dispatch('loadStockAlerts');
    }
  },

  methods: {
    clearDeleteData() {
      this.productToDelete = null;
      this.categoryToDelete = null;
    },
    categoryNameById(id) {
      const categories = this.$store.getters.categories;
      const title = categories.find(category => category.value === id)?.title || 'Not Found';
      return title;
    },
    handleBarcodeInput(event) {
      const value = event.target.value;
      if (value) {
        const numericValue = value.replace(/\D/g, '');
        this.productForm.barcode = numericValue.slice(0, 13);
      }
    },
    getCardClass(cardIndex) {
      return {
        'card-selected': this.selectedCard === cardIndex,
        'card-unselected': this.selectedCard !== null && this.selectedCard !== cardIndex
      };
    },
    filterFromCards(cardIndex) {
      this.selectedCard = cardIndex;
    },
    // Modal açma/kapama
    openAddProductDialog() {
      this.editingProduct = false;
      this.resetProductForm();
      this.showAddProduct = true;
    },

    openAddCategoryDialog() {
      this.editingCategory = false;
      this.resetProductForm();
      this.showAddCategory = true;
    },

    confirmDeleteProduct(product) {
      this.productToDelete = product;
      this.showDeleteConfirm = true;
    },

    confirmDeleteCategory(category) {
      this.categoryToDelete = category;
      this.showDeleteConfirm = true;
    },

    openStockUpdateDialog(product) {
      this.selectedProductForStock = product;
      this.stockUpdateType = 'add';
      this.stockUpdateAmount = '';
      this.showStockUpdate = true;
    },

    // Ürün işlemleri
    async saveProduct() {
      this.savingProduct = true;
      try {
        const productData = { ...this.productForm };
        if (productData.price) productData.price = parseFloat(productData.price);
        if (productData.current_stock) productData.current_stock = parseFloat(productData.current_stock);
        if (productData.critical_stock_level) productData.critical_stock_level = parseFloat(productData.critical_stock_level);

        if (this.editingProduct) {
          const updatedProduct = await this.$store.dispatch('apiCall', {
            url: `/api/products/${this.editingProduct.id}`,
            method: 'PUT',
            data: productData
          });
          this.$store.commit('UPDATE_PRODUCT', updatedProduct);
          this.$store.commit('SHOW_SNACKBAR', { text: 'Ürün başarıyla güncellendi', color: 'success' });
        } else {
          const newProduct = await this.$store.dispatch('apiCall', {
            url: '/api/products/',
            method: 'POST',
            data: productData
          });
          this.$store.commit('ADD_PRODUCT', newProduct);
          this.$store.commit('SHOW_SNACKBAR', { text: 'Ürün başarıyla eklendi', color: 'success' });
        }

        await this.$store.dispatch('loadStockAlerts');
        this.cancelProductEdit();

      } catch (error) {
        console.error('Ürün kaydedilirken hata:', error);
        this.$store.commit('SHOW_SNACKBAR', { text: 'Ürün kaydedilemedi', color: 'error' });
      } finally {
        this.savingProduct = false;
      }
    },

    editProduct(product) {
      this.editingProduct = product;
      this.productForm = { ...product };
      if (this.productForm.expiry_date) {
        this.productForm.expiry_date = this.productForm.expiry_date.split('T')[0];
      }
      this.showAddProduct = true;
      this.showProductDetail = false;
    },

    async deleteProduct() {
      if (!this.productToDelete) return;

      this.deletingProduct = true;
      try {
        await this.$store.dispatch('apiCall', {
          url: `/api/products/${this.productToDelete.id}`,
          method: 'DELETE'
        });

        this.$store.commit('DELETE_PRODUCT', this.productToDelete.id);
        this.$store.commit('SHOW_SNACKBAR', { text: 'Ürün başarıyla silindi', color: 'success' });
        this.showDeleteConfirm = false;
        this.productToDelete = null;
      } catch (error) {
        console.error('Ürün silinirken hata:', error);
        this.$store.commit('SHOW_SNACKBAR', { text: 'Ürün silinemedi', color: 'error' });
      } finally {
        this.deletingProduct = false;
      }
    },

    async toggleProductActiveness(product) {
      try {
        const updatedProduct = await this.$store.dispatch('apiCall', {
          url: `/api/products/${product.id}`,
          method: 'PUT',
          data: { is_active: product.is_active }
        });

        this.$store.commit('UPDATE_PRODUCT', updatedProduct);
        this.$store.commit('SHOW_SNACKBAR', {
          text: `${product.name} ${product.is_active ? 'aktif' : 'pasif'} edildi`,
          color: 'success'
        });
      } catch (error) {
        console.error('Ürün durumu güncellenirken hata:', error);
        product.is_active = !product.is_active; // Geri al
      }
    },

    async toggleCategoryActiveness(category) {
      try {
        const updatedCategory = await this.$store.dispatch('apiCall', {
          url: `/api/categories/${category.id}`,
          method: 'PUT',
          data: { is_active: category.is_active }
        });
        const productsToUpdate = await this.$store.dispatch('apiCall', {
          url: `/api/products/category_id/${category.id}`,
          method: 'GET'
        })
        for (const product of productsToUpdate) {
          const updatedProduct = await this.$store.dispatch('apiCall', {
            url: `/api/products/${product.id}`,
            method: 'PUT',
            data: { is_active: category.is_active }
          });
          this.$store.commit('UPDATE_PRODUCT', updatedProduct);
        }
        this.$store.commit('UPDATE_CATEGORY', updatedCategory);
        this.$store.commit('SHOW_SNACKBAR', {
          text: `${category.name} ${category.is_active ? 'aktif' : 'pasif'} edildi`,
          color: 'success'
        });
      } catch (error) {
        console.error('Kategori durumu güncellenirken hata:', error);
        category.is_active = !category.is_active; // Geri al
      }
    },

    async toggleProductBarcode(product) {
      try {
        const updatedProduct = await this.$store.dispatch('apiCall', {
          url: `/api/products/${product.id}`,
          method: 'PUT',
          data: { fast_select: product.fast_select }
        });

        this.$store.commit('UPDATE_PRODUCT', updatedProduct);
        this.$store.commit('SHOW_SNACKBAR', {
          text: `${product.name} ${product.fast_select ? 'hızlı seçime eklendi' : 'hızlı seçimden kaldırıldı'}`,
          color: 'success'
        });
      } catch (error) {
        console.error('Ürün durumu güncellenirken hata:', error);
        product.is_active = !product.is_active; // Geri al
      }
    },

    // Kategori işlemleri
    async saveCategory() {
      this.savingCategory = true;
      try {
        const categoryData = { ...this.categoryForm };

        if (this.editingCategory) {
          const updatedCategory = await this.$store.dispatch('apiCall', {
            url: `/api/products/${this.editingCategory.id}`,
            method: 'PUT',
            data: categoryData
          });
          this.$store.commit('UPDATE_CATEGORY', updatedCategory);
          this.$store.commit('SHOW_SNACKBAR', { text: 'Kategori başarıyla güncellendi', color: 'success' });
        } else {
          const newCategory = await this.$store.dispatch('apiCall', {
            url: '/api/categories/',
            method: 'POST',
            data: categoryData
          });
          this.$store.commit('ADD_CATEGORY', newCategory);
          this.$store.commit('SHOW_SNACKBAR', { text: 'Kategori başarıyla eklendi', color: 'success' });
        }

        this.cancelCategoryEdit();

      } catch (error) {
        console.error('Kategori kaydedilirken hata:', error);
        this.$store.commit('SHOW_SNACKBAR', { text: 'Kategori kaydedilemedi', color: 'error' });
      } finally {
        this.savingCategory = false;
      }
    },

    editCategory(category) {
      this.editingCategory = category;
      this.categoryForm = { ...category };
      this.showAddCategory = true;
      this.showCategoryDetail = false;
    },

    async deleteCategory() {
      if (!this.categoryToDelete) return;

      this.deletingCategory = true;
      try {
        await this.$store.dispatch('apiCall', {
          url: `/api/categories/${this.categoryToDelete.id}`,
          method: 'DELETE'
        });

        this.$store.commit('DELETE_CATEGORY', this.categoryToDelete.id);
        await this.$store.dispatch('loadProducts');
        this.$store.commit('SHOW_SNACKBAR', { text: 'Kategori başarıyla silindi', color: 'success' });
        this.showDeleteConfirm = false;
        this.categoryToDelete = null;
      } catch (error) {
        console.error('Kategori silinirken hata:', error);
        this.$store.commit('SHOW_SNACKBAR', { text: 'Kategori silinemedi', color: 'error' });
      } finally {
        this.deletingCategory = false;
      }
    },

    // Stok güncelleme
    getStockUpdateLabel() {
      switch (this.stockUpdateType) {
        case 'add': return 'Eklenecek Miktar';
        case 'remove': return 'Çıkarılacak Miktar';
        case 'set': return 'Yeni Stok Miktarı';
        default: return 'Miktar';
      }
    },

    calculateNewStock() {
      if (!this.selectedProductForStock || !this.stockUpdateAmount) return 0;

      const current = this.selectedProductForStock.current_stock;
      const amount = parseFloat(this.stockUpdateAmount);

      switch (this.stockUpdateType) {
        case 'add': return current + amount;
        case 'remove': return Math.max(0, current - amount);
        case 'set': return amount;
        default: return current;
      }
    },

    async updateStock() {
      if (!this.selectedProductForStock || !this.stockUpdateAmount) return;

      this.updatingStock = true;
      try {
        const newStock = this.calculateNewStock();
        const updatedProduct = await this.$store.dispatch('apiCall', {
          url: `/api/products/${this.selectedProductForStock.id}`,
          method: 'PUT',
          data: { current_stock: newStock }
        });

        this.$store.commit('UPDATE_PRODUCT', updatedProduct);
        this.$store.commit('SHOW_SNACKBAR', { text: 'Stok başarıyla güncellendi', color: 'success' });
        await this.$store.dispatch('loadStockAlerts');
        this.showStockUpdate = false;
      } catch (error) {
        console.error('Stok güncellenirken hata:', error);
        this.$store.commit('SHOW_SNACKBAR', { text: 'Stok güncellenemedi', color: 'error' });
      } finally {
        this.updatingStock = false;
      }
    },

    // Form işlemleri
    resetProductForm() {
      this.productForm = {
        name: '',
        barcode: '',
        price: 0,
        current_stock: 0,
        critical_stock_level: 10,
        unit: 'adet',
        category: '',
        description: '',
        expiry_date: null,
        is_active: true,
      };
    },

    resetCategoryForm() {
      this.categoryForm = {
        name: '',
        description: ''
      };
    },

    cancelProductEdit() {
      this.showAddProduct = false;
      this.editingProduct = false;
      this.resetProductForm();
    },

    cancelCategoryEdit() {
      this.showAddCategory = false;
      this.editingCategory = false;
      this.resetCategoryForm();
    },

    resetFilters() {
      this.productSearch = '';
      this.categoryFilter = '';
      this.stockFilter = '';
      this.selectedCard = null;
    },

    // Yardımcı fonksiyonlar
    formatDate(dateString) {
      if (!dateString) return '';
      const date = new Date(dateString);
      return date.toLocaleDateString('tr-TR');
    },

    getExpiryColor(dateString) {
      if (!dateString) return 'grey';
      const date = new Date(dateString);
      const today = new Date();
      const diffDays = Math.ceil((date - today) / (1000 * 60 * 60 * 24));

      if (diffDays < 0) return 'error';
      if (diffDays <= 7) return 'blue';
      return 'success';
    },

    getStockColor(product) {
      if (product.current_stock <= 0) return 'error';
      if (product.current_stock <= product.critical_stock_level) return 'warning';
      return 'success';
    }
  }
}
</script>