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

    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading activity...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load activity: {{ error.message }}</p>
    </div>

    <div v-if="data">
      <div v-for="event in data.activity.nodes" :key="event.id" class="box">
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
                <small class="has-text-grey">{{
                  new Date(event.createdAt).toLocaleString()
                }}</small>
              </p>
            </div>
          </div>
        </article>
      </div>

      <div v-if="data.activity.pageInfo.hasNextPage" class="has-text-centered mt-5">
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
import { ref, watch } from "vue";
import { useQuery } from "@/composables/useGraphQL";
import { GET_ACTIVITY } from "@/graphql/queries/resources";
import type { GetActivityQuery } from "@/types/graphql";

const feedType = ref<"GLOBAL" | "FOLLOWING">("GLOBAL");

const { data, loading, error, fetchMore, refetch } = useQuery<GetActivityQuery>(GET_ACTIVITY, {
  variables: () => ({ feedType: feedType.value, first: 25 })
});

watch(feedType, () => {
  refetch();
});

function loadMore() {
  if (!data.value) return;

  fetchMore(
    {
      feedType: feedType.value,
      first: 25,
      after: data.value.activity.pageInfo.endCursor
    },
    (prev, next) => ({
      activity: {
        ...next.activity,
        nodes: [...prev.activity.nodes, ...next.activity.nodes]
      }
    })
  );
}
</script>
