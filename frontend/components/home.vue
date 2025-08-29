<template>
  <v-container>
            <v-row>
                <v-col cols="12" md="8">
                    <!-- Barkod Okuma Kartı -->
                    <v-card class="mb-4">
                        <v-card-title>
                            <span class="icon-text">📷</span>
                            Ürün Okuma
                        </v-card-title>
                        <v-card-text>
                            <v-row>
                                <v-col cols="12" md="6">
                                    <v-text-field
                                        v-model="barcodeInput"
                                        label="Barkod"
                                        class="barcode-input"
                                        @keyup.enter="scanBarcode"
                                        autofocus
                                    >
                                        <template v-slot:prepend>
                                            <span>📊</span>
                                        </template>
                                    </v-text-field>
                                </v-col>
                                <v-col cols="12" md="6">
                                    <v-btn color="primary" @click="scanBarcode" :loading="scanning" class="mr-2">
                                        🔍 Ara
                                    </v-btn>
                                    <v-btn color="secondary" @click="showManualProduct = true">
                                        ➕ Manuel Ekle
                                    </v-btn>
                                </v-col>
                            </v-row>
                        </v-card-text>
                    </v-card>

                    <!-- Sepet Kartı -->
                    <v-card>
                        <v-card-title>
                            <span class="icon-text">🛒</span>
                            Sepet ({{ $store.state.saleItems.length }} ürün)
                        </v-card-title>
                        <v-card-text>
                            <div v-if="$store.state.saleItems.length === 0" class="text-center py-8">
                                <div style="font-size: 64px;">🛒</div>
                                <p class="text-grey mt-4">Sepet boş</p>
                            </div>
                            <v-list v-else>
                                <v-list-item
                                    v-for="(item, index) in $store.state.saleItems"
                                    :key="index"
                                    class="sale-item-card mb-2"
                                >
                                    <template v-slot:prepend>
                                        <v-avatar color="primary">📦</v-avatar>
                                    </template>
                                    <v-list-item-title>{{ item.name }}</v-list-item-title>
                                    <v-list-item-subtitle>
                                        {{ item.quantity }} {{ item.unit }} × {{ item.unit_price.toFixed(2) }} ₺
                                    </v-list-item-subtitle>
                                    <template v-slot:append>
                                        <div class="d-flex align-center">
                                            <v-btn size="small" @click="decreaseQuantity(index)" class="custom-btn">
                                                ➖
                                            </v-btn>
                                            <v-text-field
                                                :model-value="item.quantity"
                                                @update:model-value="updateQuantity(index, $event)"
                                                type="number"
                                                :step="getIncrementValue(item.unit)"
                                                :min="getIncrementValue(item.unit)"
                                                :max="item.max_stock"
                                                style="width: 100px;"
                                                density="compact"
                                                hide-details
                                                :suffix="item.unit"
                                            ></v-text-field>
                                            <v-btn size="small" @click="increaseQuantity(index)" class="custom-btn">
                                                ➕
                                            </v-btn>
                                            <div class="ml-4 font-weight-bold">
                                                {{ (item.quantity * item.unit_price).toFixed(2) }} ₺
                                            </div>
                                            <v-btn size="small" color="error" @click="removeItem(index)" class="ml-2 custom-btn">
                                                🗑️
                                            </v-btn>
                                        </div>
                                    </template>
                                </v-list-item>
                            </v-list>
                        </v-card-text>
                    </v-card>
                </v-col>

                <v-col cols="12" md="4">
                    <!-- Toplam Kartı -->
                    <v-card>
                        <v-card-title class="bg-primary text-white">
                            <span class="icon-text">🧮</span>
                            Toplam
                        </v-card-title>
                        <v-card-text class="text-center py-8">
                            <h1 class="text-h3 font-weight-bold">{{ $store.getters.totalCartAmount.toFixed(2) }} ₺</h1>
                            <v-divider class="my-4"></v-divider>
                            <v-btn 
                                color="success" 
                                size="large" 
                                block
                                :disabled="$store.state.saleItems.length === 0"
                                @click="completeSale"
                                :loading="completingSale"
                            >
                                ✅ Satışı Tamamla
                            </v-btn>
                            <v-btn 
                                color="warning" 
                                variant="outlined"
                                block
                                class="mt-2"
                                @click="clearCart"
                                v-if="$store.state.saleItems.length > 0"
                            >
                                🗑️ Sepeti Temizle
                            </v-btn>
                        </v-card-text>
                    </v-card>
                </v-col>
            </v-row>

            <!-- Manuel Ürün Ekleme Modal -->
            <v-dialog v-model="showManualProduct" max-width="600"
                    max-height="80vh"
                    scrollable>
                <v-card>
                    <v-card-title>Manuel Ürün Ekle</v-card-title>
                    <v-card-subtitle>
                        <v-select
                            v-model="selectedManualProduct"
                            :items="$store.state.products"
                            item-title="name"
                            item-value="id"
                            label="Ürün Seç"
                            return-object
                        ></v-select>
                        <v-text-field
                            v-model="manualQuantity"
                            label="Miktar"
                            type="number"
                            step="0.1"
                            v-if="selectedManualProduct"
                        ></v-text-field>
                    </v-card-subtitle>
                    <v-card-text class="pa-0">
                        <v-divider></v-divider>
                        <div class="pa-4">
                            <h4 class="mb-3">Hızlı Seçim</h4>
                        </div>
                        <div style="max-height: 45vh;">
                            <div class="px-4 pb-4">
                                <grid-component 
                                    :items="getHardBarcodeProducts()"
                                    isForSale=true
                                ></grid-component>
                            </div>
                        </div>
                    </v-card-text>
                    <v-card-actions class="pa-4 bg-grey-lighten-5">
                        <v-spacer></v-spacer>
                        <v-btn @click="showManualProduct = false" variant="outlined">İptal</v-btn>
                        <v-btn color="primary" @click="addManualProduct">Ekle</v-btn>
                    </v-card-actions>
                </v-card>
            </v-dialog>

            <!-- Satış Tamamlama Modal -->
            <v-dialog v-model="$store.state.showSaleComplete" max-width="400">
                <v-card>
                    <v-card-title class="text-success">
                        <span class="icon-text">✅</span>
                        Satış Tamamlandı!
                    </v-card-title>
                    <v-card-text class="text-center py-8">
                        <h2>{{ $store.state.lastSaleAmount.toFixed(2) }} ₺</h2>
                        <p>Satış başarıyla kaydedildi.</p>
                    </v-card-text>
                    <v-card-actions>
                        <v-spacer></v-spacer>
                        <v-btn color="primary" @click="$store.commit('HIDE_SALE_COMPLETE')">Tamam</v-btn>
                    </v-card-actions>
                </v-card>
            </v-dialog>
    </v-container>
</template>

<script>
export default {
  name: 'HomeComponent',
  
  data() {
    return {
      barcodeInput: '',
      scanning: false,
      completingSale: false,
      showManualProduct: false,
      selectedManualProduct: null,
      manualQuantity: 1
    }
  },

  async mounted() {
    await this.$store.dispatch('loadProducts');
    await this.$store.dispatch('loadStockAlerts');
  },

  methods: {
    async scanBarcode() {
      if (!this.barcodeInput.trim()) return;
      
      this.scanning = true;
      try {
        const product = await this.$store.dispatch('apiCall', {
          url: `/api/products/barcode/${this.barcodeInput}`
        });
        
        this.addProductToCart(product);
        this.barcodeInput = '';
        
      } catch (error) {
        this.$store.commit('SHOW_SNACKBAR', { 
          text: 'Ürün bulunamadı', 
          color: 'warning' 
        });
      } finally {
        this.scanning = false;
      }
    },

    addProductToCart(product, quantity = 1) {
      if (product.current_stock <= 0) {
        this.$store.commit('SHOW_SNACKBAR', { 
          text: `${product.name} stokta yok!`, 
          color: 'error' 
        });
        return;
      }
      
      if (quantity > product.current_stock) {
        this.$store.commit('SHOW_SNACKBAR', { 
          text: `Yetersiz stok! Maksimum: ${product.current_stock} ${product.unit}`, 
          color: 'warning' 
        });
        return;
      }

      this.$store.commit('ADD_TO_CART', { product, quantity });
      this.$store.commit('SHOW_SNACKBAR', { 
        text: `${product.name} sepete eklendi (${quantity} ${product.unit})`, 
        color: 'success' 
      });
    },

    addManualProduct() {
      if (!this.selectedManualProduct) return;
      
      this.addProductToCart(this.selectedManualProduct, parseFloat(this.manualQuantity) || 1);
      this.showManualProduct = false;
      this.selectedManualProduct = null;
      this.manualQuantity = 1;
    },

    updateQuantity(index, value) {
      const quantity = parseFloat(value);
      const item = this.$store.state.saleItems[index];
      const minQuantity = this.getIncrementValue(item.unit);
      
      if (quantity < minQuantity) {
        this.$store.commit('UPDATE_CART_ITEM', { index, quantity: minQuantity });
      } else if (quantity > item.max_stock) {
        this.$store.commit('UPDATE_CART_ITEM', { index, quantity: item.max_stock });
        this.$store.commit('SHOW_SNACKBAR', { 
          text: `Maksimum stok: ${item.max_stock} ${item.unit}`, 
          color: 'warning' 
        });
      } else {
        this.$store.commit('UPDATE_CART_ITEM', { index, quantity });
      }
    },

    increaseQuantity(index) {
      const item = this.$store.state.saleItems[index];
      const increment = this.getIncrementValue(item.unit);
      const newQuantity = parseFloat((item.quantity + increment).toFixed(2));
      this.updateQuantity(index, newQuantity);
    },

    decreaseQuantity(index) {
      const item = this.$store.state.saleItems[index];
      const increment = this.getIncrementValue(item.unit);
      if (item.quantity > increment) {
        const newQuantity = parseFloat((item.quantity - increment).toFixed(2));
        this.updateQuantity(index, newQuantity);
      }
    },

    getIncrementValue(unit) {
      switch(unit) {
        case 'kg':
        case 'lt':
        case 'gr':
        case 'ml':
          return 0.1;
        case 'adet':
        default:
          return 1;
      }
    },

    removeItem(index) {
      this.$store.commit('REMOVE_FROM_CART', index);
    },

    clearCart() {
      this.$store.commit('CLEAR_CART');
    },

    async completeSale() {
      if (this.$store.state.saleItems.length === 0) return;
      
      this.completingSale = true;
      try {
        await this.$store.dispatch('completeSale');
      } finally {
        this.completingSale = false;
      }
    }
  }
}
</script>

<style scoped>
/* Component'e özel stiller buraya */
</style>