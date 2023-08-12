<template>
    <div>
        <div class="text-center" v-if="userType != 'creator'">
            <h1>Please register as a creator to make surveys</h1>
            <button type="button" class="btn btn-lg btn-primary fs-1" @click="registerCreator">REGISTER</button>
        </div>
        <div v-else>
            <div v-if="page == 1">
                <table class="table table-bordered table-stripped">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Name</th>
                            <th>Description</th>
                            <th>Status</th>
                            <th># Taken</th>
                            <th>Liquidity Pool</th>
                            <th># Questions</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="row, index in data" :key="index">
                            <td v-text="row.id"></td>
                            <td v-text="row.name"></td>
                            <td v-text="row.description"></td>
                            <td v-text="getStatus(row.status)"></td>
                            <td v-text="row.taken"></td>
                            <td>
                                tokensLeft: <span v-text="fromWei(row.tokensLeft)"></span>
                                <br />
                                gasLeft: <span v-text="fromWei(row.gasLeft)"></span>
                            </td>
                            <td v-text="row.questionCount"></td>
                            <td class="d-flex flex-row flex-wrap justify-content-around">
                                <button type="button" class="btn btn-sm btn-primary" title="Edit Survey" @click="updateSurvey(row)" v-if="row.status === '0'"><i class="bi bi-pencil-square"></i></button>
                                <button type="button" class="btn btn-sm btn-primary" title="Report" @click="seeReport(row)"><i class="bi bi-clipboard-data"></i></button>
                                <button type="button" class="btn btn-sm btn-primary" title="Liquidity Pool" @click="LiquidityPool(row)"><i class="bi bi-bank"></i></button>
                                <button type="button" class="btn btn-sm btn-primary" title="Change Status" @click="openStatus(row)"><i class="bi bi-clipboard"></i></button>
                            </td>
                        </tr>
                    </tbody>
                    <tfoot>
                        <tr v-if="loading">
                            <td colspan="8">
                                <div class="text-center">
                                    <div class="spinner-border text-primary" role="status"></div>
                                    <span class="fs-2 fw-bolder">LOADING</span>
                                </div>
                            </td>
                        </tr>
                        <tr v-else>
                            <td colspan="8">
                                <div class="text-center">
                                    <button type="button" class="btn btn-sm btn-success" @click="addSurvey">Add</button>
                                </div>
                            </td>
                        </tr>
                    </tfoot>
                </table>
            </div>
            <div v-else-if="page === 2">
                <h1>{{textSurvey}} Survey</h1>
                <button type="button" class="btn btn-lg btn-primary mb-4" @click="back">BACK</button>
                <form>
                    <div class="mb-3">
                        <label class="form-label">Name</label>
                        <input type="text" class="form-control" v-model="survey.name" />
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Description</label>
                        <textarea class="form-control" v-model="survey.description"></textarea>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Bonus Amount</label>
                        <input type="number" min="0" class="form-control" v-model="survey.bonusAmount" />
                    </div>
                    <button type="submit" class="btn btn-primary" @click.prevent="submitSurvey">{{textSurvey}} Survey</button>
                </form>
                <h2 class="mt-4">Questions</h2>
                <span v-if="survey.id == null">Must submit survey first before adding questions</span>
                <div v-else>
                    <h5>Add/update your questions here</h5>
                    <div class="m-3 border border-dark p-5" v-for="row, index in questions" :key="index">
                        <h6>Question {{index+1}}</h6>
                        <div class="mb-3">
                            <label class="form-label">Title</label>
                            <input type="text" class="form-control" v-model="row.title" />
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Description</label>
                            <textarea class="form-control" v-model="row.description"></textarea>
                        </div>
                        <div class="mb-3 form-check">
                            <label class="form-check-label">
                                <input type="checkbox" class="form-check-input" v-model="row.required">
                                Required?
                            </label>
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Token Reward</label>
                            <input type="text" class="form-control" v-model="row.worth" />
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Question Type</label>
                            <select class="form-control" v-model="row.type">
                                <option value="0">Mulitple Choice</option>
                                <option value="1">Rate</option>
                                <option value="2">Text</option>
                            </select>
                        </div>
                        <div v-if="row.type === '0'">
                            <div class="input-group  mb-3" v-for="choice, indx in row.choices" :key="indx">
                                <span class="input-group-text">Choice {{indx + 1}}</span>
                                <input type="text" class="form-control" v-model="row.choices[indx]" />
                                <button type="button" class="btn btn-outline-danger" @click="removeChoice(row, indx)" v-if="row.id === null"><i class="bi bi-trash"></i></button>
                            </div>
                            <button type="button" class="btn btn-lg btn-success mt-4" @click="addChoice(row)">Add Choice</button>
                        </div>
                        <div class="text-end">
                            <button type="button" class="btn btn-lg btn-danger mx-2" @click="removeQuestion(index)" v-if="row.id === null">Delete</button>
                            <button type="button" class="btn btn-lg btn-success" @click="saveQuestion(row)">Save</button>
                        </div>
                    </div>
                    <button type="button" class="btn btn-lg btn-success mt-4" @click="addQuestion">Add Question</button>
                    <div class="mt-5 fw-bolder fst-italic">Note: Can only delete questions before submitting them. Once submitted, you can only update them.</div>
                </div>
            </div>
            <div v-else>
                <h1>Survey #{{survey.id}}</h1>
                <button type="button" class="btn btn-lg btn-primary mb-4" @click="back">BACK</button>
                <h2 class="mt-4">Questions</h2>
                <div v-for="row, index in questions" :key="index">
                    <h5 v-text="row.title"></h5>
                    <table class="table table-bordered table-stripped">
                        <thead>
                            <tr v-if="+row.type === 0">
                                <th>Choice</th>
                                <th>Count</th>
                            </tr>
                            <tr v-else-if="+row.type === 1">
                                <th>Rating</th>
                                <th>Count</th>
                            </tr>
                            <tr v-else>
                                <th>Answer</th>
                            </tr>
                        </thead>
                        <tbody v-if="+row.type === 0">
                            <tr v-for="choice,indx in row.choices" :key="indx">
                                <td v-text="choice"></td>
                                <td v-if="answers[index] && answers[index][indx] !== undefined" v-text="answers[index][indx]"></td>
                                <td v-else>0</td>
                            </tr>
                        </tbody>
                        <tbody v-else-if="+row.type === 1">
                            <tr v-for="rating,indx in ratings" :key="indx">
                                <td v-text="rating"></td>
                                <td v-if="answers[index] && answers[index][rating] !== undefined" v-text="answers[index][rating]"></td>
                                <td v-else>0</td>
                            </tr>
                        </tbody>
                        <tbody v-else>
                            <tr v-for="answer,indx in answers[index]" :key="indx">
                                <td v-text="answer"></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <modal v-if="showLP && lp" @close="closeModal">
            <template v-slot:header>
                <h3>Liquidity Pool (ID #{{lp.id}})</h3>
            </template>
            <template v-slot:body>
                <div v-if="!lp.approving">
                    <h2>PANGO Tokens: {{lp.tokens}}</h2>
                    <h2>Gas: {{lp.gas}}</h2>
                    <h5>Balance: {{lp.tokenBalance}}</h5>
                    <div class="mb-3 input-group">
                        <span class="input-group-text">Token</span>
                        <input type="number" min="0" class="form-control" v-model="lp.tokenInput" />
                        <button type="button" class="btn btn-outline-success" @click="deposit('tokens')">Deposit</button>
                        <button type="button" class="btn btn-outline-danger" @click="withdraw('tokens')">Withdraw</button>
                    </div>
                    <h5>Balance: {{lp.ethBalance}}</h5>
                    <div class="mb-3 input-group">
                        <span class="input-group-text">Gas</span>
                        <input type="number" min="0" class="form-control" v-model="lp.ethInput" />
                        <button type="button" class="btn btn-outline-success" @click="deposit('eth')">Deposit</button>
                        <button type="button" class="btn btn-outline-danger" @click="withdraw('eth')">Withdraw</button>
                    </div>
                    <div>
                        <small>Get Tokens here <a href="https://swap-thang.herokuapp.com/">https://swap-thang.herokuapp.com/</a></small>
                    </div>
                </div>
                <div v-else>
                    <h1>Depositing {{lp.tokenInput}} Tokens</h1>
                    <h2>2 APPROVALS REQUIRED</h2>
                    <ul>
                        <li>Approve token contract call "approve" to use the function transferFrom</li>
                        <li>Approve survanas transferFrom call to actually take the funds</li>
                    </ul>
                </div>
            </template>
            <template v-slot:footer v-if="lp.approving">
                &nbsp;
            </template>
        </modal>

        <modal v-if="showStatus && status" @close="closeModal">
            <template v-slot:header>
                <h3>Status (ID #{{status.id}})</h3>
            </template>
            <template v-slot:body>
                <h2>Current Status: {{getStatus(status.status)}}</h2>
                <div class="row">
                    <div class="col-4">
                        <button type="button" class="w-100 btn btn-lg btn-success fs-1" @click="setStatus(0)" :disabled="status.status === '0'">EDIT</button>
                    </div>
                    <div class="col-4">
                        <button type="button" class="w-100 btn btn-lg btn-primary fs-1" @click="setStatus(1)" :disabled="status.status === '1'">OPEN</button>
                    </div>
                    <div class="col-4">
                        <button type="button" class="w-100 btn btn-lg btn-danger fs-1" @click="setStatus(2)" :disabled="status.status === '2'">CLOSE</button>
                    </div>
                </div>
            </template>
        </modal>
    </div>
</template>

<script>
import {mapMutations, mapState} from "vuex"
import Survey from "../../build/contracts-final/Survey.json"
import Modal from "./Modal"

export default {
    name: "Creator",
    components: {
        Modal,
    },
    data() {
        return {
            data: [],
            loading: false,
            page: 1,
            survey: {
                id: null,
                name: "",
                description: "",
                bonusAmount: 0,
            },
            questions: [],
            showLP: false,
            lp: {},
            showStatus: false,
            status: {},
            answers: [],
            ratings: ["0", "0.5", "1", "1.5", "2", "2.5", "3", "3.5", "4", "4.5", "5"]
        }
    },
    computed: {
        ...mapState(['walletAddress', 'userType', 'page', 'survanaContract', 'tokenContract', 'contractsLoaded']),
        textSurvey() {
            return this.survey.id !== null ? "Update" : "Add"
        }
    },
    mounted() {
        if (this.contractsLoaded) {
            this.getCreatorSurveys()
        }
    },
    watch: {
        contractsLoaded(v, ov) {
            if (v && !ov) {
                this.getCreatorSurveys()
            }
        },
        page(v, ov) {
            if (ov !== 1 && v === 1) {
                this.getCreatorSurveys()
            }
        }
    },
    methods: {
        ...mapMutations(['setUserType']),
        async seeReport(row) {
            this.survey = {
                id: row.id,
                name: row.name,
            }
            // console.log(row.addr)
            const loader = this.$loading.show({loader: "bars"})
            const survey = new web3.eth.Contract(Survey.abi, row.addr)
            const data = await survey.methods.getQuestions().call({from: this.walletAddress})
            // console.log(data)
            if (data.length > 0) {
                for(const index in data) {
                    const row = data[index]
                    this.questions.push({
                        id: index,
                        title: row.title,
                        type: row.questionType,
                        choices: row.choices,
                    })

                    //grab answers
                    try {
                        const array = await survey.methods.getAnswers(index).call({from: this.walletAddress})
                        if (+row.questionType < 2) {
                            const dat = {}
                            for(const a of array) {
                                const n = +a
                                if (typeof dat[n] === 'undefined') {
                                    dat[n] = 0
                                }
                                dat[n]++
                            }
                            this.answers[index] = dat
                        } else {
                            this.answers[index] = array
                        }
                    } catch (e) {
                        console.log(e)
                    }
                }
                // console.log(answers)
            }
            loader.hide()
            this.page = 3
        },
        fromWei(x) {
            return web3.utils.fromWei(""+x, "ether")
        },
        closeModal() {
            this.showLP = false
            this.showStatus = false
            this.getCreatorSurveys()
        },
        async setStatus(status) {
            const loader = this.$loading.show({loader: "bars"})
            try {
                const receipt = await this.survanaContract.methods.setSurveyStatus(this.status.id, status).send({from: this.walletAddress})
                console.log(receipt)
            } catch (e) {
                console.log(e)
            }
            this.status.status = ""+status;
            loader.hide()
        },
        openStatus(row) {
            this.status.id = row.id
            this.status.status = row.status
            this.showStatus = true
        },
        async refreshToken() {
            this.lp.tokenInput = ""
            this.lp.approving = false
            const bal = await this.getBalances()
            this.lp.tokenBalance = +bal.token
            let token = await this.tokenContract.methods.balanceOf(this.lp.address).call({from: this.walletAddress})
            this.lp.tokens = web3.utils.fromWei(""+token, "ether")
        },
        async refreshEth() {
            this.lp.ethInput = ""
            const bal = await this.getBalances()
            this.lp.ethBalance = +bal.eth
            let token = await web3.eth.getBalance(this.lp.address)
            this.lp.gas = web3.utils.fromWei(""+token, "ether")
        },
        async deposit(type) {
            if (type === "tokens") {
                if (!this.lp.tokenInput) {
                    alert("Must not be blank and greater than 0")
                    return
                }
                if(+this.lp.tokenInput > this.lp.tokenBalance) {
                    alert("You can't go above your balance")
                    return
                }
                this.lp.approving = true
                try {
                    const amount = web3.utils.toWei(""+this.lp.tokenInput, "ether")
                    let event = await this.tokenContract.methods.approve(this.lp.address, amount).send({from: this.walletAddress})
                    event = await this.survanaContract.methods.depositToSurveyTokenPool(this.lp.id, amount).send({from: this.walletAddress})
                    console.log(event)
                } catch(e) {
                    console.log(e)
                }
                await this.refreshToken()
            } else {
                if (!this.lp.ethInput) {
                    alert("Must not be blank and greater than 0")
                    return
                }
                if(+this.lp.ethInput > this.lp.ethBalance) {
                    alert("You can't go above your balance")
                    return
                }
                const loader = this.$loading.show({loader: "bars"})
                try {
                    let event = await this.survanaContract.methods.depositToSurveyGasPool(this.lp.id).send({from: this.walletAddress, value: web3.utils.toWei(""+this.lp.ethInput, "ether")})
                    console.log(event)
                } catch(e) {
                    console.log(e)
                }
                await this.refreshEth()
                loader.hide()
            }
        },
        async withdraw(type) {
            if (type === "tokens") {
                if (!this.lp.tokenInput) {
                    alert("Must not be blank and greater than 0")
                    return
                }
                if(+this.lp.tokenInput > +this.lp.tokens) {
                    alert("You can't go above the contracts amount")
                    return
                }
                const loader = this.$loading.show({loader: "bars"})
                try {
                    const amount = web3.utils.toWei(""+this.lp.tokenInput, "ether")
                    let event = await this.survanaContract.methods.withdrawFromTokenPool(this.lp.id, amount).send({from: this.walletAddress})
                    console.log(event)
                } catch(e) {
                    console.log(e)
                }
                await this.refreshToken()
                loader.hide()
            } else {
                if (!this.lp.ethInput) {
                    alert("Must not be blank and greater than 0")
                    return
                }
                if(+this.lp.ethInput > +this.lp.gas) {
                    alert("You can't go above the contracts amount")
                    return
                }
                const loader = this.$loading.show({loader: "bars"})
                try {
                    const amount = web3.utils.toWei(""+this.lp.ethInput, "ether")
                    let event = await this.survanaContract.methods.withdrawFromGasPool(this.lp.id, amount).send({from: this.walletAddress})
                    console.log(event)
                } catch(e) {
                    console.log(e)
                }
                await this.refreshEth()
                loader.hide()
            }
        },
        async getBalances() {
            let token = await this.tokenContract.methods.balanceOf(this.walletAddress).call({from: this.walletAddress})
            // console.log(token)
            token = web3.utils.fromWei(""+token, "ether")
            let eth = await web3.eth.getBalance(this.walletAddress)
            eth = web3.utils.fromWei(""+eth, "ether")
            return {token, eth}
        },
        async LiquidityPool(row) {
            this.lp.id = row.id
            this.lp.address = row.addr
            this.lp.tokens = web3.utils.fromWei(""+row.tokensLeft, "ether")
            this.lp.gas = web3.utils.fromWei(""+row.gasLeft, "ether")

            const bal = await this.getBalances()
            this.lp.tokenBalance = +bal.token
            this.lp.ethBalance = +bal.eth

            this.lp.tokenInput = ""
            this.lp.ethInput = ""
            this.lp.approving = false

            this.showLP = true
        },
        async saveQuestion(row) {
            if (!row.title || !row.description) {
                alert("Please fill in the name and/or description")
                return;
            }
            if (+row.type != 0) {
                row.choices = []
            }
            const loader = this.$loading.show({loader: "bars"})
            if (row.id !== null) {
                //update
                const args = [
                    this.survey.id,
                    row.id,
                    +row.type,
                    web3.utils.toWei(""+row.worth, 'ether'),
                    row.required,
                    row.title,
                    row.description,
                    row.choices
                ]
                console.log(args)
                try {
                    const receipt = await this.survanaContract.methods.updateQuestion(
                        ...args
                    ).send({from: this.walletAddress})
                    console.log(receipt)
                } catch (e) {
                    console.log(e)
                }
            } else {
                const args = [
                    this.survey.id,
                    +row.type,
                    web3.utils.toWei(""+row.worth, 'ether'),
                    row.required,
                    row.title,
                    row.description,
                    row.choices
                ]
                console.log(args)
                try {
                    const receipt = await this.survanaContract.methods.addQuestion(
                        ...args
                    ).send({from: this.walletAddress})
                    const event = receipt?.events?.QuestionAdded?.returnValues
                    console.log(receipt)
                    if (event) {
                        if (event._creator === this.walletAddress) {
                            row.id = event._questionId
                            console.log("Attached ID to Question", event._questionId)
                        }
                    }
                } catch (e) {
                    console.log(e)
                }
            }
            // loader
            loader.hide()
        },
        back() {
            this.page = 1
            this.questions = []
            this.answers = []
        },
        removeChoice(row, indx) {
            row.choices.splice(indx, 1)
        },
        addChoice(row) {
            row.choices.push("")
        },
        removeQuestion(index) {
            this.questions.splice(index, 1)
        },
        addQuestion() {
           this.questions.push({
               id: null,
               worth: 0,
               required: false,
               title: "",
               description: "",
               type: "0",
               choices: [],
           })
        },
        getStatus(status) {
            let ret
            switch(status) {
                case "0":
                    ret = "EDITING"
                    break
                case "1":
                    ret = "OPEN"
                    break
                case "2":
                    ret = "CLOSED"
                    break
            }
            return ret
        },
        async getCreatorSurveys() {
            this.data = [];
            this.loading = true
            // const loader = this.$loading.show({loader: 'bars'})
            try {
                this.data = await this.survanaContract.methods.getCreatorSurveys().call({from: this.walletAddress})
                // console.log(this.data)
            } catch (e) {
                console.log(e)
            }
            this.loading = false
            // loader.hide()
        },
        addSurvey() {
            this.survey = {
                id: null,
                name: "",
                description: "",
                bonusAmount: 0,
            }
            this.page = 2
        },
        async updateSurvey(row) {
            this.survey = {
                id: row.id,
                name: row.name,
                description: row.description,
                bonusAmount: web3.utils.fromWei(""+row.bonusAmount, 'ether').toString(),
            }
            this.page = 2
            //fetch the rest of the survey
            const loader = this.$loading.show({loader: "bars"})
            const survey = new web3.eth.Contract(Survey.abi, row.addr)
            const data = await survey.methods.getQuestions().call({from: this.walletAddress})
            // console.log(data)
            if (data.length > 0) {
                for(const index in data) {
                    const row = data[index]
                    this.questions.push({
                        id: index,
                        worth: web3.utils.fromWei(""+row.worth, 'ether').toString(),
                        required: row.required,
                        title: row.title,
                        description: row.description,
                        type: row.questionType,
                        choices: row.choices,
                    })
                }
            }
            console.log(data)
            loader.hide()
        },
        async submitSurvey() {
            if (!this.survey.name || !this.survey.description) {
                alert("Please fill in the name and/or description")
                return;
            }
            const loader = this.$loading.show({loader: "bars"})
            const amount = web3.utils.toWei(""+this.survey.bonusAmount, "ether")
            if (this.survey.id !== null) {
                //update
                try {
                    const receipt = await this.survanaContract.methods.updateSurvey(this.survey.id, this.survey.name, this.survey.description, amount).send({from: this.walletAddress})
                    console.log(receipt)
                } catch (e) {
                    console.log(e)
                }
            } else {
                //add
                try {
                    const receipt = await this.survanaContract.methods.createSurvey(this.survey.name, this.survey.description, amount).send({from: this.walletAddress})
                    const event = receipt?.events?.SurveyCreated?.returnValues
                    console.log(receipt)
                    if (event) {
                        if (event._creator === this.walletAddress) {
                            this.survey.id = event._surveyId
                            console.log("Attached ID to Survey", event._surveyId)
                        }
                    }
                } catch (e) {
                    console.log(e)
                }
            }
            // loader
            loader.hide()
        },
        async registerCreator() {
            const loader = this.$loading.show({loader: 'bars'})
            try {
                const receipt = await this.survanaContract.methods.addCreator(this.walletAddress).send({from: this.walletAddress})
                console.log(receipt)
                
                //check to see if they are a creator now
                const isCreator = await this.survanaContract.methods.creators(this.walletAddress).call({from: this.walletAddress})
                console.log(isCreator)
                if (isCreator) {
                    this.setUserType("creator")
                }
            } catch (e) {
                console.log(e)
            }
            loader.hide()
        },
    }

}
</script>

<style>

</style>