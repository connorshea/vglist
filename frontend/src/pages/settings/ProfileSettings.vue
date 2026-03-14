<template>
  <div>
    <h2 class="title is-4">Profile Settings</h2>

    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading profile...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load profile: {{ error.message }}</p>
    </div>

    <form v-if="data" @submit.prevent="saveProfile">
      <div class="field">
        <label class="label" for="bio">Bio</label>
        <div class="control">
          <textarea
            id="bio"
            v-model="bio"
            class="textarea"
            placeholder="Tell us about yourself..."
          ></textarea>
        </div>
      </div>

      <div class="field">
        <label class="label" for="privacy">Privacy</label>
        <div class="control">
          <div class="select">
            <select id="privacy" v-model="privacy">
              <option value="PUBLIC_ACCOUNT">Public</option>
              <option value="PRIVATE_ACCOUNT">Private</option>
            </select>
          </div>
        </div>
      </div>

      <div class="field">
        <div class="control">
          <label class="checkbox">
            <input type="checkbox" v-model="hideDaysPlayed" />
            Hide days played
          </label>
        </div>
      </div>

      <div v-if="saveError" class="notification is-danger">
        <p>{{ saveError }}</p>
      </div>

      <div v-if="saveSuccess" class="notification is-success">
        <p>Profile updated successfully.</p>
      </div>

      <div class="field">
        <div class="control">
          <button
            type="submit"
            class="button is-primary"
            :class="{ 'is-loading': saving }"
            :disabled="saving"
          >
            Save
          </button>
        </div>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { useQuery, useMutation } from '@/composables/useGraphQL'
import { UPDATE_USER } from '@/graphql/mutations/users'
import gql from 'graphql-tag'
import type { GetCurrentUserProfileData, UpdateUserData } from '@/types/graphql'

const GET_CURRENT_USER_PROFILE = gql`
  query GetCurrentUserProfile {
    currentUser {
      id
      bio
      privacy
      hideDaysPlayed
    }
  }
`

const bio = ref('')
const privacy = ref('PUBLIC_ACCOUNT')
const hideDaysPlayed = ref(false)
const saveError = ref('')
const saveSuccess = ref(false)

const { data, loading, error } = useQuery<GetCurrentUserProfileData>(GET_CURRENT_USER_PROFILE)

watch(data, (val) => {
  if (val?.currentUser) {
    bio.value = val.currentUser.bio ?? ''
    privacy.value = val.currentUser.privacy ?? 'PUBLIC_ACCOUNT'
    hideDaysPlayed.value = val.currentUser.hideDaysPlayed ?? false
  }
}, { immediate: true })

const { mutate, loading: saving } = useMutation<UpdateUserData>(UPDATE_USER)

async function saveProfile() {
  saveError.value = ''
  saveSuccess.value = false

  try {
    const response = await mutate({
      bio: bio.value,
      privacy: privacy.value,
      hideDaysPlayed: hideDaysPlayed.value,
    })

    const errors = response?.updateUser?.errors
    if (errors && errors.length > 0) {
      saveError.value = errors.join(', ')
    } else {
      saveSuccess.value = true
    }
  } catch (e) {
    saveError.value = e instanceof Error ? e.message : 'An unexpected error occurred.'
  }
}
</script>
