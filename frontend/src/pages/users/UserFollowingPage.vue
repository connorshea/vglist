<template>
  <FollowList
    kind="following"
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
import { GET_USER_FOLLOWING } from "@/graphql/queries/users";
import type { GetUserFollowingQuery } from "@/types/graphql";
import FollowList from "@/components/users/FollowList.vue";

const route = useRoute("userFollowing");

const { users, loading, error, page, hasNextPage, goToPage } = useFollowList<GetUserFollowingQuery>(
  GET_USER_FOLLOWING,
  { slug: () => route.params.slug, select: (data) => data.user?.following }
);
</script>
