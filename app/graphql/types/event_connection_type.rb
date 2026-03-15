class Types::EventConnectionType < Types::BaseConnectionObject
  # Override nodes to batch-preload eventables and avoid N+1 queries.
  def nodes
    events = super
    Views::NewEvent.preload_eventables(events)
  end
end
