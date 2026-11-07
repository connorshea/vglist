<template>
  <FollowList kind="followers" :users="users" :loading="loading" :error="error" />
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useRoute } from "vue-router";
import { useQuery } from "@/composables/useGraphQL";
import { GET_USER_FOLLOWERS } from "@/graphql/queries/users";
import type { GetUserFollowersQuery } from "@/types/graphql";
import FollowList from "@/components/users/FollowList.vue";

const route = useRoute("userFollowers");

const { data, loading, error } = useQuery<GetUserFollowersQuery>(GET_USER_FOLLOWERS, {
  variables: () => ({ slug: route.params.slug, first: 50 })
});

const users = computed(() => data.value?.user?.followers.nodes ?? []);
</script>
