import { ref, watch, onMounted, type Ref, isRef } from 'vue'
import type { DocumentNode } from 'graphql'
import { gqlClient } from '@/graphql/client'

type MaybeRefOrGetter<T> = T | Ref<T> | (() => T)

function resolveValue<T>(source: MaybeRefOrGetter<T>): T {
  if (isRef(source)) return source.value
  if (typeof source === 'function') return (source as () => T)()
  return source
}

interface UseQueryOptions<TVariables> {
  variables?: MaybeRefOrGetter<TVariables>
  enabled?: MaybeRefOrGetter<boolean>
}

interface UseQueryReturn<TData> {
  data: Ref<TData | null>
  loading: Ref<boolean>
  error: Ref<Error | null>
  refetch: () => Promise<void>
  fetchMore: (variables: Record<string, unknown>, merge: (prev: TData, next: TData) => TData) => Promise<void>
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function useQuery<TData = any, TVariables = Record<string, unknown>>(
  query: DocumentNode,
  options?: UseQueryOptions<TVariables>,
): UseQueryReturn<TData> {
  const data = ref<TData | null>(null) as Ref<TData | null>
  const loading = ref(false)
  const error = ref<Error | null>(null)

  async function execute() {
    if (options?.enabled !== undefined && !resolveValue(options.enabled)) return

    loading.value = true
    error.value = null

    try {
      const variables = options?.variables ? resolveValue(options.variables) : undefined
      data.value = await gqlClient.request<TData>(query, variables as Record<string, unknown>)
    } catch (e) {
      error.value = e instanceof Error ? e : new Error(String(e))
    } finally {
      loading.value = false
    }
  }

  async function fetchMore(
    variables: Record<string, unknown>,
    merge: (prev: TData, next: TData) => TData,
  ) {
    loading.value = true
    try {
      const nextData = await gqlClient.request<TData>(query, variables)
      if (data.value) {
        data.value = merge(data.value, nextData)
      } else {
        data.value = nextData
      }
    } catch (e) {
      error.value = e instanceof Error ? e : new Error(String(e))
    } finally {
      loading.value = false
    }
  }

  // Watch reactive variables and re-execute
  if (options?.variables && (isRef(options.variables) || typeof options.variables === 'function')) {
    const varsGetter = typeof options.variables === 'function'
      ? options.variables as () => TVariables
      : () => (options.variables as Ref<TVariables>).value

    watch(varsGetter, () => { execute() }, { deep: true })
  }

  // Watch enabled flag
  if (options?.enabled && (isRef(options.enabled) || typeof options.enabled === 'function')) {
    const enabledGetter = typeof options.enabled === 'function'
      ? options.enabled as () => boolean
      : () => (options.enabled as Ref<boolean>).value

    watch(enabledGetter, (val) => { if (val) execute() })
  }

  onMounted(() => { execute() })

  return { data, loading, error, refetch: execute, fetchMore }
}

interface UseMutationReturn<TData, TVariables> {
  mutate: (variables?: TVariables) => Promise<TData>
  data: Ref<TData | null>
  loading: Ref<boolean>
  error: Ref<Error | null>
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function useMutation<TData = any, TVariables = Record<string, unknown>>(
  mutation: DocumentNode,
): UseMutationReturn<TData, TVariables> {
  const data = ref<TData | null>(null) as Ref<TData | null>
  const loading = ref(false)
  const error = ref<Error | null>(null)

  async function mutate(variables?: TVariables): Promise<TData> {
    loading.value = true
    error.value = null

    try {
      const result = await gqlClient.request<TData>(mutation, variables as Record<string, unknown>)
      data.value = result
      return result
    } catch (e) {
      error.value = e instanceof Error ? e : new Error(String(e))
      throw e
    } finally {
      loading.value = false
    }
  }

  return { mutate, data, loading, error }
}
