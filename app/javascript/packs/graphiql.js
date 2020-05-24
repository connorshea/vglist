// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import { React } from 'react';
import { ReactDOM } from 'react-dom';
import 'graphiql';
import '../vendor/graphiql-1.0.0-alpha.10.css';

let graphQLFetcher = (graphQLParams) => {
  return fetch(window.location.origin + '/graphql', {
    method: 'post',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(graphQLParams),
  }).then(response => response.json());
}

ReactDOM.render(
  React.createElement(GraphiQL, { fetcher: { graphQLFetcher } }),
  document.body
);
