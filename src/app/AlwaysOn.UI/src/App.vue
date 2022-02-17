<template>
  <div>
    <router-link :to="{ path: '/' }">Home</router-link> |
    <router-link :to="{ name: 'catalogPage' }">Catalog</router-link>

    <hr />

    <SystemMessage />

    <router-view :key="$route.fullPath"></router-view>
  
    <hr/>

    <footer>This is a reference implementation of <a href="https://github.com/Azure/AlwaysOn">Azure AlwaysOn</a>. Built in 2021-2022. Version: {{ versionLabel }}</footer>
  </div>
</template>

<script>
import SystemMessage from "./components/SystemMessage";

export default {
  data: function() {
     return {
        versionLabel: window.VERSION_LABEL
      }
  },
  created() { },
  methods: { },
  computed: { },
  components: {
    SystemMessage,
  },
};
</script>

<style>
footer {
   font-style: italic;
   font-size: 0.8em;
}
</style>
