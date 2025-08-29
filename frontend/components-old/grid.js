const GridComponent = {
    template: `
        <v-container>
            <v-row>
                <v-col 
                    cols="12"    
                    sm="6"       
                    md="4"       
                    lg="3"       
                    xl="2"       
                    v-for="item in items" 
                    :key="item.id"
                >
                    <v-card height="200" width="100" hover @click="selectItem(item)">
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
    `,

    props: {
        items: {
            type: Array,
            default: () => []
        },
        isForSale: {
            type: Boolean,
            default: () => false,
        }
    },
    
    methods: {
        selectItem(item) {
            this.$emit('item-selected', item);
        }
    }
}