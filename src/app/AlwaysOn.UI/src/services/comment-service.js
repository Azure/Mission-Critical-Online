import { processErrorResponseAsync } from "../utils"

const API_ENDPOINT = window.API_URL;

export default class RatingService {
   
   async getCommentsByCatalogItemAsync(itemId) {
      var res = await fetch(`${API_ENDPOINT}/1.0/catalogitem/${itemId}/comments`);

      if (res.ok) {
         return await res.json();
      }
      else if (res.status === 404) {
         return 0;
      }
      else {
         throw new Error(await processErrorResponseAsync(res));
      }
   }

   async addItemComment(itemId, comment) {
      var res = await fetch(`${API_ENDPOINT}/1.0/catalogitem/${itemId}/comments`, {
         method: "POST",
         body: JSON.stringify({ authorName: comment.authorName, text: comment.text }),
         headers: [
            ["Content-Type", "application/json"]
         ]
      });

      if (res.status === 202) {
         // accepted for processing
         return 0;
      }
      else {
         throw new Error(await processErrorResponseAsync(res));
      }
   }
  
}