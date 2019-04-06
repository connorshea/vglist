<template>
  <div class="game-library">
    <vue-good-table
      :columns="columns"
      :rows="rows"
      :sort-options="{
        enabled: true,
        initialSortBy: { field: 'rating', type: 'desc' }
      }"
    >
      <div slot="table-actions">
        <button
          v-if="isEditable"
          @click="activateModal({})"
          class="button mr-5"
        >Add a game to your library</button>
      </div>
      <template slot="table-row" slot-scope="props">
        <span v-if="props.column.field == 'after'">Actions</span>
        <span v-else-if="props.column.field == 'game.name'">
          <a :href="props.row.game_url">{{ props.row.game.name }}</a>
        </span>
        <span v-else-if="props.column.field == 'platforms'">
          <span v-for="platform in props.row.platforms" :key="platform.id">{{ platform.name }}</span>
        </span>
        <span v-else>{{ props.formattedRow[props.column.field] }}</span>
      </template>
      <div slot="emptystate" class="vgt-center-align">
        <span v-if="isLoading">Loading...</span>
        <span v-else class="vgt-text-disabled">This library is empty.</span>
      </div>
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
      isModalActive: false,
      currentGame: {},
      doesGamePurchaseExist: false,
      isLoading: true,
      columns: [
        {
          label: 'Name',
          field: 'game.name',
          type: 'text'
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
          field: 'completion_status.label',
          type: 'text'
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
          field: 'platforms',
          type: 'text'
        },
        {
          label: 'Comments',
          field: 'comments',
          type: 'text'
        }
      ],
      rows: []
    };
  },
  created: function() {
    this.loadGames();
    if (this.isEditable) {
      this.columns.push({
        label: 'Actions',
        field: 'after'
      });
    }
  },
  methods: {
    loadGames() {
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
          this.isLoading = false;
        });
    },
    refreshLibrary() {
      this.loadGames();
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
  }
};
</script>
