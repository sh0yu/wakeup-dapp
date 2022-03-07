import { createApp } from 'vue'
import App from './App.vue'
import Datepicker from 'vue3-date-time-picker';
import 'vue3-date-time-picker/dist/main.css'
import "bootstrap/dist/js/bootstrap.bundle.min.js"
import "bootstrap/dist/css/bootstrap.min.css";
import "bootstrap";

createApp(App).component('Datepicker', Datepicker).mount('#app')
