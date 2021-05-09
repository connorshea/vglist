# typed: strict
module Types
  class SortDirectionType < Types::BaseEnum
    description "Direction for sorting a list of records."

    value 'DESC', value: 'desc', description: 'Sorted descending (larger values first).'
    value 'ASC', value: 'asc', description: 'Sorted ascending (smaller values first).'
  end
end
