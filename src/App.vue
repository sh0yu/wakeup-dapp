<template>
  <div class="bg-img pt-3 vh-100">
    <TopPage/>
  </div>
</template>

<script>
import TopPage from './components/TopPage.vue'

export default {
  name: 'App',
  components: {
    TopPage
  }
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
}
.bg-img {
  background-image: url("assets/background.jpeg");
}
</style>
