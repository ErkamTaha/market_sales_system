<template>
  <v-container>
    <v-row class="mb-4">
      <v-col>
        <h2>Satışlar</h2>
      </v-col>
      <v-col cols="auto">
        <p class="text-grey">Toplam {{ filteredSales.length }} satış</p>
        <p class="text-grey">Toplam tutar: {{ filteredTotalAmount }} ₺</p>
      </v-col>
    </v-row>

    <v-card class="mb-4">
      <v-card-text>
        <v-row>
          <v-col cols="12" md="3">
            <v-select v-model="dateFilter" :items="dateOptions" label="Satış Tarihi" clearable hide-details>
              <template v-slot:prepend>
                <v-icon>mdi-magnify</v-icon>
              </template>
            </v-select>
          </v-col>
          <v-col cols="12" md="7">
          </v-col>
          <v-col cols="12" md="2">
            <v-btn color="secondary" block @click="resetFilters">
              Temizle
            </v-btn>
          </v-col>
        </v-row>
      </v-card-text>
    </v-card>
    <v-card>
      <v-card-title class="d-flex align-center">
        Satış Listesi
        <v-spacer></v-spacer>
        <v-chip color="primary">{{ filteredSales.length }} satış</v-chip>
      </v-card-title>
      <v-data-table :headers="saleHeaders" :items="filteredSales" :loading="$store.state.loadingSales"
        :items-per-page="10" item-value="id" @click:row="handleRowClick" hover
        :row-props="{ style: 'cursor: pointer' }">
        <template v-slot:[`item.total_amount`]="{ item }">
          <span class="font-weight-bold">{{ item.total_amount.toFixed(2) }} ₺</span>
        </template>
        <template v-slot:[`item.sale_date`]="{ item }">
          <v-chip v-if="item.sale_date" color="primary" size="small">
            {{ formatDate(item.sale_date) }}
          </v-chip>
          <span v-else class="text-grey">-</span>
        </template>
      </v-data-table>
    </v-card>

    <v-dialog v-model="showSaleDetail" max-width="600" :z-index="1000">
      <v-card v-if="selectedSale">
        <v-card-title class="bg-info text-white">
          Satış Detayları
        </v-card-title>
        <v-card-text class="pa-6">
          <v-list>
            <v-list-item>
              <v-list-item-title>ID</v-list-item-title>
              <v-list-item-subtitle>{{ selectedSale.id }}</v-list-item-subtitle>
            </v-list-item>
            <v-list-item>
              <v-list-item-title>Toplam Tutar</v-list-item-title>
              <v-list-item-subtitle class="font-weight-bold">{{ selectedSale.total_amount.toFixed(2) }}
                ₺</v-list-item-subtitle>
            </v-list-item>
            <v-list-item v-if="selectedSale.sale_date">
              <v-list-item-title>Satış Tarihi</v-list-item-title>
              <v-list-item-subtitle>{{ formatDate(selectedSale.sale_date) }}
              </v-list-item-subtitle>
            </v-list-item>
          </v-list>
        </v-card-text>
        <grid-component :items="selectedSale.items" @showProduct="handleShowProductDetails"></grid-component>
      </v-card>
    </v-dialog>

    <product-detail-component v-model="showProductDetail" :product="productToDisplay">

    </product-detail-component>
  </v-container>
</template>

<script>
export default {
  name: 'ReportsComponent',

  data() {
    return {
      dateFilter: '',

      totalAmount: 0,

      selectedSale: null,
      showSaleDetail: false,

      showProductDetail: false,
      productToDisplay: null,

      //Seçenekler
      dateOptions: [
        { title: 'Tümü', value: '' },
        { title: 'Bugün', value: 'today' },
        { title: 'Bu Hafta', value: 'this week' },
        { title: 'Bu Ay', value: 'this month' },
      ],

      // Tablo başlıkları
      saleHeaders: [
        { title: 'ID', key: 'id', width: '80px' },
        { title: 'Toplam Fiyat', key: 'total_amount' },
        { title: 'Satış Tarihi', key: 'sale_date' },
      ]
    }
  },

  computed: {
    filteredSales() {
      let filtered = this.$store.state.sales;

      if (this.dateFilter) {
        const today = new Date();
        let startDate, endDate;

        switch (this.dateFilter) {
          case 'today':
            startDate = new Date(today.getFullYear(), today.getMonth(), today.getDate());
            endDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1);
            break;

          case 'this week':
            startDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 7);
            endDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1);
            break;

          case 'this month':
            startDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 30);
            endDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1);
            break;

          default:
            return filtered;
        }

        filtered = filtered.filter(sale => {
          const saleDate = new Date(sale.sale_date);
          return saleDate >= startDate && saleDate < endDate;
        });
      }

      return filtered;
    },

    filteredTotalAmount() {
      return this.filteredSales.reduce((total, sale) => total + sale.total_amount, 0);
    }
  },

  beforeRouteEnter(to, from, next) {
    next(vm => {
      vm.reloadSalesData();
    });
  },

  async mounted() {
    if (this.$store.state.sales.length === 0) {
      await this.$store.dispatch('loadSales');
    }
  },

  methods: {

    handleShowProductDetails(product) {
      console.log('Received product:', product);
      this.productToDisplay = product;
      this.showProductDetail = true;
      console.log('Dialog should show:', this.showProductDetail);
    },

    async reloadSalesData() {
      await this.$store.dispatch('loadSales');
    },

    handleRowClick(event, { item }) {
      this.selectedSale = item;
      this.showSaleDetail = true;
    },

    resetFilters() {
      this.dateFilter = '';
    },

    formatDate(dateString) {
      if (!dateString) return '';
      const date = new Date(dateString);
      return date.toLocaleString('tr-TR');
    },

  }
}
</script>