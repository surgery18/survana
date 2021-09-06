<template>
    <div>
        <div v-if="page === 0">
            <surveys></surveys>
        </div>
        <div v-else-if="page === 1">
           <creator></creator>
        </div>
        <div v-else-if="page === 2">
        </div>
        <div v-else>
        </div>
    </div>
</template>

<script>
import Web3 from "web3"
import {mapMutations, mapState} from "vuex"
import Token from "../../build/contracts/Token.json"
import Survana from "../../build/contracts/Survana.json"
import Survey from "../../build/contracts/Survey.json"
import Creator from './Creator.vue'
import Surveys from './Surveys.vue'

export default {
    name: "Survana",
    components: { Creator, Surveys },
    async created() {
        const loader = this.$loading.show({loader: 'bars'})
        //init web3
        if (window.ethereum) {
            window.web3 = new Web3(window.ethereum)
            await window.ethereum.enable()
        }
        else if (window.web3) {
            window.web3 = new Web3(window.web3.currentProvider)
        }
        else {
            window.alert('Non-Ethereum browser detected. You should consider trying MetaMask!')
        }

        //get accounts
        const accounts = await web3.eth.getAccounts()
        const walletAddress = accounts[0]

        this.setAddress(walletAddress)

        //get network id
        const nid = await web3.eth.net.getId()
        console.log("Network ID is", nid)

        this.setTokenContract(new web3.eth.Contract(Token.abi, "0x93DAcc9cA3CfAdA36Cd927223521fA7715351812"))

        const std = Survana.networks[nid]
        if (std) {
            this.setSurvanaContract(new web3.eth.Contract(Survana.abi, std.address))
        } else {
            // alert("SwapThang contract not found on network id")
            this.loading = false;
            return
        }

        //find out if they are the owner?
        const owner = await this.survanaContract.methods.owner().call({from: this.walletAddress})
        console.log(owner, walletAddress)
        if (owner.toString() === walletAddress.toString()) {
            this.setUserType('owner')
        } else {
            //no, creator?
            const isCreator = await this.survanaContract.methods.creators(walletAddress).call({from: this.walletAddress})
            console.log(isCreator)
            if (isCreator) {
                this.setUserType("creator")
            } else {
                this.setUserType("user")
            }

        }
        loader.hide()
        this.setContractLoaded(true)

        // console.log(this.survanaContract)
    },
    computed: {
        ...mapState(['walletAddress', 'userType', 'page', 'survanaContract', 'tokenContract'])
    },
    methods: {
        ...mapMutations(['setAddress', 'setUserType', 'setSurvanaContract', 'setTokenContract', 'setContractLoaded']),
    }
}
</script>

<style>

</style>