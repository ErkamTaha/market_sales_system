<template>
  <v-container>
    <v-row>
      <v-col cols="12" sm="6" md="4" lg="3" v-for="(item, index) in localItems" :key="item.id">
        <v-card height="200" hover class="position-relative"
          @click="isForSale ? selectItem(index) : showDetails(index)">
          <div v-if="item.itemSelected && isForSale">
            <div color="primary" class="inner-border"></div>
            <v-icon color="primary" size="24" class="mark-icon">
              mdi-check
            </v-icon>
          </div>
          <v-card-text class="d-flex flex-column align-center text-center">
            <v-avatar size="60" color="primary" class="mb-3">
              📋
            </v-avatar>
            <h3>{{ item.product.name }}</h3>
            <v-chip color="success" size="small">
              {{ item.product.price }} ₺
            </v-chip>
            <div class="d-flex align-center" justify-center mt-2 v-if="isForSale">
              <v-btn size="small" icon @click.stop="decreaseQuantity(index)" class="custom-btn">
                <v-icon>mdi-minus</v-icon>
              </v-btn>
              <v-text-field :model-value="item.quantity" @click.stop @update:model-value="updateQuantity(index, $event)"
                type="number" :step="item.incrementValue" :min="item.incrementValue" :max="item.product.max_stock"
                style="width: 50px;" density="compact" hide-details variant="plain" class="qty-input"></v-text-field>
              <v-btn size="small" icon @click.stop="increaseQuantity(index)" class="custom-btn">
                <v-icon>mdi-plus</v-icon>
              </v-btn>
            </div>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<style>
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
  border: 2px solid #1976d2;
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

    showDetails(index) {
      this.$emit('showProduct', this.localItems[index].product);
    },

    roundDecimals(value) {
      return Math.round(value * 10) / 10; // 1 decimal
    },

    selectItem(index) {
      const item = this.localItems[index];
      item.itemSelected = !item.itemSelected;

      const selectedItems = this.localItems.filter(i => i.itemSelected).map(i => ({ ...i }));
      this.$emit('update:selection', selectedItems);
    },

    increaseQuantity(index) {
      const item = this.localItems[index];
      item.quantity = this.roundDecimals(item.quantity + item.incrementValue);

      if (item.itemSelected) {
        this.$emit('update:selection', this.localItems.filter(i => i.itemSelected).map(i => ({ ...i })));
      }
    },

    decreaseQuantity(index) {
      const item = this.localItems[index];
      if (item.quantity > 0) {
        item.quantity = this.roundDecimals(item.quantity - item.incrementValue);
        if (item.itemSelected) {
          this.$emit('update:selection', this.localItems.filter(i => i.itemSelected).map(i => ({ ...i })));
        }
      }
    },

    updateQuantity(index, quantity) {
      const item = this.localItems[index];
      item.quantity = this.roundDecimals(quantity);
      if (item.itemSelected) {
        this.$emit('update:selection', this.localItems.filter(i => i.itemSelected).map(i => ({ ...i })));
      }
    }
  }
}
</script>