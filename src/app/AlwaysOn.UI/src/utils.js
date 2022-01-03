export const Constants = {
   EVENT_ERROR: "error",
   EVENT_SUCCESS: "success",
}

export async function processErrorResponseAsync(httpResponse) {
   
   if (httpResponse == null) {
      return "Error when sending request. API not available.";
   }

   // Forbidden when trying to access the API method.
   if (httpResponse.status === 403) {
      return `Not authorized to perform this operation. (HTTP ${httpResponse.status})`;
   }

   // ASP.NET Core generated rich error response.
   var contentType = httpResponse.headers.get("Content-Type");
   if (contentType && contentType.indexOf("application/problem+json") > -1) {
      
      var out = "";
      var resJson = await httpResponse.json();
      if (resJson.errors) {
         out += JSON.stringify(resJson.errors);
      }
      else {
         out += httpResponse.statusText;
      }

      out += ` (HTTP ${httpResponse.status})`;
      return out;
   }

   // Final "catch all" other cases.
   return `${await httpResponse.text()} (HTTP: ${httpResponse.status})`;
}