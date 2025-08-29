<template>
  <v-container>
    <v-row>
      <v-col cols="12" md="8">
        <!-- Barkod Okuma Kartı -->
        <v-card class="mb-4">
          <v-card-title>
            <v-icon>mdi-camera</v-icon>
            Ürün Okuma
          </v-card-title>
          <v-card-text>
            <v-row>
              <v-col cols="12" md="6">
                <v-text-field v-model="barcodeInput" label="Barkod" class="barcode-input" @keyup.enter="scanBarcode"
                  autofocus>
                </v-text-field>
              </v-col>
              <v-col cols="12" md="6">
                <v-btn color="primary" @click="scanBarcode" :loading="scanning" class="mr-2">
                  Barkodu Okut
                </v-btn>
              </v-col>
            </v-row>
          </v-card-text>
        </v-card>

        <v-card>
          <v-tabs v-model="tab" bg-color="primary">
            <v-tab value="1"><v-icon>mdi-cart</v-icon> Sepet 1</v-tab>
            <v-tab value="2"><v-icon>mdi-cart</v-icon> Sepet 2</v-tab>
            <v-tab value="3"><v-icon>mdi-cart</v-icon> Sepet 3</v-tab>
            <v-tab value="4"><v-icon>mdi-cart</v-icon> Sepet 4</v-tab>
            <v-tab value="5"><v-icon>mdi-cart</v-icon> Sepet 5</v-tab>
          </v-tabs>

          <v-card-text>
            <v-tabs-window v-model="tab">
              <v-tabs-window-item v-for="cartNumber in [1, 2, 3, 4, 5]" :key="cartNumber"
                :value="cartNumber.toString()">
                <v-btn color="secondary" @click="showManualProduct = true">
                  <v-icon>mdi-plus</v-icon> Manuel Ekle
                </v-btn>
                <div v-if="getCartItems(cartNumber).length === 0" class="text-center py-8">
                  <p class="text-grey mt-4">Sepet boş</p>
                </div>
                <v-list v-else>
                  <div class="mb-4">
                    {{ getCartItems(cartNumber).length }} ürün
                  </div>
                  <v-list-item v-for="(item, index) in getCartItems(cartNumber)" :key="`${cartNumber}-${index}`"
                    class="sale-item-card mb-2">
                    <template v-slot:prepend>
                      <v-avatar color="primary">📦</v-avatar>
                    </template>
                    <v-list-item-title>{{ item.name }}</v-list-item-title>
                    <v-list-item-subtitle>
                      {{ item.quantity }} {{ item.unit }} × {{ item.unit_price.toFixed(2) }} ₺
                    </v-list-item-subtitle>
                    <template v-slot:append>
                      <div class="d-flex align-center justify-space-between">
                        <div class="d-flex align-center quantity-controls" style="width: 120px;">
                          <v-btn size="small" icon @click="decreaseQuantity(item, cartNumber)" class="custom-btn">
                            <v-icon>mdi-minus</v-icon>
                          </v-btn>
                          <v-text-field :model-value="item.quantity"
                            @update:model-value="updateQuantity(item, $event, cartNumber)" type="number"
                            :step="getIncrementValue(item.unit)" :min="getIncrementValue(item.unit)"
                            :max="item.max_stock" style="width: 100px;" density="compact" hide-details variant="plain"
                            class="qty-input">
                          </v-text-field>
                          <v-btn size="small" icon @click="increaseQuantity(item, cartNumber)" class="custom-btn">
                            <v-icon>mdi-plus</v-icon>
                          </v-btn>
                        </div>
                        <div class="ml-4 font-weight-bold" style="width: 80px; text-align: right;">
                          {{ (item.quantity * item.unit_price).toFixed(2) }} ₺
                        </div>
                        <v-btn size="small" variant="outlined" color="error" icon class="ml-2 custom-btn"
                          @click="removeItem(item, cartNumber)">
                          <v-icon>mdi-delete</v-icon>
                        </v-btn>
                      </div>
                    </template>
                  </v-list-item>
                </v-list>
              </v-tabs-window-item>
            </v-tabs-window>
          </v-card-text>
        </v-card>
      </v-col>

      <v-col cols="12" md="4">
        <!-- Toplam Kartı -->
        <v-card>
          <v-card-title class="bg-primary text-white">
            Toplam
          </v-card-title>
          <v-card-text class="text-center py-8">
            <h1 class="text-h3 font-weight-bold">{{ currentCartTotal.toFixed(2) }} ₺</h1>
            <v-divider class="my-4"></v-divider>
            <v-btn color="success" size="large" block
              :disabled="$store.state.saleItems.filter(item => item.selectedCart === Number(this.tab)).length === 0"
              @click="completeSale" :loading="completingSale">
              Satışı Tamamla
            </v-btn>
            <v-btn color="error" variant="outlined" block class="mt-2" @click="clearCart"
              v-if="$store.state.saleItems.filter(item => item.selectedCart === Number(this.tab)).length > 0">
              Sepeti Temizle
            </v-btn>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>

    <!-- Manuel Ürün Ekleme Modal -->
    <v-dialog v-model="showManualProduct" max-width="600" max-height="80vh" scrollable>
      <v-card>
        <v-card-title>Manuel Ürün Ekle</v-card-title>
        <v-card-subtitle>
          <v-select v-model="selectedManualProduct" :items="$store.state.products" item-title="name" item-value="id"
            label="Ürün Seç" return-object></v-select>
          <v-text-field v-model="manualQuantity"
            :label="selectedManualProduct.unit.charAt(0).toUpperCase() + selectedManualProduct.unit.slice(1)"
            type="number" :step=getIncrementValue(selectedManualProduct.unit)
            v-if="selectedManualProduct"></v-text-field>
        </v-card-subtitle>
        <v-card-text class="pa-0">
          <v-divider></v-divider>
          <div class="pa-4">
            <h4>Hızlı Seçim</h4>
          </div>
          <div style="max-height: 45vh;">
            <div class="px-4 pb-4">
              <grid-component :items="getHardBarcodeProducts()" isForSale
                v-model:selection="selectedItems"></grid-component>
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

<style>
.custom-btn {
  min-width: 28px;
  /* smaller buttons */
  height: 28px;
  padding: 0;
  /* round buttons */
}

.quantity-controls {
  min-width: 120px;
  /* fixed space for buttons + text field */
  justify-content: center;
  /* center the quantity row */
}

.qty-input {
  max-width: 35px;
  margin: 0;
}

.qty-input input {
  text-align: center;
  padding: 0 !important;
  height: 28px;
  /* match button height */
  line-height: 28px;
  /* vertical centering */
}

.qty-input input::-webkit-outer-spin-button,
.qty-input input::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}
</style>

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
      selectedItems: [],
      manualQuantity: 1,
      tab: "1",
      cartOptions: [
        { label: 'Sepet 1', value: 1 },
        { label: 'Sepet 2', value: 2 },
        { label: 'Sepet 3', value: 3 }
      ]
    }
  },

  async mounted() {
    await this.$store.dispatch('loadProducts');
    await this.$store.dispatch('loadStockAlerts');
  },
  computed: {
    currentCartTotal() {
      const cartNumber = Number(this.tab) || 1;
      return this.$store.getters.totalCartAmount(cartNumber);
    }
  },

  methods: {
    getCartItems(cartNumber) {
      const items = this.$store.state.saleItems.filter(item => item.selectedCart === cartNumber);
      return items;
    },
    getHardBarcodeProducts() {
      return this.$store.state.products
        .filter(product => product.is_barcode_easy === false)
        .map((product, index) => ({
          id: product.id,
          index: index,
          incrementValue: this.getIncrementValue(product.unit),
          quantity: 0,
          itemSelected: false,
          product: product,
        }));
    },
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
      const cart = Number(this.tab);
      this.$store.commit('ADD_TO_CART', { product, quantity, cart });
      this.$store.commit('SHOW_SNACKBAR', {
        text: `${product.name} ${cart}. sepete eklendi (${quantity} ${product.unit})`,
        color: 'success'
      });
    },

    addManualProduct() {
      if (this.selectedManualProduct) {
        this.addProductToCart(this.selectedManualProduct, parseFloat(this.manualQuantity) || 1);
        this.showManualProduct = false;
        this.selectedManualProduct = null;
        this.manualQuantity = 1;
      }
      if (this.selectedItems) {
        const items = this.selectedItems;
        items.forEach(item => {
          this.addProductToCart(item.product, parseFloat(item.quantity) || 1);
        });
        this.showManualProduct = false;
        this.selectedItems = [];
      }
    },

    updateQuantity(item, newQuantity, cartNumber) {
      const index = this.$store.state.saleItems.findIndex(storeItem =>
        storeItem.id === item.id && storeItem.selectedCart === cartNumber
      );
      const quantity = parseFloat(newQuantity);
      const minQuantity = this.getIncrementValue(item.unit);
      if (index !== -1) {
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
      }
    },

    increaseQuantity(item, cartNumber) {
      const index = this.$store.state.saleItems.findIndex(storeItem =>
        storeItem.id === item.id && storeItem.selectedCart === cartNumber
      );
      const increment = this.getIncrementValue(item.unit);
      const newQuantity = parseFloat((item.quantity + increment).toFixed(1));
      if (index !== -1) {
        this.updateQuantity(item, newQuantity, cartNumber);
      }
    },
    decreaseQuantity(item, cartNumber) {
      const index = this.$store.state.saleItems.findIndex(storeItem =>
        storeItem.id === item.id && storeItem.selectedCart === cartNumber
      );
      const increment = this.getIncrementValue(item.unit);
      if (index !== -1) {
        if (item.quantity > increment) {
          const newQuantity = parseFloat((item.quantity - increment).toFixed(1));
          this.updateQuantity(item, newQuantity, cartNumber);
        }
      }
    },
    removeItem(item, cartNumber) {
      const index = this.$store.state.saleItems.findIndex(storeItem =>
        storeItem.id === item.id && storeItem.selectedCart === cartNumber
      );
      this.$store.commit('REMOVE_FROM_CART', index);
    },
    clearCart() {
      this.$store.commit('CLEAR_CART', Number(this.tab));
    },
    async completeSale() {
      const cartNumber = Number(this.tab);
      const items = this.$store.state.saleItems.filter(item => item.selectedCart === cartNumber);
      if (items.length === 0) return;

      this.completingSale = true;
      try {
        await this.$store.dispatch('completeSale', { cart: cartNumber });
      } finally {
        this.completingSale = false;
      }
      this.clearCart();
    },
    getIncrementValue(unit) {
      switch (unit) {
        case 'kg':
        case 'lt':
        case 'gr':
        case 'ml':
          return 0.1;
        case 'adet':
        default:
          return 1;
      }
    }
  }
}
</script>

<style scoped>
/* Component'e özel stiller buraya */
</style>