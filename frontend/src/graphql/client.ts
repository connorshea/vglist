import { GraphQLClient } from "graphql-request";
import { useAuthStore } from "@/stores/auth";

export const gqlClient = new GraphQLClient(`${import.meta.env.VITE_API_URL}/graphql`, {
  headers: () => {
    const authStore = useAuthStore();
    const token = authStore.token;
    const headers: Record<string, string> = {};
    if (token) headers["authorization"] = `Bearer ${token}`;
    return headers;
  }
});
