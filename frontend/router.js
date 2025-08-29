// router.js - Vue Router Yapılandırması
const { createRouter, createWebHashHistory } = VueRouter;

// Vue SFC dosyalarını yükleme fonksiyonu
async function loadVueComponent(url) {
    const response = await fetch(url);
    const template = await response.text();
    return Vue.defineAsyncComponent(() => {
        return Vue.compileToFunction(template);
    });
}

// Daha basit yöntem - sadece template'i yükle
async function loadComponent(path) {
    const response = await fetch(`components/${path}.vue`);
    const content = await response.text();
    
    // .vue dosyasını parse et
    const templateMatch = content.match(/<template>([\s\S]*?)<\/template>/);
    const scriptMatch = content.match(/<script>([\s\S]*?)<\/script>/);
    const styleMatch = content.match(/<style[^>]*>([\s\S]*?)<\/style>/);
    
    const template = templateMatch ? templateMatch[1] : '';
    const scriptContent = scriptMatch ? scriptMatch[1] : 'export default {}';
    
    // Script içeriğini değerlendir
    const module = {};
    const exports = {};
    eval(scriptContent.replace('export default', 'module.exports ='));
    
    const component = module.exports || {};
    component.template = template;
    
    // Style'ı head'e ekle
    if (styleMatch) {
        const style = document.createElement('style');
        style.textContent = styleMatch[1];
        document.head.appendChild(style);
    }
    
    return component;
}

const routes = [
    {
        path: '/',
        name: 'home',
        component: () => loadComponent('Home'),
        meta: {
            title: 'Satış',
            icon: '💰'
        }
    },
    {
        path: '/products',
        name: 'products',
        component: () => loadComponent('Products'),
        meta: {
            title: 'Ürün Yönetimi',
            icon: '📦'
        }
    },
    {
        path: '/reports',
        name: 'reports',
        component: () => loadComponent('Reports'),
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