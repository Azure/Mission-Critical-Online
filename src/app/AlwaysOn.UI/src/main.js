import Vue from 'vue'
import VueRouter from 'vue-router'
import { ApplicationInsights } from '@microsoft/applicationinsights-web'

import App from './App.vue'
import components from "@/components"

import CatalogService from './services/catalog-service'
import CommentService from './services/comment-service'
import RatingService from './services/rating-service'

const appInsights = new ApplicationInsights(
{ 
   config: {
      instrumentationKey: window.APPINSIGHTS_INSTRUMENTATIONKEY,
      enableCorsCorrelation: true,
      enableRequestHeaderTracking: true,
      enableResponseHeaderTracking: true,
      disableFetchTracking: false,
      enableAutoRouteTracking: true
   } 
});

appInsights.loadAppInsights();
appInsights.trackPageView();

Vue.prototype.$CatalogService = new CatalogService()
Vue.prototype.$CommentService = new CommentService()
Vue.prototype.$RatingService = new RatingService()

export const EventBus = new Vue(); // global event bus to send events across components

Vue.config.productionTip = false

Vue.use(VueRouter);

const router = new VueRouter({
  routes: [
   {
      path: "/",
      name: "mainPage",
      component: components.MainPage
   },
   {
      path: "/catalog",
      name: "catalogPage",
      component: components.CatalogPage
   },
   {
      path: "/catalog/:itemId",
      name: "itemById",
      component: components.ItemPage
   }
  ]
});

new Vue({
  router,
  render: function (h) { return h(App) },
}).$mount('#app')
