<template>
    <div id="app" class="container py-4">
        <navbar></navbar>
        <survana></survana>
    </div>
</template>

<script>
import Navbar from './components/Navbar.vue'
import Survana from './components/Survana.vue'
export default {
    name: "App",
    components: {Navbar, Survana}
}
</script>

<style>

</style>