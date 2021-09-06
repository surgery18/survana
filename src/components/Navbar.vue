<template>
    <div>
        <nav class="py-2 bg-light border-bottom">
            <div class="container d-flex flex-wrap">
                <ul class="nav me-auto">
                    <li class="nav-item"><a href="#" class="nav-link link-dark px-2 active" @click.prevent="changePage(0)">Surveys</a></li>
                    <li class="nav-item"><a href="#" class="nav-link link-dark px-2" @click.prevent="changePage(1)">Creator</a></li>
                    <li class="nav-item"><a href="#" class="nav-link link-dark px-2">History</a></li>
                    <!-- <li class="nav-item"><a href="#" class="nav-link link-dark px-2" v-if="userType === 'owner'">Admin</a></li> -->
                </ul>
                <ul class="nav">
                    <li class="nav-item mt-2" v-text="walletAddress"></li>
                </ul>
            </div>
        </nav>
        <header class="py-3 mb-4 border-bottom">
            <div class="container d-flex flex-wrap justify-content-between">
                <div class="text-dark text-decoration-none">
                    <span class="fs-4">Survana</span>
                </div>
                <div>
                    <h3 v-text="pageTitle"></h3>
                </div>
                <div >
                    <span class="fs-4" v-text="userType"></span>
                </div>
            </div>
        </header>
    </div>
</template>

<script>
import {mapState, mapMutations} from "vuex"
export default {
    name: "Navbar",
    computed: {
        ...mapState(['walletAddress', 'userType', 'pageTitle'])
    },
    methods: {
        ...mapMutations(['setPageTitle', 'setPage']),
        changePage(p) {
            if (p === 0) {
                this.setPage(0)
                this.setPageTitle("Surveys")
            } else if (p === 1) {
                this.setPage(1)
                this.setPageTitle("Creator")
            }
        }
    }
}
</script>

<style>

</style>