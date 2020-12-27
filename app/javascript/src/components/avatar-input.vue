<template>
  <div class="avatar-form">
    <!-- Display errors if there are any. -->
    <div class="notification errors-notification is-danger" v-if="errors.length > 0">
      <p>
        {{ errors.length > 1 ? 'Errors' : 'An error' }} prevented your avatar from
        being saved:
      </p>
      <ul>
        <li v-for="error in errors" :key="error">{{ error }}</li>
      </ul>
    </div>
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
        class="button is-primary mr-10 mr-0-mobile is-fullwidth-mobile js-submit-button"
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

<script lang="ts">
import FileSelect from './fields/file-select.vue';
import VglistUtils from '../utils';
import { DirectUpload } from '@rails/activestorage';
import Turbolinks from 'turbolinks';

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
      hasSelectedFile: false,
      errors: []
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
      const upload = new DirectUpload(file, url, {
        directUploadWillStoreFileWithXHR: (xhr) => {
          // Use this workaround to make sure that Direct Upload-ed images are
          // uploaded with the correct header. Otherwise they will end up being
          // private files.
          xhr.setRequestHeader('x-amz-acl', 'public-read');
        }
      });

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

      VglistUtils.authenticatedFetch(
        this.submitPath,
        'PUT',
        JSON.stringify(submittableData)
      ).then(game => {
        Turbolinks.visit(`${window.location.origin}/settings`);
      }).catch(errors => {
        this.errors = errors;
        let submitButton = document.querySelector('.js-submit-button');
        submitButton.classList.add('js-submit-button-error');
        setTimeout(() => {
          submitButton.classList.remove('js-submit-button-error');
        }, 2000);
      });
    },
    onDelete() {
      VglistUtils.authenticatedFetch(
        this.deletePath,
        'DELETE'
      ).then(game => {
        Turbolinks.visit(`${window.location.origin}/settings`);
      }).catch(errors => {
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
