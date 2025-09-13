<template>
  <v-container>
    <v-row>
      <v-col cols="12" sm="6" md="4" lg="3" v-for="(item, index) in localItems" :key="item.id">
        <v-card height="200" class="position-relative" @click="isForSale ? null : showDetails(index)">
          <div v-if="item.itemSelected && isForSale">
            <div color="primary" class="inner-border"></div>
            <div class="total-amount">
              {{ item.total }} ₺
            </div>
          </div>
          <div v-if="isForSale === false">
            <div class="total-amount">
              {{ item.quantity }} {{ item.product.unit }}
            </div>
          </div>
          <v-card-text class="d-flex flex-column align-center text-center">
            <v-icon size="60">mdi-image-area</v-icon>
            <h3>{{ item.product.name }}</h3>
            <v-chip v-if="isForSale" color="success" size="small">
              {{ item.product.price }} ₺ ({{ item.product.unit }})
            </v-chip>
            <v-col class="px-0" v-if="isForSale === false">
              <v-chip class="mb-2" color="success" size="small">
                {{ item.product.price }} ₺ ({{ item.product.unit }})
              </v-chip>
              <div class="total-sale-price">
                {{ item.total_price }} ₺
              </div>
            </v-col>
            <div class="quantity-container" v-if="isForSale">
              <!-- Container that reserves space for all elements -->
              <div class="quantity-inner">
                <!-- Minus button (slides from behind plus button to the left) -->
                <transition name="slide-from-center">
                  <v-btn v-if="item.showQuantityControls" size="small" icon @click="decreaseQuantity(index)"
                    class="custom-btn minus-btn">
                    <transition name="flip" mode="out-in">
                      <div v-if="item.lastOne" key="delete">
                        <v-icon>mdi-delete</v-icon>
                      </div>
                      <div v-else key="minus">
                        <v-icon>mdi-minus</v-icon>
                      </div>
                    </transition>
                  </v-btn>
                </transition>

                <!-- Text field (fade in/out animation) -->
                <div class="input-container">
                  <transition name="fade">
                    <v-text-field v-if="item.showQuantityControls" :model-value="item.quantity"
                      @update:model-value="updateQuantity(index, $event)" type="number" :step="item.incrementValue"
                      :min="item.incrementValue" :max="item.product.max_stock" style="width: 50px;" density="compact"
                      hide-details variant="plain" class="qty-input" />
                  </transition>
                </div>

                <!-- Plus button (always present, moves with CSS transition) -->
                <v-btn size="small" icon
                  @click="item.showQuantityControls ? increaseQuantity(index) : activateQuantityControls(index)"
                  class="custom-btn plus-btn" :class="{ 'positioned-right': item.showQuantityControls }">
                  <v-icon>mdi-plus</v-icon>
                </v-btn>
              </div>
            </div>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<style>
.quantity-container {
  display: flex;
  align-items: center;
  justify-content: center;
  margin-top: 8px;
}

.quantity-inner {
  position: relative;
  display: flex;
  align-items: center;
  width: 110px;
  /* Fixed width to prevent layout shifts */
  height: 40px;
  /* Fixed height */
  justify-content: center;
}

/* Plus button - positioned absolutely for smooth movement */
.plus-btn {
  position: absolute;
  transition: all 0.3s ease;
  left: 50%;
  transform: translateX(-50%);
  /* Initially centered */
  z-index: 3;
}

.plus-btn.positioned-right {
  left: calc(100% - 20px);
  /* Move to right side */
  transform: translateX(-50%);
}

/* Minus button - positioned absolutely */
.minus-btn {
  position: absolute;
  left: 0;
  z-index: 2;
}

/* Input container - positioned absolutely */
.input-container {
  position: absolute;
  left: 57%;
  transform: translateX(-50%);
  width: 50px;
}

/* Minus button slide animation */
.slide-from-center-enter-active,
.slide-from-center-leave-active {
  transition: all 0.3s ease;
}

.slide-from-center-enter-from {
  opacity: 25;
  transform: translateX(90%);
}

.slide-from-center-leave-to {
  opacity: 25;
  transform: translateX(90%);
}

/* Text field - no transition, just appears */
.qty-input {
  z-index: 1;
  /* No transition properties, so it just appears/disappears instantly */
}

/* Fade transition for text field */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.flip-enter-active,
.flip-leave-active {
  transition: all 0.2s ease;
}

.flip-enter-from {
  opacity: 0;
  transform: rotateY(90deg);
}

.flip-leave-to {
  opacity: 0;
  transform: rotateY(90deg);
}

.position-relative {
  position: relative;
}

/* 2px border overlay */
.inner-border {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  border: 1px solid #1976d2;
  /* change color as needed */
  pointer-events: none;
  /* allows clicks to pass through */
  box-sizing: border-box;
  /* ensures border is inside the card */
  border-radius: 4px;
  /* match card's border radius if any */
  z-index: 5;
  /* above content if needed */
}

.total-amount {
  position: absolute;
  margin: 2px;
  z-index: 4;
  font-size: 0.75rem;
  font-weight: bold;
  color: #1976d2;
}

.total-sale-price {
  font-weight: bold;
  font-size: large;
}

.mark-icon {
  position: absolute;
  top: 2px;
  /* distance from top */
  left: 2px;
  /* distance from left */
  z-index: 10;
  /* above other content */
}
</style>

<script>
export default {
  name: 'GridComponent',

  data() {
    return {
      localItems: this.items.map(item => ({
        ...item
      })),
    };
  },

  watch: {

    selection: {
      handler(newSelection) {
        // Sync local selection state with parent selection prop
        const selectedIds = new Set(newSelection.map(item => item.id));
        this.localItems.forEach(item => {
          item.itemSelected = selectedIds.has(item.id);
        });
      },
      deep: true
    },
  },

  props: {
    items: {
      type: Array,
      required: true,
      default: () => []
    },
    isForSale: {
      type: Boolean,
      default: false
    },
    selection: {
      type: Array,
      default: () => []
    },
    showProduct: {
      type: Array,
      default: () => []
    }
  },

  methods: {
    activateQuantityControls(index) {
      this.localItems[index].showQuantityControls = true;
      this.localItems[index].lastOne = true;
      this.localItems[index].total = 0;
      this.increaseQuantity(index);
    },

    showDetails(index) {
      this.$emit('showProduct', this.localItems[index].product);
    },

    roundDecimals(value) {
      return Math.round(value * 10) / 10; // 1 decimal
    },

    increaseQuantity(index) {
      const item = this.localItems[index];
      item.quantity = this.roundDecimals(item.quantity + item.incrementValue);
      item.total = item.quantity * item.product.price;

      if (item.quantity - item.incrementValue > 0) {
        item.lastOne = false;
      }

      if (item.quantity > 0 && item.itemSelected === false) {
        item.itemSelected = true;
      }

      if (item.quantity > 0 && item.itemSelected === true) {
        const selectedItems = this.localItems.filter(i => i.itemSelected).map(i => ({ ...i }));
        this.$emit('update:selection', selectedItems);
      }
    },

    decreaseQuantity(index) {
      const item = this.localItems[index];
      if (item.quantity > 0) {
        item.quantity = this.roundDecimals(item.quantity - item.incrementValue);
        item.total = item.quantity * item.product.price;
        if (item.quantity === 0) {
          item.itemSelected = false;
          this.localItems[index].showQuantityControls = false;
        }
        if (item.quantity - item.incrementValue === 0) {
          item.lastOne = true;
        }
        const selectedItems = this.localItems.filter(i => i.itemSelected).map(i => ({ ...i }));
        this.$emit('update:selection', selectedItems);
      }
    },

    updateQuantity(index, quantity) {
      const item = this.localItems[index];
      item.quantity = this.roundDecimals(quantity);
      item.total = item.quantity * item.product.price;
      if (item.quantity === 0) {
        item.itemSelected = false;
      }
      if (item.quantity - item.incrementValue === 0) {
        item.lastOne = true;
      }
      const selectedItems = this.localItems.filter(i => i.itemSelected).map(i => ({ ...i }));
      this.$emit('update:selection', selectedItems);
    }
  }
}
</script>