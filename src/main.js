import {createApp} from "vue"
import {createStore} from "vuex"
import App from "./App.vue"

import VueLoading from 'vue-loading-overlay'
import 'vue-loading-overlay/dist/vue-loading.css'

import "bootstrap/dist/js/bootstrap.bundle.min"
import "bootstrap/dist/css/bootstrap.min.css"
import "bootstrap-icons/font/bootstrap-icons.css"

const store = createStore({
    state () {
        return {
            walletAddress: "",
            userType: "",
            pageTitle: "Surveys",
            page: 0,
            survanaContract: null,
            tokenContract: null,
            contractsLoaded: false,
        }
    },
    mutations: {
        setAddress(state, address) {
            state.walletAddress = address
        },
        setUserType(state, utype) {
            state.userType = utype
        },
        setPageTitle(state, title) {
            state.pageTitle = title
        },
        setPage(state, page) {
            state.page = page
        },
        setSurvanaContract(state, contract) {
            state.survanaContract = contract
        },
        setTokenContract(state, contract) {
            state.tokenContract = contract
        },
        setContractLoaded(state, loaded) {
            state.contractsLoaded = loaded
        }
    }
})

const app = createApp(App)
app.use(store)
app.use(VueLoading)
app.mount("#app")