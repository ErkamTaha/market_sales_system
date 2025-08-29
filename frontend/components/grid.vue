<template>
  <v-container>
    <v-row>
      <v-col 
        cols="12" sm="6" md="4" lg="3"
        v-for="item in items" 
        :key="item.id"
      >
        <v-card height="200" hover @click="selectItem(item)">
          <v-card-text class="d-flex flex-column justify-center align-center text-center fill-height">
            <v-avatar size="60" color="primary" class="mb-3">
              📋
            </v-avatar>
            <h3>{{ item.product.name }}</h3>
            <v-chip color="success" size="small">
              {{ item.product.price }} ₺
            </v-chip>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
export default {
  name: 'GridComponent',
  
  props: {
    items: {
      type: Array,
      default: () => []
    }
  },
  
  methods: {
    selectItem(item) {
      this.$emit('item-selected', item);
    }
  }
}
</script>