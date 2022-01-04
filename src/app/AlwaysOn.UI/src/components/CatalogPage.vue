<template>
   <section>
      <h1>Catalog</h1>

      <p v-show="loading">Loading...</p>

      <div v-show="items.length > 0">

         <div class="grid-container">
            <div v-for="item in items" v-bind:key="item.id" v-on:click="gotoDetail(item.id)" class="catalog-item">
               <img :src="item.imageUrl" width="200" /><br />
                  <strong>{{ item.name }}</strong> <br />
                  ${{ item.price }}
            </div>
         </div>

         <p>Showing {{items.length}} item{{ (items.length > 1) ? "s" : "" }}.</p>
      </div>

      <div v-show="!loading && items.length <= 0">
         <p>Nothing to show.</p>
      </div>
  </section>
</template>

<style scoped>
.grid-container {
   display: grid;
   grid-template-columns: repeat(3, 1fr);
   gap: 10px;
   grid-auto-rows: minmax(100px, auto);
}
.grid-container > div {
   cursor: pointer;
}
</style>

<script>
import { Constants } from "../utils"
import { EventBus } from "../main"

export default {
   data: function() {
      return {
         items: [],
         loading: false
      }
   },
   async created() {
      this.loading = true;

      try {
         this.items = await this.$CatalogService.listItemsAsync();
      }
      catch (e) {
         EventBus.$emit(Constants.EVENT_ERROR, "There was a problem fetching items. " + e.message);
      }
      this.loading = false;
   },
   methods: {
      gotoDetail(itemId) {
         this.$router.push({ name: 'itemById', params: { itemId: itemId }});
      },
      async deleteItem(itemId) {
         console.log("Removing: " + itemId);
         try {
            await this.$CatalogService.deleteCatalogItemAsync(itemId);
            EventBus.$emit(Constants.EVENT_SUCCESS, "Deletion accepted.");
         }
          catch (e) {
            EventBus.$emit(Constants.EVENT_ERROR, "Deleting item failed. " + e.message);
         }
      }
   }
}
</script>