<template>
  <div>
    <section class="hero is-medium is-primary">
      <div class="hero-body">
        <p class="title">vglist</p>
        <p class="subtitle">Track your video game library</p>
      </div>
    </section>

    <section class="section" v-if="data">
      <div class="columns is-multiline">
        <div class="column is-3" v-for="stat in stats" :key="stat.label">
          <div class="box has-text-centered">
            <p class="heading">{{ stat.label }}</p>
            <p class="title">{{ stat.value.toLocaleString() }}</p>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useQuery } from '@/composables/useGraphQL'
import { GET_BASIC_SITE_STATISTICS } from '@/graphql/queries/resources'
import type { GetBasicSiteStatisticsQuery } from '@/types/graphql'

const { data } = useQuery<GetBasicSiteStatisticsQuery>(GET_BASIC_SITE_STATISTICS)

const stats = computed(() => {
  if (!data.value) return []
  const s = data.value.basicSiteStatistics
  return [
    { label: 'Games', value: s.games },
    { label: 'Platforms', value: s.platforms },
    { label: 'Companies', value: s.companies },
    { label: 'Genres', value: s.genres },
    { label: 'Engines', value: s.engines },
    { label: 'Series', value: s.series },
  ]
})
</script>
