// store.js - Vuex Store (Global State Management)
import { createStore } from 'vuex'
import axios from 'axios'

// Axios instance oluşturun
const api = axios.create({
    baseURL: 'http://localhost:8000',
    timeout: 10000,
    headers: {
        'Content-Type': 'application/json'
    }
})

// Request interceptor
api.interceptors.request.use(
    config => {
        console.log(`API Request: ${config.method?.toUpperCase()} ${config.url}`)
        return config
    },
    error => Promise.reject(error)
)

// Response interceptor  
api.interceptors.response.use(
    response => {
        console.log(`API Response: ${response.status} ${response.config.url}`)
        return response
    },
    error => {
        console.error('API Error:', error.response?.data || error.message)
        return Promise.reject(error)
    }
)

const store = createStore({
    state: {
        // Sepet verileri
        saleItems: [],

        // Satışlar
        sales: [],
        loadingSales: false,

        // Ürün verileri
        products: [],
        loadingProducts: false,

        // Stok uyarıları
        lowStockProducts: [],
        expiredProducts: [],
        expiringProducts: [],

        // UI durumları
        drawer: false,

        // Snackbar
        snackbar: false,
        snackbarText: '',
        snackbarColor: 'info',

        // Modal durumları (global)
        showSaleComplete: false,
        lastSaleAmount: 0
    },

    mutations: {
        // Sepet işlemleri
        ADD_TO_CART(state, { product, quantity = 1, cart }) {
            const existingIndex = state.saleItems.findIndex(item => item.id === product.id && item.selectedCart === cart);

            if (existingIndex >= 0) {
                state.saleItems[existingIndex].quantity += quantity;
            } else {
                state.saleItems.push({
                    id: product.id,
                    name: product.name,
                    unit_price: product.price,
                    quantity: quantity,
                    unit: product.unit,
                    max_stock: product.current_stock,
                    barcode: product.barcode || '',
                    category: product.category || '',
                    selectedCart: cart
                });
            }
        },

        UPDATE_CART_ITEM(state, { index, quantity }) {
            if (state.saleItems[index]) {
                state.saleItems[index].quantity = quantity;
            }
        },

        REMOVE_FROM_CART(state, index) {
            state.saleItems.splice(index, 1);
        },

        CLEAR_CART(state, cart) {
            state.saleItems = state.saleItems.filter(item => item.selectedCart !== cart);
        },

        // Ürün işlemleri
        SET_PRODUCTS(state, products) {
            state.products = products;
        },

        SET_SALES(state, sales) {
            state.sales = sales;
        },

        SET_LOADING_PRODUCTS(state, loading) {
            state.loadingProducts = loading;
        },

        SET_LOADING_SALES(state, loading) {
            state.loadingSales = loading;
        },

        ADD_PRODUCT(state, product) {
            state.products.push(product);
        },

        UPDATE_PRODUCT(state, updatedProduct) {
            const index = state.products.findIndex(p => p.id === updatedProduct.id);
            if (index !== -1) {
                state.products[index] = updatedProduct;
            }
        },

        DELETE_PRODUCT(state, productId) {
            state.products = state.products.filter(p => p.id !== productId);
        },

        // Stok uyarıları
        SET_STOCK_ALERTS(state, { lowStock, expired, expiring }) {
            state.lowStockProducts = lowStock;
            state.expiredProducts = expired;
            state.expiringProducts = expiring;
        },

        // UI durumları
        TOGGLE_DRAWER(state) {
            state.drawer = !state.drawer;
        },

        SET_DRAWER(state, value) {
            state.drawer = value;
        },

        // Snackbar
        SHOW_SNACKBAR(state, { text, color = 'info' }) {
            state.snackbarText = text;
            state.snackbarColor = color;
            state.snackbar = true;
        },

        HIDE_SNACKBAR(state) {
            state.snackbar = false;
        },

        // Satış tamamlama
        COMPLETE_SALE(state, amount) {
            state.lastSaleAmount = amount;
            state.showSaleComplete = true;
        },

        HIDE_SALE_COMPLETE(state) {
            state.showSaleComplete = false;
        }
    },

    actions: {

        async apiCall({ commit }, { url, method = 'GET', data = null }) {
            try {
                const config = {
                    method: method.toLowerCase(),
                    url: url
                }

                if (data) {
                    config.data = data
                }

                const response = await api(config)
                return response.data

            } catch (error) {
                const errorMessage = error.response?.data?.detail || error.message || 'Bir hata oluştu'

                commit('SHOW_SNACKBAR', {
                    text: errorMessage,
                    color: 'error'
                })

                throw error
            }
        },

        // Ürünleri yükle
        async loadProducts({ commit, dispatch }) {
            commit('SET_LOADING_PRODUCTS', true);
            try {
                const products = await dispatch('apiCall', { url: '/api/products/' });
                commit('SET_PRODUCTS', products);
            } catch (error) {
                console.error('Ürünler yüklenirken hata:', error);
            } finally {
                commit('SET_LOADING_PRODUCTS', false);
            }
        },

        // Satışları yükle
        async loadSales({ commit, dispatch }) {
            commit('SET_LOADING_SALES', true);
            try {
                const sales = await dispatch('apiCall', { url: '/api/sales/' });
                commit('SET_SALES', sales);
            } catch (error) {
                console.error('Satışlar yüklenirken hata:', error);
            } finally {
                commit('SET_LOADING_SALES', false);
            }
        },

        // Stok uyarılarını yükle
        async loadStockAlerts({ commit, dispatch }) {
            try {
                const [lowStock, expired, expiring] = await Promise.all([
                    dispatch('apiCall', { url: '/api/products/low-stock/' }),
                    dispatch('apiCall', { url: '/api/products/expired/' }),
                    dispatch('apiCall', { url: '/api/products/expiring-soon/' })
                ]);

                commit('SET_STOCK_ALERTS', { lowStock, expired, expiring });

                // Uyarıları göster
                const alerts = [];
                if (lowStock.length > 0) {
                    alerts.push(`${lowStock.length} ürün kritik stokta`);
                }
                if (expired.length > 0) {
                    alerts.push(`${expired.length} ürün süresi geçmiş`);
                }
                if (expiring.length > 0) {
                    alerts.push(`${expiring.length} ürün yakında bitecek`);
                }

                if (alerts.length > 0) {
                    commit('SHOW_SNACKBAR', {
                        text: `DİKKAT: ${alerts.join(', ')}`,
                        color: 'warning'
                    });
                }

            } catch (error) {
                console.error('Stok uyarıları yüklenirken hata:', error);
            }
        },

        // Satışı tamamla
        async completeSale({ state, commit, dispatch }, { cart }) {
            const items = state.saleItems.filter(item => item.selectedCart === cart);
            if (items.length === 0) return;

            try {
                const saleData = {
                    total_amount: items.reduce((total, item) => total + (item.quantity * item.unit_price), 0),
                    items: items.map(item => ({
                        product_id: item.id,
                        quantity: item.quantity,
                        unit_price: item.unit_price,
                        total_price: item.quantity * item.unit_price
                    }))
                };

                await dispatch('apiCall', { url: '/api/sales/', method: 'POST', data: saleData });

                commit('COMPLETE_SALE', saleData.total_amount);
                await dispatch('loadProducts');
                await dispatch('loadStockAlerts');

                commit('SHOW_SNACKBAR', { text: 'Satış başarıyla tamamlandı!', color: 'success' });

            } catch (error) {
                console.error('Satış tamamlanırken hata:', error);
                commit('SHOW_SNACKBAR', { text: 'Satış tamamlanamadı!', color: 'error' });
            }
        }
    },

    getters: {
        // Sepet toplam tutarı
        totalCartAmount: (state) => (cartNumber) => {
            return state.saleItems
                .filter(item => item.selectedCart === cartNumber)
                .reduce((total, item) => total + (item.quantity * item.unit_price), 0);
        },

        // Kategoriler listesi
        categories: (state) => {
            const cats = [...new Set(state.products.map(p => p.category).filter(Boolean))];
            return cats.map(cat => ({ title: cat, value: cat }));
        }
    }
});

export default store