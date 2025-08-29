// router.js - Vue Router Yapılandırması
import { createRouter, createWebHashHistory } from 'vue-router'
import Home from '../views/home.vue'
import Products from '../views/products.vue'
import Reports from '../views/reports.vue'
import store from '../store'

const routes = [
  {
    path: '/',
    name: 'home',
    component: Home,
    meta: {
      title: 'Satış',
      icon: '💰'
    }
  },
  {
    path: '/products',
    name: 'products',
    component: Products,
    meta: {
      title: 'Ürün Yönetimi',
      icon: '📦'
    }
  },
  {
    path: '/reports',
    name: 'reports',
    component: Reports,
    meta: {
      title: 'Raporlar',
      icon: '📊'
    }
  },
  {
    // 404 sayfası - bilinmeyen route'lar için
    path: '/:pathMatch(.*)*',
    redirect: '/'
  }
];

const router = createRouter({
  history: createWebHashHistory(), // Hash mode (#/products gibi)
  routes
});

// Route değiştiğinde sayfa başlığını güncelle
router.beforeEach((to, from, next) => {
  if (to.meta.title) {
    document.title = `${to.meta.title} - Market Satış Sistemi`;
  }
  next();
});

// Route değiştiğinde drawer'ı kapat (mobil için)
router.afterEach(() => {
  // Eğer ekran küçükse drawer'ı kapat
  if (window.innerWidth < 960) {
    store.commit('SET_DRAWER', false);
  }
});

export default router
