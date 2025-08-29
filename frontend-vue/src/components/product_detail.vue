<template>
    <v-dialog max-width="600" :z-index="1001">
        <v-card v-if="product">
            <v-card-title class="bg-info text-white">
                Ürün Detayları
            </v-card-title>
            <v-card-text class="pa-6">
                <div class="text-center mb-4">
                    <v-avatar size="80" color="primary">📦</v-avatar>
                    <h2 class="mt-3">{{ product.name }}</h2>
                    <v-chip :color="product.is_active ? 'success' : 'error'">
                        {{ product.is_active ? 'Aktif' : 'Pasif' }}
                    </v-chip>
                </div>
                <v-list>
                    <v-list-item>
                        <v-list-item-title>ID</v-list-item-title>
                        <v-list-item-subtitle>{{ product.id }}</v-list-item-subtitle>
                    </v-list-item>
                    <v-list-item v-if="product.barcode">
                        <v-list-item-title>Barkod</v-list-item-title>
                        <v-list-item-subtitle>{{ product.barcode }}</v-list-item-subtitle>
                    </v-list-item>
                    <v-list-item>
                        <v-list-item-title>Kategori</v-list-item-title>
                        <v-list-item-subtitle>{{ product.category || 'Kategorisiz' }}</v-list-item-subtitle>
                    </v-list-item>
                    <v-list-item>
                        <v-list-item-title>Fiyat</v-list-item-title>
                        <v-list-item-subtitle class="font-weight-bold">{{ product.price.toFixed(2) }}
                            ₺</v-list-item-subtitle>
                    </v-list-item>
                    <v-list-item>
                        <v-list-item-title>Mevcut Stok</v-list-item-title>
                        <v-list-item-subtitle>
                            <v-chip :color="getStockColor(product)" size="small">
                                {{ product.current_stock }} {{ product.unit }}
                            </v-chip>
                        </v-list-item-subtitle>
                    </v-list-item>
                    <v-list-item>
                        <v-list-item-title>Kritik Stok</v-list-item-title>
                        <v-list-item-subtitle>{{ product.critical_stock_level }} {{ product.unit
                        }}</v-list-item-subtitle>
                    </v-list-item>
                    <v-list-item v-if="product.expiry_date">
                        <v-list-item-title>Son Kullanma Tarihi</v-list-item-title>
                        <v-list-item-subtitle>
                            <v-chip :color="getExpiryColor(product.expiry_date)" size="small">
                                {{ formatDate(product.expiry_date) }}
                            </v-chip>
                        </v-list-item-subtitle>
                    </v-list-item>
                    <v-list-item v-if="product.description">
                        <v-list-item-title>Açıklama</v-list-item-title>
                        <v-list-item-subtitle>{{ product.description }}</v-list-item-subtitle>
                    </v-list-item>
                </v-list>
            </v-card-text>
        </v-card>
    </v-dialog>
</template>

<script>
export default {
    name: 'ProductDetailComponent',

    data() {
        return {
        };
    },

    props: {
        product: {
            type: Array,
            default: () => [],
            required: true
        }
    },

    methods: {
        formatDate(dateString) {
            if (!dateString) return '';
            const date = new Date(dateString);
            return date.toLocaleDateString('tr-TR');
        },
        getExpiryColor(dateString) {
            if (!dateString) return 'grey';
            const date = new Date(dateString);
            const today = new Date();
            const diffDays = Math.ceil((date - today) / (1000 * 60 * 60 * 24));

            if (diffDays < 0) return 'error';
            if (diffDays <= 7) return 'warning';
            return 'success';
        },

        getStockColor(product) {
            if (product.current_stock <= 0) return 'error';
            if (product.current_stock <= product.critical_stock_level) return 'warning';
            return 'success';
        }
    }
}
</script>