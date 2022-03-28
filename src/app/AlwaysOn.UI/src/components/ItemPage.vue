<template>
   <section>
      
      <p v-show="loading">Loading...</p>
      
      <div v-if="!loading && item != null">
         <div class="grid-container">
            <img :src="item.imageUrl" width="540" />
            <div>
               <h1>{{ item.name }}</h1>
               <p>{{ item.description }}</p>
               <p>Price: ${{ item.price }}</p>
               <p>Rating: {{ Math.round(item.rating.averageRating * 10)/10 }} ({{ item.rating.numberOfVotes }} vote{{ (item.rating.numberOfVotes > 1 || item.rating.numberOfVotes == 0) ? "s" : "" }})</p>
               <p class="rating-buttons" v-if="!ratedYet">
                  <button v-on:click="rate(1)" :disabled="ratedYet" id="rating-1">1</button>
                  <button v-on:click="rate(2)" :disabled="ratedYet" id="rating-2">2</button>
                  <button v-on:click="rate(3)" :disabled="ratedYet" id="rating-3">3</button>
                  <button v-on:click="rate(4)" :disabled="ratedYet" id="rating-4">4</button>
                  <button v-on:click="rate(5)" :disabled="ratedYet" id="rating-5">5</button>
               </p>
            </div>
         </div>

         <h2>Comments</h2>

         <div>
            <table>
               <tr>
                  <td>Your name:</td>
                  <td><input v-model="newComment.authorName" id="comment-authorName" /></td>
               </tr>
               <tr>
                  <td>Comment:</td>
                  <td colspan="2"><textarea v-model="newComment.text" cols="30" rows="10" id="comment-text"></textarea></td>
               </tr>
               <tr>
                  <td></td>
                  <td><button v-on:click="postComment()" id="submit-comment">Send</button></td>
               </tr>
            </table>
         </div>

         <div v-for="comment in item.comments" v-bind:key="comment.id" class="comment-box">
            <p>{{ comment.text }}</p>
            <p class="name">{{ comment.authorName }} | {{ new Date(comment.creationDate).toLocaleString() }}</p>
         </div>
      </div>

   </section>
</template>

<style scoped>
td:first-child {
   font-weight: bold;
}

.grid-container {
   display: grid;
   grid-template-columns: 1fr 1fr;
   gap: 10px;
   grid-auto-rows: minmax(100px, auto);
}

.comment-box {
   border: 2px dashed rgb(233, 233, 233);
   padding: 8px;
}
.comment-box .name {
   font-size: 9pt
}

.rating-buttons > button {
   margin: 4px;
}

</style>

<script>
import { Constants } from '../utils';
import { EventBus } from "../main"

export default {
   data: function() {
      return {
         item: {
            name: "",
            imageUrl: "",
            description: "",
            price: "",
            rating: "Loading...",
            comments: []
         },
         newComment: {
            authorName: "",
            text: ""
         },
         loading: false,
         ratedYet: false
      }
   },
   methods: {
      async postComment() {
         try {
            // send comment to the service
            await this.$CommentService.addItemComment(this.item.id, this.newComment);
            
            // add the comment to the list immediately (fake the date)
            this.newComment.creationDate = new Date();
            this.item.comments.unshift(this.newComment);
            
            // cleanup for next comment
            this.newComment = {
               authorName: "",
               text: ""
            }
         }
         catch (e) {
            EventBus.$emit(Constants.EVENT_ERROR, "There was a problem posting the comment. " + e.message);
         }
      },
      async rate(rating) {
         try {
            await this.$RatingService.addItemRating(this.item.id, rating);
            this.ratedYet = true;
            this.item.rating = await this.$RatingService.getRatingByCatalogItemAsync(this.item.id); // get updated rating
            this.$forceUpdate(); // reload components with new data
         }
         catch (e) {
            EventBus.$emit(Constants.EVENT_ERROR, "There was a problem posting the rating. " + e.message);
         }
      }
   },
   async created() {
      this.loading = true;
      try {
         const itemId = this.$route.params.itemId;
         if (itemId == null) {
            EventBus.$emit(Constants.EVENT_ERROR, "Item ID is required.");
         }
         else {
            this.item = await this.$CatalogService.getItemByIdAsync(itemId);
            this.item.rating = await this.$RatingService.getRatingByCatalogItemAsync(this.item.id);
            this.item.comments = await this.$CommentService.getCommentsByCatalogItemAsync(this.item.id);
         }
      }
      catch (e) {
         EventBus.$emit(Constants.EVENT_ERROR, "There was a problem fetching the item. " + e.message);
      }

      this.loading = false;
   }
}
</script>