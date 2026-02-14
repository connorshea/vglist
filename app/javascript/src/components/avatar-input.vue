<template>
  <div class="avatar-form">
    <!-- Display errors if there are any. -->
    <div class="notification errors-notification is-danger" v-if="errors.length > 0">
      <p>{{ errors.length > 1 ? "Errors" : "An error" }} prevented your avatar from being saved:</p>
      <ul>
        <li v-for="error in errors" :key="error">{{ error }}</li>
      </ul>
    </div>
    <div class="field">
      <label class="label">Avatar</label>
      <!-- A dumb hack to display the user's current avatar if it exists. -->
      <div class="user-avatar" v-if="existingAvatar">
        <img :src="existingAvatar" width="150px" height="150px" />
      </div>
      <file-select
        v-model="avatar"
        @update:modelValue="onChange"
        :fileClass="'user-avatar'"
      ></file-select>
    </div>
    <div class="field">
      <button
        class="button is-primary mr-10 mr-0-mobile is-fullwidth-mobile js-submit-button"
        value="Submit"
        @click.prevent="onSubmit"
        :disabled="!hasSelectedFile"
      >
        Submit
      </button>
      <!-- Only display cancel button if file has been selected. -->
      <button
        v-if="hasSelectedFile"
        class="button mr-10 mr-0-mobile is-fullwidth-mobile"
        value="Cancel"
        @click.prevent="onCancel"
      >
        Cancel
      </button>
      <!-- Only disable 'remove' button if the user has an avatar and a file has not been selected. -->
      <button
        v-if="avatarPath && !hasSelectedFile"
        class="button is-danger mr-10 mr-0-mobile is-fullwidth-mobile"
        value="Remove avatar"
        @click.prevent="onDelete"
      >
        Remove avatar
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from "vue";
import FileSelect from "./fields/file-select.vue";
import VglistUtils from "../utils";
import { DirectUpload } from "@rails/activestorage";
import Turbolinks from "turbolinks";

type UserPayload = {
  user: {
    avatar?: string;
  };
};

interface Props {
  railsDirectUploadsPath: string;
  submitPath: string;
  deletePath: string;
  avatarPath?: string;
}

const props = defineProps<Props>();

const avatar = ref<File | undefined>(undefined);
const avatarBlob = ref<string | undefined>(undefined);
// If there's an avatar path prop, set the existingAvatar to it.
const existingAvatar = ref<string | undefined>(props.avatarPath);
const hasSelectedFile = ref(false);
const errors = ref<string[]>([]);

function onChange(file: File) {
  uploadFile(file);
  hasSelectedFile.value = true;
}

function uploadFile(file: File) {
  existingAvatar.value = undefined;
  const url = props.railsDirectUploadsPath;
  const upload = new DirectUpload(file, url, {
    directUploadWillStoreFileWithXHR: (xhr) => {
      // Use this workaround to make sure that Direct Upload-ed images are
      // uploaded with the correct header. Otherwise they will end up being
      // private files.
      xhr.setRequestHeader("x-amz-acl", "public-read");
    }
  });

  upload.create((error, blob) => {
    if (error) {
      // TODO: Handle this error.
      console.log(error);
    } else if (blob) {
      avatarBlob.value = blob.signed_id;
    }
  });
}

function onSubmit() {
  const submittableData: UserPayload = { user: {} };
  if (avatarBlob.value) {
    submittableData.user.avatar = avatarBlob.value;
  }

  VglistUtils.authenticatedFetch(props.submitPath, "PUT", JSON.stringify(submittableData))
    .then(() => {
      Turbolinks.visit(`${window.location.origin}/settings`);
    })
    .catch((errorsResp) => {
      errors.value = errorsResp;
      const submitButton = document.querySelector(".js-submit-button");
      if (submitButton) {
        submitButton.classList.add("js-submit-button-error");
        setTimeout(() => {
          submitButton.classList.remove("js-submit-button-error");
        }, 2000);
      }
    });
}

// TODO: Add a confirmation dialog before deleting.
function onDelete() {
  VglistUtils.authenticatedFetch(props.deletePath, "DELETE")
    .then(() => {
      Turbolinks.visit(`${window.location.origin}/settings`);
    })
    .catch((errorsResp) => {
      errors.value = errorsResp;
    });
}

// Reload the page on cancel.
function onCancel() {
  Turbolinks.visit(`${window.location.origin}/settings`);
}
</script>
