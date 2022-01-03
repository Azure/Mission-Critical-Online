<template>
   <div v-show="message !== ''">
      <p :class="type">{{ message }} <button @click="message = ''">❌ Dismiss</button></p>
   </div>
</template>

<script>
import { Constants } from "../utils"
import { EventBus } from "../main"

export default {
   data: () => ({
      type: "error",
      message: ""
   }),
   created() {
      EventBus.$on(Constants.EVENT_ERROR, data => {
         this.type = Constants.EVENT_ERROR;
         this.message = data;
      });

      EventBus.$on(Constants.EVENT_SUCCESS, data => {
         this.type = Constants.EVENT_SUCCESS;
         this.message = data;
      });
   },
   watch: {
      $route (to, from) {
         this.message = "";
      }
   }
}
</script>

<style scoped>
p {
   padding: 6pt;
   border-radius: 5px;
}

p.error {
   border: 1px solid rgb(255, 0, 0);
   background-color: rgb(255, 208, 208);
}

p.success {
   border: 1px solid rgb(0, 110, 0);
   background-color: rgb(181, 252, 181);
}
</style>