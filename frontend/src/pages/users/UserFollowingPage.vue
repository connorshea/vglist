<template>
  <FollowList kind="following" :users="users" :loading="loading" :error="error" />
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useRoute } from "vue-router";
import { useQuery } from "@/composables/useGraphQL";
import { GET_USER_FOLLOWING } from "@/graphql/queries/users";
import type { GetUserFollowingQuery } from "@/types/graphql";
import FollowList from "@/components/users/FollowList.vue";

const route = useRoute("userFollowing");

const { data, loading, error } = useQuery<GetUserFollowingQuery>(GET_USER_FOLLOWING, {
  variables: () => ({ slug: route.params.slug, first: 50 })
});

const users = computed(() => data.value?.user?.following.nodes ?? []);
</script>
