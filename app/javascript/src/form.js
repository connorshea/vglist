import Vue from 'vue/dist/vue.esm';
import TextField from './components/text-field.vue';
import TextArea from './components/text-area.vue';

document.addEventListener('turbolinks:load', () => {
  let textField = document.getElementById("game-title-text-field")
  if (textField !== null) {
    const gameTitleTextField = new Vue({
      el: '#game-title-text-field',
      components: { TextField }
    })
  }

  let textArea = document.getElementById("game-description-text-area")
  if (textArea !== null) {
    const gameDescriptionTextArea = new Vue({
      el: '#game-description-text-area',
      components: { TextArea }
    })
  }
});
