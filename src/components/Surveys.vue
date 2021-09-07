<template>
    <div>
        <div v-if="page === 1">
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
                            <a href="#" class="btn btn-primary" @click="takeSurvey(row)">Take Survey</a>
                        </div>
                        <div class="card-footer text-muted" v-if="row.bonusAmount !== '0'">
                            Bonus Reward: <span v-text="fromWei(row.bonusAmount)"></span>
                        </div>
                        <div class="card-footer text-muted" v-else>
                            No Bonus Rewards
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div v-else>
            <button type="button" class="btn btn-lg btn-primary mb-4" @click="back">Back</button>
            <h1 v-text="survey.name"></h1>
            <h2 v-text="survey.description"></h2>
            <h3 class="my-4">Questions (ones in blue are required)</h3>
            <div class="border p-5 m-3 border-2" :class="{'border-primary': row.required, 'border-dark': !row.required}" v-for="row,index in survey.questions" :key="index">
                <h6>Question {{index+1}}</h6>
                <h3 v-text="row.title"></h3>
                <h4 v-text="row.description"></h4>
                <div v-if="row.questionType === '0'">
                    <div class="form-check" v-for="choice, indx in row.choices" :key="indx">
                        <input class="form-check-input" type="radio" :id="`radio-${index}-${indx}`" :value="indx" v-model="answers[index]">
                        <label class="form-check-label" :for="`radio-${index}-${indx}`" v-text="choice"></label>
                    </div>
                </div>
                <div v-else-if="row.questionType === '1'">
                    <star-rating :increment="0.5" @update:rating="setRating(index, $event)"></star-rating>
                </div>
                <div v-else>
                    <textarea class="form-control" rows="5" v-model="answers[index]"></textarea>
                </div>
            </div>
            <div class="text-end">
                <button type="button" class="btn btn-lg btn-success" @click="submit" :disabled="!canSubmit">Submit</button>
            </div>
        </div>
    </div>
</template>

<script>
import {mapMutations, mapState} from "vuex"
import Survey from "../../build/contracts-final/Survey.json"
import StarRating from 'vue-star-rating'
import Swal from 'sweetalert2'

export default {
    name: "Surveys",
    components: {
        StarRating
    },
    data() {
        return {
            rows: [],
            survey: {},
            page: 1,
            answers: [],
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
        canSubmit() {
            //loop through all answers to see if the required ones are done
            for(const index in this.survey.questions) {
                const q = this.survey.questions[index]
                if (q.required && this.answers[index] === undefined) {
                    return false
                }
            }
            return true
        }
    },
    methods: {
        async submit() {
            console.log(this.answers)
            //loop through answers to make it the same length as the questions and convert them as strings
            const a = []
            for (const index in this.survey.questions) {
                const q = this.survey.questions[index]
                const answer = this.answers[index]
                if (typeof answer === 'undefined') {
                    a.push('')
                } else {
                    a.push(`${answer}`)
                }
            }
            console.log(a)

            try {
                let msg = "No tokens rewareded. :("
                const receipt = await this.survanaContract.methods.submitSurvey(this.survey.id,a).send({from: this.walletAddress})
                const event = receipt?.events?.SurveySubmited?.returnValues
                console.log(receipt)
                if (event) {
                    if (event._user === this.walletAddress) {
                        const reward = this.fromWei(event._tokensAwarded)
                        msg = `You were rewarded ${reward} tokens!`
                    }
                }

                await Swal.fire({
                    title: "Survey Submitted!",
                    text: msg,
                    icon: 'success',
                    allowOutsideClick: false,
                })

                this.page = 1
            } catch (e) {
                console.log(e)
            }
        },
        setRating(indx, evt) {
            // console.log(indx, evt)
            this.answers[indx] = evt
        },
        fromWei(x) {
            return web3.utils.fromWei(""+x, "ether")
        },
        back() {
            this.survey = {}
            this.page = 1
        },
        async takeSurvey(row) {
            const loader = this.$loading.show({loader: "bars"})
            try {
                const s = new web3.eth.Contract(Survey.abi, row.addr)
                const questions = await s.methods.getQuestions().call({from: this.walletAddress})
                this.survey = {
                    ...row,
                    questions
                }
                console.log(this.survey)
                this.page = 2
            } catch (e) {
                console.log(e)
            }
            loader.hide()
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