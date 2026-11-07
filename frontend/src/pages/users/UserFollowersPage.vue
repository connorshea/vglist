<template>
  <FollowList
    kind="followers"
    :users="users"
    :loading="loading"
    :error="error"
    :page="page"
    :has-next-page="hasNextPage"
    @go-to-page="goToPage"
  />
</template>

<script setup lang="ts">
import { useRoute } from "vue-router";
import { useFollowList } from "@/composables/useFollowList";
import { GET_USER_FOLLOWERS } from "@/graphql/queries/users";
import type { GetUserFollowersQuery } from "@/types/graphql";
import FollowList from "@/components/users/FollowList.vue";

const route = useRoute("userFollowers");

const { users, loading, error, page, hasNextPage, goToPage } = useFollowList<GetUserFollowersQuery>(
  GET_USER_FOLLOWERS,
  { slug: () => route.params.slug, select: (data) => data.user?.followers }
);
</script>
