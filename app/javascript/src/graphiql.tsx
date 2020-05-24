// import React from 'react';
// import ReactDOM from 'react-dom';
import GraphiQL from 'graphiql';

function graphQLFetcher(graphQLParams) {
  return fetch(window.location.origin + '/graphql', {
    method: 'post',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(graphQLParams),
  }).then(response => response.json());
}

// document.addEventListener('DOMContentLoaded', () => {
//   ReactDOM.render(
//     <GraphiQL fetcher={graphQLFetcher} />,
//     document.body
//   );
// });
