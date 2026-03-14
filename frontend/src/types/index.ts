export type CompletionStatus =
  | "unplayed"
  | "in_progress"
  | "paused"
  | "dropped"
  | "completed"
  | "fully_completed"
  | "not_applicable";

export type UserRole = "member" | "moderator" | "admin";

export type UserPrivacy = "public_account" | "private_account";

export type AvatarSize = "small" | "medium" | "large";

export interface User {
  id: string;
  username: string;
  email?: string;
  bio: string | null;
  slug: string;
  role: UserRole;
  privacy: UserPrivacy;
  createdAt: string;
  updatedAt: string;
  banned: boolean;
  avatarUrl: string | null;
  isFollowed: boolean | null;
  hideDaysPlayed: boolean;
}

export interface Game {
  id: string;
  name: string;
  wikidataId: number | null;
  pcgamingwikiId: string | null;
  mobygamesId: string | null;
  giantbombId: string | null;
  epicGamesStoreId: string | null;
  gogId: string | null;
  igdbId: string | null;
  steamAppIds: number[];
  releaseDate: string | null;
  avgRating: number | null;
  coverUrl: string | null;
  developers: Company[];
  publishers: Company[];
  platforms: Platform[];
  genres: Genre[];
  engines: Engine[];
  series: Series | null;
}

export interface GamePurchase {
  id: string;
  game: Game;
  hoursPlayed: number | null;
  completionStatus: CompletionStatus | null;
  rating: number | null;
  startDate: string | null;
  completionDate: string | null;
  comments: string | null;
  replayCount: number;
  platforms: Platform[];
  stores: Store[];
}

export interface Platform {
  id: string;
  name: string;
  wikidataId: number | null;
}

export interface Genre {
  id: string;
  name: string;
  wikidataId: number | null;
}

export interface Company {
  id: string;
  name: string;
  wikidataId: number | null;
}

export interface Engine {
  id: string;
  name: string;
  wikidataId: number | null;
}

export interface Series {
  id: string;
  name: string;
  wikidataId: number | null;
}

export interface Store {
  id: string;
  name: string;
}

export interface Event {
  id: string;
  eventCategory: string;
  createdAt: string;
  user: User;
  eventable: Game | GamePurchase | User;
}

export interface PageInfo {
  hasNextPage: boolean;
  hasPreviousPage: boolean;
  startCursor: string | null;
  endCursor: string | null;
}

export interface SearchResult {
  searchableId: string;
  searchableType: string;
  content: string;
  searchable: Game | User | Company | Platform | Engine | Genre | Series | Store;
}
