<template>
    <div>
        <h1>Available Surveys</h1>
        <h2 v-if="rows.length === 0">None available at this time</h2>
        <div class="row mt-5">
            <div class="col-4" v-for="row,index in rows" :key="index">
                <div class="card text-center">
                    <div class="card-header">
                        <div>Max Reward: <span v-text="fromWei(row.worth)"></span></div>
                        <div># Questions: <span v-text="row.questionCount"></span></div>
                    </div>
                    <div class="card-body">
                        <h5 class="card-title" v-text="row.name"></h5>
                        <p class="card-text" v-text="row.description"></p>
                        <a href="#" class="btn btn-primary">Take Survey</a>
                    </div>
                    <div class="card-footer text-muted">
                        Bonus Reward: <span v-text="fromWei(row.bonusAmount)"></span>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import {mapMutations, mapState} from "vuex"
import Survey from "../../build/contracts/Survey.json"
export default {
    name: "Surveys",
    data() {
        return {
            rows: [],
        }
    },
    mounted() {
        if (this.contractsLoaded) {
            this.getSurveys()
        }
    },
    watch: {
        contractsLoaded(v, ov) {
            if (v && !ov) {
                this.getSurveys()
            }
        },
        page(v, ov) {
            if (ov !== 1 && v === 1) {
                this.getSurveys()
            }
        }
    },
    computed: {
        ...mapState(['walletAddress', 'survanaContract', 'tokenContract', 'contractsLoaded']),
    },
    methods: {
        fromWei(x) {
            return web3.utils.fromWei(""+x, "ether")
        },
        async getSurveys() {
            const loader = this.$loading.show({loader: "bars"})
            try {
                this.rows = await this.survanaContract.methods.getOpenSurveys().call({from: this.walletAddress})
                console.log(this.rows)
            } catch (e) {
                console.log(e)
            }
            loader.hide()
        }
    }
}
</script>

<style>

</style>