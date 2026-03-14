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

const { data } = useQuery(GET_BASIC_SITE_STATISTICS)

const stats = computed(() => {
  if (!data.value) return []
  const s = data.value.basicSiteStatistics
  return [
    { label: 'Games', value: s.gamesCount },
    { label: 'Users', value: s.usersCount },
    { label: 'Library Entries', value: s.gamePurchasesCount },
    { label: 'Platforms', value: s.platformsCount },
    { label: 'Companies', value: s.companiesCount },
    { label: 'Genres', value: s.genresCount },
    { label: 'Engines', value: s.enginesCount },
    { label: 'Series', value: s.seriesCount },
  ]
})
</script>
