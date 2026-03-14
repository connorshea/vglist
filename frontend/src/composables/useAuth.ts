import { useMutation } from '@vue/apollo-composable'
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'
import { SIGN_IN, SIGN_UP, REQUEST_PASSWORD_RESET } from '@/graphql/mutations/auth'
import { apolloClient } from '@/graphql/client'

export function useAuth() {
  const authStore = useAuthStore()
  const router = useRouter()

  async function signIn(email: string, password: string) {
    const { data, errors } = await apolloClient.mutate({
      mutation: SIGN_IN,
      variables: { email, password },
    })

    if (errors?.length) {
      return { success: false, errors: errors.map((e) => e.message) }
    }

    const result = data.signIn
    if (result.errors.length > 0) {
      return { success: false, errors: result.errors }
    }

    authStore.setAuth(result.token, {
      id: result.user.id,
      username: result.user.username,
      email,
      role: result.user.role.toLowerCase(),
      slug: result.user.slug,
    })

    return { success: true, errors: [] }
  }

  async function signUp(
    username: string,
    email: string,
    password: string,
    passwordConfirmation: string,
  ) {
    const { data, errors } = await apolloClient.mutate({
      mutation: SIGN_UP,
      variables: { username, email, password, passwordConfirmation },
    })

    if (errors?.length) {
      return { success: false, errors: errors.map((e) => e.message) }
    }

    const result = data.signUp
    if (result.errors.length > 0) {
      return { success: false, errors: result.errors }
    }

    return { success: true, errors: [] }
  }

  async function requestPasswordReset(email: string) {
    const { data } = await apolloClient.mutate({
      mutation: REQUEST_PASSWORD_RESET,
      variables: { email },
    })

    return data.requestPasswordReset.message
  }

  function signOut() {
    authStore.clearAuth()
    apolloClient.clearStore()
    router.push('/login')
  }

  return {
    signIn,
    signUp,
    signOut,
    requestPasswordReset,
  }
}
