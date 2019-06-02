<template>
  <div class="avatar-form">
    <div class="field">
      <label class="label">Avatar</label>
      <!-- A dumb hack to display the user's current avatar if it exists. -->
      <div class="user-avatar" v-if="existingAvatar">
        <img :src="existingAvatar" width="150px" height="150px">
      </div>
      <file-select v-model="avatar" @input="onChange" :fileClass="'user-avatar'"></file-select>
    </div>
    <div class="field">
      <button
        class="button is-primary mr-10 mr-0-mobile is-fullwidth-mobile"
        value="Submit"
        @click.prevent="onSubmit"
        :disabled="!hasSelectedFile"
      >Submit</button>
      <!-- Only display cancel button if file has been selected. -->
      <button
        v-if="hasSelectedFile"
        class="button mr-10 mr-0-mobile is-fullwidth-mobile"
        value="Cancel"
        @click.prevent="onCancel"
      >Cancel</button>
      <!-- Only disable 'remove' button if the user has an avatar and a file has not been selected. -->
      <button
        v-if="avatarPath && !hasSelectedFile"
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
  name: 'avatar-input',
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
    },
    avatarPath: {
      type: String,
      required: false
    }
  },
  data: function() {
    return {
      avatar: null,
      avatarBlob: null,
      existingAvatar: null,
      hasSelectedFile: false
    };
  },
  created: function() {
    // If there's an avatar path prop, set the existingAvatar to it.
    if (this.avatarPath) {
      this.existingAvatar = this.avatarPath;
    }
  },
  methods: {
    onChange(file) {
      this.uploadFile(file);
      this.hasSelectedFile = true;
    },
    uploadFile(file) {
      this.existingAvatar = null;
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
      let submittableData = { user: {} };
      if (this.avatarBlob) {
        submittableData['user']['avatar'] = this.avatarBlob;
      }

      fetch(this.submitPath, {
        method: 'PUT',
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
    },
    // Reload the page on cancel.
    onCancel() {
      Turbolinks.visit(`${window.location.origin}/settings`);
    }
  }
};
</script>
