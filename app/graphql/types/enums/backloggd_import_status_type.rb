# frozen_string_literal: true

module Types::Enums
  class BackloggdImportStatusType < Types::BaseEnum
    description "Where a Backloggd import is up to."

    value "QUEUED", value: 'queued', description: 'Waiting to start.'
    value "RUNNING", value: 'running', description: 'Fetching the Backloggd list and adding its games.'
    value "SUCCEEDED", value: 'succeeded', description: 'Finished. The results are ready.'
    value "FAILED", value: 'failed', description: "Stopped early. `errorMessage` says why."
  end
end
