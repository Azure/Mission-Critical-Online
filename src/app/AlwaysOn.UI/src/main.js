import { createApp } from 'vue'
import { createRouter, createWebHashHistory } from 'vue-router'
import { ApplicationInsights } from '@microsoft/applicationinsights-web'
import emitter from 'tiny-emitter/instance'

import App from './App.vue'
import components from "@/components"

import CatalogService from './services/catalog-service'
import CommentService from './services/comment-service'
import RatingService from './services/rating-service'

const appInsights = new ApplicationInsights(
{
   config: {
      connectionString: window.APPLICATIONINSIGHTS_CONNECTION_STRING,
      enableCorsCorrelation: true,
      enableRequestHeaderTracking: true,
      enableResponseHeaderTracking: true,
      disableFetchTracking: false,
      enableAutoRouteTracking: true
   }
});

appInsights.loadAppInsights();
appInsights.trackPageView();

const app = createApp(App);

app.config.globalProperties.$CatalogService = new CatalogService();
app.config.globalProperties.$CommentService = new CommentService();
app.config.globalProperties.$RatingService = new RatingService();

// global event bus to send events across components
// migrated to emitter based on https://v3.vuejs.org/guide/migration/events-api.html#event-bus
export const EventBus = {
   $on: (...args) => emitter.on(...args),
   $once: (...args) => emitter.once(...args),
   $off: (...args) => emitter.off(...args),
   $emit: (...args) => emitter.emit(...args)
}

const router = createRouter({
   history: createWebHashHistory(),
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

app.use(router).mount("#app");