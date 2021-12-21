<template>
   <section>
      <section v-if="!$AuthService.activeAccount">
         <p>You need to log in to play.</p>
      </section>
      
      <section v-if="$AuthService.activeAccount">

         <h1>Let's play!</h1>
         
         <h2>Pick your hero:</h2>

         <div style="font-size: 26pt; text-align: center">

            <li v-bind:class="[picked == 'rock' ? 'selected' : '']">
               <input type="radio" id="rock" name="gesture" value="rock" v-model="picked" >
               <label for="rock">🗿<br/>Rock</label>
            </li>
            <li v-bind:class="[picked == 'paper' ? 'selected' : '']">
               <input type="radio" id="paper" name="gesture" value="paper" v-model="picked">
               <label for="paper">📜<br/>Paper</label>
            </li>
            <li v-bind:class="[picked == 'scissors' ? 'selected' : '']">
               <input type="radio" id="scissors" name="gesture" value="scissors" v-model="picked">
               <label for="scissors">✂️<br/>Scissors</label>
            </li>
            <li v-bind:class="[picked == 'lizard' ? 'selected' : '']">
               <input type="radio" id="lizard" name="gesture" value="lizard" v-model="picked">
               <label for="lizard">🦎<br/>Lizard</label>
            </li>
            <li v-bind:class="[picked == 'spock' ? 'selected' : '']">
               <input type="radio" id="spock" name="gesture" value="spock" v-model="picked">
               <label for="spock">🖖<br/>Spock</label>
            </li>
            <li v-bind:class="[picked == 'ferrari' ? 'selected' : '']" v-if="showExtraItem">
               <input type="radio" id="ferrari" name="gesture" value="ferrari" v-model="picked">
               <label for="ferrari">🚗<br/>Ferrari</label>
            </li>

            <hr />

            <table style="width: 30%; text-align: left; border: 2px solid grey; border-radius: 5px; margin: auto;">
               <tr>
                  <td style="width: 20%; text-align: center" rowspan="5">
                     <p>{{ playerGesture.icon }}</p>
                     <p style="font-size: 10pt">{{ playerGesture.name }}</p>
                  </td>
                  <td style="width: 20%; text-align: center" rowspan="5">
                     vs.
                  </td>
                  <td style="width: 20%; text-align: center" rowspan="5">
                     <p>{{ opponentGesture.icon }}</p>
                     <p style="font-size: 10pt">{{ opponentGesture.name }}</p>
                  </td>
               </tr>
            </table>

            <button class="play" v-on:click="calculateGame" :disabled="gameRunning">GO!</button>

            <p>&nbsp;{{ result }}</p>
         </div>
      </section>
  </section>
</template>

<style scoped>

input[type="radio"] {
   margin-left: 20px;
   display: none;
}

/* Global table style overrides. */
td {
   border: none;
}
table tr:nth-child(odd) {
  background: none;
}
table tr:nth-child(even) {
  background: none;
}

/* Pick your hero buttons */
li
{
    padding: 10px;
    list-style-type: none;
    display: inline-block;
}

li.selected
{
    background: #eee;
    color: #333;
}

</style>

<script>
import { Constants } from "../utils"
import { EventBus } from "../main"

const extraTxt = "IHRocmVlIHRpbWVzIGluIGEgcm93LiBZb3UgbXVzdCBiZSBhIEZlcnJhcmkgZHJpdmVyLg==";

const gestureIcons = [
   { "name": "rock", "icon": "🗿" },
   { "name": "paper", "icon": "📜" },
   { "name": "scissors", "icon": "✂️" },
   { "name": "lizard", "icon": "🦎" },
   { "name": "spock", "icon": "🖖" },
   { "name": "ferrari", "icon": "🚗" },
]

export default {
   data: function() {
      return {
         opponentGesture: {"icon": "?"},
         result: "",
         picked: "rock",
         gameRunning: false,
         showExtraItem: false,
         losingStreakLength: 0
      }
   },
   computed: {
    playerGesture() {
       return gestureIcons.find(i => i.name == this.picked)
    }
   },
   methods: {
      async calculateGame() {
         this.result = "Thinking..."
         this.gameRunning = true;
         var turnResult = {};

         try {
            // Running in parallel: send result to the API & show the "calculating" animation.
            let sendToApi = new Promise((resolve) => resolve(this.$GameService.playAiGame(this.picked)));
            
            let showAnimation = new Promise(async (resolve) => {
               for (var i = 0; i < 20; i++) {
                  this.opponentGesture = gestureIcons[this.$GameLogic.getRndInteger(0, gestureIcons.length - 1)];
                  await (new Promise(res => setTimeout(res, 50)));
               }
               
               resolve();
            });

            var res = await Promise.all([sendToApi, showAnimation]);
            // sendToApi is the first Promise, if anything went wrong this will throw an error
            turnResult.aiGesture = res[0].playerGestures[1].gesture.toLowerCase();
            turnResult.winner = res[0].winningPlayerId;
            
            this.picked = res[0].playerGestures[0].gesture.toLowerCase(); // reset user choice too, based on server response
         }
         catch (e) {
            EventBus.$emit(Constants.EVENT_ERROR, "Sending game result failed. " + e.message);
         }
         
         this.opponentGesture = gestureIcons.find(i => i.name == turnResult.aiGesture);

         if (turnResult.winner == "00000000-0000-0000-0000-000000000000") {
            this.result = "It's a tie 😐";
            this.losingStreakLength = 0;
         }
         else if (turnResult.winner === this.$AuthService.activeAccount.localAccountId) {
            this.result = "You won 😀";
            this.losingStreakLength = 0;
         }
         else {
            this.result = "You lost 😪";
            this.losingStreakLength++;
         }

         this.gameRunning = false;

         if(this.losingStreakLength == 3) {
            this.showExtraItem = true;
            this.result += atob(extraTxt);
         }
      }
   }
}
</script>