<template>
  <v-container>
    <!-- Başlık ve İstatistikler -->
    <v-row class="mb-4">
      <v-col>
        <h2>Ürün Yönetimi</h2>
        <p class="text-grey">Toplam {{ $store.state.products.length }} ürün</p>
      </v-col>
      <v-col cols="auto">
        <v-btn color="primary" @click="openAddProductDialog" size="large">
          <v-icon>mdi-plus</v-icon>
          Ürün Ekle
        </v-btn>
      </v-col>
    </v-row>

    <!-- Hızlı İstatistikler -->
    <v-row class="mb-4">
      <v-col cols="12" md="3">
        <v-card hover @click=filterFromCards(0) class="lighten-hover" color="success" dark>
          <v-card-text class="text-center">
            <v-icon>mdi-package</v-icon>
            <h3>{{ $store.state.products.length }}</h3>
            <p>Toplam Ürün</p>
          </v-card-text>
        </v-card>
      </v-col>
      <v-col cols="12" md="3">
        <v-card hover @click=filterFromCards(1) class="lighten-hover" color="warning" dark>
          <v-card-text class="text-center">
            <v-icon>mdi-alert</v-icon>
            <h3>{{ $store.state.lowStockProducts.length }}</h3>
            <p>Kritik Stok</p>
          </v-card-text>
        </v-card>
      </v-col>
      <v-col cols="12" md="3">
        <v-card hover @click=filterFromCards(2) class="lighten-hover" color="error" dark>
          <v-card-text class="text-center">
            <v-icon>mdi-calendar-clock</v-icon>
            <h3>{{ $store.state.expiredProducts.length }}</h3>
            <p>Süresi Geçmiş</p>
          </v-card-text>
        </v-card>
      </v-col>
      <v-col cols="12" md="3">
        <v-card hover @click=filterFromCards(3) class="lighten-hover" color="info" dark>
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
            <v-btn color="secondary" block @click="resetFilters">
              <v-icon>mdi-eraser</v-icon>
              Temizle
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
            <v-avatar size="40" class="mr-3">📦</v-avatar>
            <div>
              <div class="font-weight-medium">{{ item.name }}</div>
              <div class="text-caption text-grey">{{ item.category || 'Kategorisiz' }}</div>
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

        <template v-slot:[`item.is_barcode_easy`]="{ item }">
          <v-switch v-model="item.is_barcode_easy" color="success" hide-details
            @change="toggleProductBarcode(item)"></v-switch>
        </template>

        <template v-slot:[`item.actions`]="{ item }">
          <div class="d-flex">
            <v-btn size="small" color="info" @click="viewProduct(item)" class="mr-1 custom-btn">
              <v-icon>mdi-eye</v-icon>
            </v-btn>
            <v-btn size="small" color="primary" @click="editProduct(item)" class="mr-1 custom-btn">
              <v-icon>mdi-pencil</v-icon>
            </v-btn>
            <v-btn size="small" color="success" @click="openStockUpdateDialog(item)" class="mr-1 custom-btn">
              <v-icon>mdi-box-shadow</v-icon>
            </v-btn>
            <v-btn size="small" color="error" @click="confirmDeleteProduct(item)" class="custom-btn">
              <v-icon>mdi-delete</v-icon>
            </v-btn>
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

    <!-- Ürün Ekleme/Düzenleme Modal -->
    <v-dialog v-model="showAddProduct" max-width="800">
      <v-card>
        <v-card-title class="bg-primary text-white">
          {{ editingProduct ? 'Ürün Düzenle' : 'Yeni Ürün Ekle' }}
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
                <v-text-field v-model="productForm.barcode" label="Barkod"></v-text-field>
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field v-model="productForm.category" label="Kategori"></v-text-field>
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
                <v-switch v-model="productForm.is_barcode_easy" label="Barkod Kolaylığı" color="success" inset
                  hide-details></v-switch>
              </v-col>
            </v-row>
          </v-form>
        </v-card-text>
        <v-card-actions class="pa-4">
          <v-spacer></v-spacer>
          <v-btn @click="cancelProductEdit" variant="outlined">İptal</v-btn>
          <v-btn color="primary" @click="saveProduct" :loading="savingProduct">
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
          Stok Güncelle
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
          <v-text-field v-model="stockUpdateAmount" :label="getStockUpdateLabel()" type="number" step="0.1" min="0"
            :suffix="selectedProductForStock.unit"></v-text-field>
          <v-alert v-if="stockUpdateAmount && stockUpdateType !== 'set'"
            :type="stockUpdateType === 'add' ? 'success' : 'warning'" variant="tonal">
            Yeni Stok: {{ calculateNewStock() }} {{ selectedProductForStock.unit }}
          </v-alert>
        </v-card-text>
        <v-card-actions class="pa-4">
          <v-spacer></v-spacer>
          <v-btn @click="showStockUpdate = false" variant="outlined">İptal</v-btn>
          <v-btn color="success" @click="updateStock" :loading="updatingStock" :disabled="!stockUpdateAmount">
            Güncelle
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Silme Onay Modal -->
    <v-dialog v-model="showDeleteConfirm" max-width="400">
      <v-card>
        <v-card-title class="bg-error text-white">
          Ürün Sil
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
        <v-card-actions class="pa-4">
          <v-spacer></v-spacer>
          <v-btn @click="showDeleteConfirm = false" variant="outlined">İptal</v-btn>
          <v-btn color="error" @click="deleteProduct" :loading="deletingProduct">
            Sil
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-container>
</template>

<script>
export default {
  name: 'ProductsComponent',

  data() {
    return {
      // Arama ve filtreler
      productSearch: '',
      categoryFilter: '',
      stockFilter: '',
      cardFilter: 0,

      // Modal durumları
      showAddProduct: false,
      showProductDetail: false,
      showStockUpdate: false,
      showDeleteConfirm: false,

      // Form durumları
      editingProduct: false,
      savingProduct: false,
      deletingProduct: false,
      updatingStock: false,
      formValid: false,

      // Seçili öğeler
      selectedProduct: null,
      productToDelete: null,
      selectedProductForStock: null,

      // Stok güncelleme
      stockUpdateType: 'add',
      stockUpdateAmount: '',

      // Form verileri
      productForm: {
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
        is_barcode_easy: true
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
        { title: 'Son Kullanma', key: 'expiry_date' },
        { title: 'Aktif', key: 'is_active' },
        { title: 'Barkod Kolaylığı', key: 'is_barcode_easy' },
        { title: 'İşlemler', key: 'actions', sortable: false }
      ]
    }
  },
  computed: {
    filteredProducts() {
      let filtered = this.$store.state.products;

      if (this.cardFilter) {
        switch (this.cardFilter) {
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
        filtered = filtered.filter(product => product.category === this.categoryFilter);
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
    if (this.$store.state.products.length === 0) {
      await this.$store.dispatch('loadProducts');
    }
    if (this.$store.state.lowStockProducts.length === 0) {
      await this.$store.dispatch('loadStockAlerts');
    }
  },

  methods: {
    filterFromCards(filter) {
      this.cardFilter = filter;
    },
    // Modal açma/kapama
    openAddProductDialog() {
      this.editingProduct = false;
      this.resetProductForm();
      this.showAddProduct = true;
    },

    viewProduct(product) {
      this.selectedProduct = product;
      this.showProductDetail = true;
    },

    confirmDeleteProduct(product) {
      this.productToDelete = product;
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

    async toggleProductBarcode(product) {
      try {
        const updatedProduct = await this.$store.dispatch('apiCall', {
          url: `/api/products/${product.id}`,
          method: 'PUT',
          data: { is_barcode_easy: product.is_barcode_easy }
        });

        this.$store.commit('UPDATE_PRODUCT', updatedProduct);
        this.$store.commit('SHOW_SNACKBAR', {
          text: `${product.name} barkod okuma kolaylığı ${product.is_barcode_easy ? 'aktif' : 'pasif'} edildi`,
          color: 'success'
        });
      } catch (error) {
        console.error('Ürün durumu güncellenirken hata:', error);
        product.is_active = !product.is_active; // Geri al
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
        is_active: true
      };
    },

    cancelProductEdit() {
      this.showAddProduct = false;
      this.editingProduct = false;
      this.resetProductForm();
    },

    resetFilters() {
      this.productSearch = '';
      this.categoryFilter = '';
      this.stockFilter = '';
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

<style scoped>
.lighten-hover {
  transition: filter 0.2s ease-in-out;
}

.lighten-hover:hover {
  filter: brightness(1.1);
}
</style>