import { processErrorResponseAsync } from "../utils"

const API_ENDPOINT = window.API_URL;

export default class RatingService {
   
   async getRatingByCatalogItemAsync(itemId) {
      var res = await fetch(`${API_ENDPOINT}/1.0/catalogitem/${itemId}/ratings`);

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

   async addItemRating(itemId, rating) {
      var res = await fetch(`${API_ENDPOINT}/1.0/catalogitem/${itemId}/ratings`, {
         method: "POST",
         headers: [
            ["Content-Type", "application/json"]
         ],
         body: JSON.stringify({ rating: rating })
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