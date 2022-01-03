import { processErrorResponseAsync } from "../utils"
import { Constants } from "../utils";

const API_ENDPOINT = window.API_URL;

export default class CatalogService {

   async listItemsAsync(limit = 100) {
      var res = await fetch(`${API_ENDPOINT}/1.0/catalogitem?limit=${limit}`);
      if (res.ok) {
         return res.json();
      }
      else {
         throw new Error(await processErrorResponseAsync(res));
      }
   }

   async getItemByIdAsync(itemId) {
      var res = await fetch(`${API_ENDPOINT}/1.0/catalogitem/${itemId}`);

      if (res.ok) {
         return await res.json();
      }
      else {
         throw new Error(await processErrorResponseAsync(res));
      }
   }

   async deleteItemAsync(itemId) {
      var res = await fetch(`${API_ENDPOINT}/1.0/catalogitem/${itemId}`, {
         method: "DELETE"
      });

      console.log(res);

      if (res.status === 202) {
         // Accepted for processing.
         console.log("ok");
      }
      else if (res.ok) {
         console.log(res);
      }
      else {
         throw new Error(await processErrorResponseAsync(res));
      }
   }

}
