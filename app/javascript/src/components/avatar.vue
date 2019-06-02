<template>
  <div class="avatar-form">
    <div class="field">
      <file-select :label="'Avatar'" v-model="avatar" @input="onChange" :fileClass="'avatar'"></file-select>
    </div>
    <div class="field">
      <button
        class="button is-primary mr-10 mr-0-mobile is-fullwidth-mobile"
        value="Submit"
        @click.prevent="onSubmit"
      >Submit</button>
      <button
        class="button is-danger mr-10 mr-0-mobile is-fullwidth-mobile"
        value="Remove avatar"
        @click.prevent="onDelete"
      >Remove avatar</button>
    </div>
  </div>
</template>

<script>
import FileSelect from './fields/file-select.vue';
import Rails from 'rails-ujs';
import { DirectUpload } from 'activestorage';

export default {
  name: 'games-filter',
  components: {
    FileSelect
  },
  props: {
    railsDirectUploadsPath: {
      type: String,
      required: true
    },
    submitPath: {
      type: String,
      required: true
    },
    deletePath: {
      type: String,
      required: true
    }
  },
  data: function() {
    return {
      avatar: null,
      avatarBlob: null
    };
  },
  methods: {
    onChange(file) {
      this.uploadFile(file);
    },
    uploadFile(file) {
      const url = this.railsDirectUploadsPath;
      const upload = new DirectUpload(file, url);

      upload.create((error, blob) => {
        if (error) {
          // TODO: Handle this error.
          console.log(error);
        } else {
          this.avatarBlob = blob.signed_id;
        }
      });
    },
    onSubmit() {
      if (this.avatarBlob) {
        submittableData['user']['avatar'] = this.avatarBlob;
      }

      fetch(this.submitPath, {
        method: 'POST',
        body: JSON.stringify(submittableData),
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': Rails.csrfToken(),
          Accept: 'application/json'
        },
        credentials: 'same-origin'
      })
        .then(response => {
          return response.json().then(json => {
            if (response.ok) {
              return Promise.resolve(json);
            }
            return Promise.reject(json);
          });
        })
        .then(game => {
          Turbolinks.visit(`${window.location.origin}/settings`);
        })
        .catch(errors => {
          this.errors = errors;
        });
    },
    onDelete() {
      fetch(this.deletePath, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': Rails.csrfToken(),
          Accept: 'application/json'
        },
        credentials: 'same-origin'
      })
        .then(response => {
          return response.json().then(json => {
            if (response.ok) {
              return Promise.resolve(json);
            }
            return Promise.reject(json);
          });
        })
        .then(game => {
          Turbolinks.visit(`${window.location.origin}/settings`);
        })
        .catch(errors => {
          this.errors = errors;
        });
    }
  }
};
</script>
