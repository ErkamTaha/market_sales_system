// app.js - Ana Vue Uygulaması
const { createApp } = Vue;
const { createVuetify } = Vuetify;

// Vuetify yapılandırması
const vuetify = createVuetify({
    theme: {
        defaultTheme: 'light'
    }
});

// Ana Vue uygulaması
const app = createApp({
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
});

// Plugin'leri ekle
app.use(vuetify);
app.use(router);
app.use(store);
app.component('grid-component', GridComponent);

// Uygulamayı mount et
app.mount('#app');
// app.js'e global error handler ekleyin
app.config.errorHandler = (err, vm, info) => {
    console.error('Vue Global Error:', err);
    console.error('Component:', vm);
    console.error('Info:', info);

    // Store varsa snackbar göster
    if (vm.$store) {
        vm.$store.commit('SHOW_SNACKBAR', {
            text: `Uygulama hatası: ${err.message}`,
            color: 'error'
        });
    }
};

// Component yükleme durumunu kontrol etmek için
window.debugVue = {
    checkComponents: () => {
        console.log('Registered components:', app._context.components);
    },

    checkRoutes: () => {
        console.log('Current routes:', router.getRoutes());
    },

    testComponentLoad: async (name) => {
        try {
            const component = await loadComponent(name);
            console.log(`Test load ${name}:`, component);
        } catch (error) {
            console.error(`Test load ${name} failed:`, error);
        }
    }
};