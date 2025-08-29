import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import store from './store'
import vuetify from './plugins/vuetify'
import { loadFonts } from './plugins/webfontloader'
import GridComponent from './components/grid.vue'
import ProductDetailComponent from './components/product_detail.vue'

loadFonts()

createApp(App)
  .use(router)
  .use(vuetify)
  .use(store)
  .component('grid-component', GridComponent)
  .component('product-detail-component', ProductDetailComponent)
  .mount('#app')
