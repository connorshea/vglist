import gql from "graphql-tag";

export const DELETE_EVENT = gql`
  mutation DeleteEvent($eventId: ID!) {
    deleteEvent(eventId: $eventId) {
      deleted
    }
  }
`;
