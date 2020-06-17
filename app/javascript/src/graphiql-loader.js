import { GraphiQL } from 'graphiql';
import { buildSchema } from 'graphql';

let graphQLFetcher = (graphQLParams, opts = { headers: {} }) => {
  return fetch(window.location.origin + '/graphql', {
    method: 'post',
    headers: Object.assign({ 'Content-Type': 'application/json', 'User-Agent': 'vglist.co GraphiQL' }, opts.headers),
    body: JSON.stringify(graphQLParams),
  }).then(response => response.json());
}

let schema = document.getElementById("graphiql-injection-point").dataset.graphqlSchema;
let graphQLSchema = buildSchema(schema);

ReactDOM.render(
  React.createElement(GraphiQL, {
    schema: graphQLSchema,
    fetcher: graphQLFetcher,
    headerEditorEnabled: true,
    headers: '{\n  "X-User-Email": "user@example.com",\n  "X-User-Token": "API_TOKEN_HERE"\n}'
  }),
  document.getElementById("graphiql-injection-point")
);
