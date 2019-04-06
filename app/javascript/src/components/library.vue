<template>
  <div class="game-library">
    <!-- <game-in-library
      v-for="gameInLibrary in purchasedGames"
      :key="gameInLibrary.id"
      :gameInLibrary="gameInLibrary"
      :isEditable="isEditable"
      v-on:delete="refreshLibrary"
      v-on:edit="activateModal"
    ></game-in-library>-->

    <vue-good-table :columns="columns" :rows="rows">
      <div slot="table-actions">
        <button
          v-if="isEditable"
          @click="activateModal({})"
          class="button mt-10"
        >Add a game to your library</button>
      </div>
      <template slot="table-row" slot-scope="props">
        <span v-if="props.column.field == 'platforms'">
          <span v-for="platform in props.row.platforms" :key="platform.id">{{ platform.name }}</span>
        </span>
        <span v-else>{{props.formattedRow[props.column.field]}}</span>
      </template>
      <div slot="emptystate" class="vgt-center-align vgt-text-disabled">This library is empty.</div>
    </vue-good-table>

    <game-modal
      v-if="isModalActive"
      :isActive="isModalActive"
      :create="doesGamePurchaseExist"
      :userId="userId"
      v-bind="currentGame"
      v-on:close="deactivateModal"
      v-on:closeAndRefresh="closeAndRefresh"
      v-on:create="refreshLibrary"
    ></game-modal>
  </div>
</template>

<script>
import GameInLibrary from './game-in-library.vue';
import GameModal from './game-modal.vue';
import { VueGoodTable } from 'vue-good-table';
import 'vue-good-table/dist/vue-good-table.css';

export default {
  components: {
    GameInLibrary,
    GameModal,
    VueGoodTable
  },
  props: {
    gamePurchasesUrl: {
      type: String,
      required: true
    },
    isEditable: {
      type: Boolean,
      required: false,
      default: false
    },
    userId: {
      type: Number,
      required: true
    }
  },
  data: function() {
    return {
      purchasedGames: [],
      isModalActive: false,
      currentGame: {},
      doesGamePurchaseExist: false,
      columns: [
        {
          label: 'Name',
          field: 'game.name'
        },
        {
          label: 'Rating',
          field: 'rating',
          type: 'number'
        },
        {
          label: 'Hours Played',
          field: 'hours_played',
          type: 'decimal'
        },
        {
          label: 'Completion Status',
          field: 'completion_status.label'
        },
        {
          label: 'Start Date',
          field: 'start_date',
          type: 'date',
          dateInputFormat: 'YYYY-MM-DD',
          dateOutputFormat: 'MMMM D, YYYY'
        },
        {
          label: 'Completion Date',
          field: 'completion_date',
          type: 'date',
          dateInputFormat: 'YYYY-MM-DD',
          dateOutputFormat: 'MMMM D, YYYY'
        },
        {
          label: 'Platforms',
          field: 'platforms'
        },
        {
          label: 'Comments',
          field: 'comments'
        }
      ],
      rows: []
    };
  },
  created: function() {
    fetch(this.gamePurchasesUrl, {
      headers: {
        'Content-Type': 'application/json'
      }
    })
      .then(response => {
        return response.json().then(json => {
          if (response.ok) {
            return Promise.resolve(json);
          }
          return Promise.reject(json);
        });
      })
      .then(purchasedGames => {
        this.rows = purchasedGames;
      });
  },
  methods: {
    refreshLibrary() {
      fetch(this.gamePurchasesUrl, {
        headers: {
          'Content-Type': 'application/json'
        }
      })
        .then(response => {
          return response.json().then(json => {
            if (response.ok) {
              return Promise.resolve(json);
            }
            return Promise.reject(json);
          });
        })
        .then(purchasedGames => {
          this.rows = purchasedGames;
        });
    },
    activateModal(game = {}) {
      if (!this.isEditable) {
        return;
      }
      let html = document.querySelector('html');
      html.classList.add('is-clipped');

      this.doesGamePurchaseExist =
        Object.entries(game).length > 0 ? false : true;
      this.currentGame = game;
      this.isModalActive = true;
    },
    deactivateModal() {
      let html = document.querySelector('html');
      html.classList.remove('is-clipped');

      this.isModalActive = false;
    },
    closeAndRefresh() {
      this.deactivateModal();
      // Give it some time for the change to persist on the backend.
      setTimeout(() => {
        this.refreshLibrary();
      }, 750);
    }
  },
  computed: {
    libraryEmpty: function() {
      return this.rows.length === 0;
    }
  }
};
</script>
