export enum CompletionStatus {
  unplayed = 'UNPLAYED',
  in_progress = 'IN_PROGRESS',
  dropped = 'DROPPED',
  completed = 'COMPLETED',
  fully_completed = 'FULLY_COMPLETED',
  not_applicable = 'NOT_APPLICABLE',
  paused = 'PAUSED'
}

export interface GamePurchase {
  id: number;
  user_id: number;
  game_id: number;
  created_at: string;
  updated_at: string;
  completion_status?: CompletionStatus;
};
