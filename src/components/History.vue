<template>
  <div>
      <h1>Completed Surveys</h1>
      <h2 class="mt-5" v-if="rows.length === 0">Nothing completed yet. Go take some surveys!</h2>
      <div class="row mt-5">
            <div class="col-4" v-for="row,index in rows" :key="index">
                <div class="card text-center bg-success text-white">
                    <div class="card-body">
                        <h5 class="card-title" v-text="row.name"></h5>
                        <p class="card-text" v-text="row.description"></p>
                    </div>
                    <div class="card-footer" v-if="rewarded[row.id] !== undefined">
                        Rewarded: <span v-text="rewarded[row.id]"></span> Tokens!
                    </div>
                </div>
            </div>
        </div>
  </div>
</template>

<script>
import {mapMutations, mapState} from "vuex"
// import Survey from "../../build/contracts-final/Survey.json"

export default {
    name: "History",
    data() {
        return {
            rows: [],
            rewarded: {},
        }
    },
    mounted() {
        if (this.contractsLoaded) {
            this.getFinishedSurveys()
        }
    },
    watch: {
        contractsLoaded(v, ov) {
            if (v && !ov) {
                this.getFinishedSurveys()
            }
        },
        page(v, ov) {
            if (ov !== 1 && v === 1) {
                this.getFinishedSurveys()
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
        async getFinishedSurveys() {
            const loader = this.$loading.show({loader: "bars"})
            try {
                this.rows = await this.survanaContract.methods.getUserFinishedSurveys().call({from: this.walletAddress})
                console.log(this.rows)

                const res = await this.survanaContract.getPastEvents(
                    "SurveySubmited",
                    {
                        filter: {
                            _user: this.walletAddress,
                        },
                        fromBlock: 0,
                        toBlock: 'latest'
                    }
                )
                if (res) {
                    for(const row of res) {
                        const event = row.returnValues
                        this.rewarded[+event._surveyId] = this.fromWei(event._tokensAwarded)
                    }
                }
                console.log(res)
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