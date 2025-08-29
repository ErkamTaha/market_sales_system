<template>
  <v-app>
    <!-- ========================================= -->
    <!-- SOL MENÜ (Her sayfada aynı kalacak)       -->
    <!-- ========================================= -->
    <v-navigation-drawer v-model="$store.state.drawer" app>
      <v-list>
        <!-- Router-link kullanarak sayfa geçişleri -->
        <v-list-item :to="{ name: 'home' }" exact>
          <template v-slot:prepend>
            <v-icon>mdi-cash</v-icon>
          </template>
          <v-list-item-title>Satış</v-list-item-title>
        </v-list-item>

        <v-list-item :to="{ name: 'products' }">
          <template v-slot:prepend>
            <v-icon>mdi-package-variant</v-icon>
          </template>
          <v-list-item-title>Ürün Yönetimi</v-list-item-title>
        </v-list-item>

        <v-list-item :to="{ name: 'reports' }">
          <template v-slot:prepend>
            <v-icon>mdi-chart-bar</v-icon>
          </template>
          <v-list-item-title>Raporlar</v-list-item-title>
        </v-list-item>
      </v-list>
    </v-navigation-drawer>

    <!-- ========================================= -->
    <!-- ÜST BAR (Her sayfada aynı kalacak)        -->
    <!-- ========================================= -->
    <v-app-bar app color="primary" dark>
      <!-- Custom drawer button -->
      <v-btn icon @click="$store.commit('TOGGLE_DRAWER')" size="large">
        <v-icon size="28">mdi-menu</v-icon>
      </v-btn>

      <v-toolbar-title>Market Satış Sistemi</v-toolbar-title>
    </v-app-bar>

    <!-- ========================================= -->
    <!-- ANA İÇERİK ALANI (Sayfa içerikleri burada gösterilir) -->
    <!-- ========================================= -->
    <v-main>
      <!-- 
                Bu kısım en önemli! 
                router-view, URL'ye göre farklı componentleri gösterir:
                - / -> HomeComponent (Satış sayfası)
                - /products -> ProductsComponent (Ürün yönetimi)
                - /reports -> ReportsComponent (Raporlar)
                -->
      <router-view></router-view>
    </v-main>

    <!-- ========================================= -->
    <!-- GLOBAL SNACKBAR (Her sayfada aynı)       -->
    <!-- ========================================= -->
    <v-snackbar v-model="$store.state.snackbar" :color="$store.state.snackbarColor" :timeout="4000">
      {{ $store.state.snackbarText }}
      <template v-slot:actions>
        <v-btn variant="text" @click="$store.commit('HIDE_SNACKBAR')">Kapat</v-btn>
      </template>
    </v-snackbar>
  </v-app>
</template>

<script>

export default {
  name: 'App',

  data() {
    return {
      // App seviyesi veriler buraya
    }
  },

  async mounted() {
    // Uygulama başlatıldığında çalışacak kodlar
    console.log('Market Satış Sistemi başlatıldı');

    // Eğer hiç ürün yoksa, ürünleri yükle
    if (this.$store.state.products.length === 0) {
      await this.$store.dispatch('loadProducts');
    }
  },

  methods: {
    // Global metodlar buraya
  }
}
</script>
