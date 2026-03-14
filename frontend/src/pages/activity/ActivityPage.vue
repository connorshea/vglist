<template>
  <section class="section">
    <h1 class="title">Activity</h1>

    <div class="tabs">
      <ul>
        <li :class="{ 'is-active': feedType === 'GLOBAL' }">
          <a @click="feedType = 'GLOBAL'">Global</a>
        </li>
        <li :class="{ 'is-active': feedType === 'FOLLOWING' }">
          <a @click="feedType = 'FOLLOWING'">Following</a>
        </li>
      </ul>
    </div>

    <div v-if="loading && !result" class="has-text-centered">
      <p>Loading activity...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load activity: {{ error.message }}</p>
    </div>

    <div v-if="result">
      <div
        v-for="event in result.activity.nodes"
        :key="event.id"
        class="box"
      >
        <article class="media">
          <figure class="media-left" v-if="event.user.avatarUrl">
            <p class="image is-48x48">
              <img class="is-rounded" :src="event.user.avatarUrl" :alt="event.user.username" />
            </p>
          </figure>
          <div class="media-content">
            <div class="content">
              <p>
                <strong>
                  <router-link :to="`/users/${event.user.slug}`">
                    {{ event.user.username }}
                  </router-link>
                </strong>
                <span class="has-text-grey ml-2">{{ event.eventCategory }}</span>
                <br />
                <small class="has-text-grey">{{ new Date(event.createdAt).toLocaleString() }}</small>
              </p>
            </div>
          </div>
        </article>
      </div>

      <div
        v-if="result.activity.pageInfo.hasNextPage"
        class="has-text-centered mt-5"
      >
        <button
          class="button is-primary"
          :class="{ 'is-loading': loading }"
          :disabled="loading"
          @click="loadMore"
        >
          Load More
        </button>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { useQuery } from '@vue/apollo-composable'
import { GET_ACTIVITY } from '@/graphql/queries/resources'

const feedType = ref<'GLOBAL' | 'FOLLOWING'>('GLOBAL')

const { result, loading, error, fetchMore, refetch } = useQuery(GET_ACTIVITY, () => ({
  feedType: feedType.value,
  first: 25,
}))

watch(feedType, () => {
  refetch()
})

function loadMore() {
  fetchMore({
    variables: {
      feedType: feedType.value,
      first: 25,
      after: result.value.activity.pageInfo.endCursor,
    },
    updateQuery(previousResult, { fetchMoreResult }) {
      if (!fetchMoreResult) return previousResult

      return {
        activity: {
          ...fetchMoreResult.activity,
          nodes: [
            ...previousResult.activity.nodes,
            ...fetchMoreResult.activity.nodes,
          ],
        },
      }
    },
  })
}
</script>
