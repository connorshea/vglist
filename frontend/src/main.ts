import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { DefaultApolloClient } from '@vue/apollo-composable'
import App from './App.vue'
import router from './router'
import { apolloClient } from './graphql/client'

import './assets/stylesheets/application.scss'

const app = createApp(App)

app.provide(DefaultApolloClient, apolloClient)
app.use(createPinia())
app.use(router)

app.mount('#app')
