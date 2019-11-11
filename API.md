# vglist API

vglist includes a built-in [GraphQL](https://graphql.org/) API that allows third-party users to request and modify information on the site. As opposed to a 'REST' API, GraphQL allows users to request data in a query format rather than via HTTP requests to various endpoints.

For example, rather than needing to make one request that gets a game's information, and then a separate request to get information on the engines used by the game, you can get all of this information with one query.

Example query:

```graphql
query($id: ID!) {
  game(id: $id) {
    name
    id
    wikidataId
    engines {
      nodes {
        id
        name
        wikidataId
      }
    }
  }
}
```

(and a query variable like `{ "id": "372" }`)

JSON response:

```json
{
  "data": {
    "game": {
      "name": "Half-Life 2",
      "id": "372",
      "wikidataId": "193581",
      "engines": {
        "nodes": [
          {
            "id": "3",
            "name": "Havok",
            "wikidataId": "616957"
          },
          {
            "id": "6",
            "name": "Source Engine",
            "wikidataId": "643572"
          }
        ]
      }
    }
  }
}
```

vglist's GraphQL endpoint is available at `https://vglist.co/graphql` (queries must be POSTed).

## 'Scraping' the vglist Database

If you just want to scrape the database to create something yourself, it'd be much easier (and much nicer for me) if you'd instead just get the data from [Wikidata](https://www.wikidata.org), which is where the vast majority (>95%) of vglist's data originally came from. The Wikidata import scripts I built for vglist are all open source and are available in [the vglist GitHub repository](https://github.com/connorshea/VideoGameList/tree/master/lib/tasks/import). Game covers were mostly retrieved from the kind folks at [PCGamingWiki](https://pcgamingwiki.com) and [MobyGames](https://www.mobygames.com/).

## Authentication

The API does not support public access, and requires that you have a user account and OAuth token.

### OAuth

The vglist API supports authentication with [OAuth 2.0](https://www.oauth.com/). This is meant to allow other websites' users to connect their vglist accounts and import/export data, or to allow applications (e.g. a local game library client such as Playnite) to update a user's vglist library whenever they buy or play a game.

<!-- TODO: Add a guide for creating an OAuth application here. -->

### API Tokens

I intend to support long-lasting API tokens soon, but they do not currently exist. They'll be useful for creating things like Discord bots, which could be used for things like searching the vglist database with a bot command.

## Rate Limiting

Currently, there's no rate limiting! I will change this very soon!

## Pagination

All endpoints which return lists of items (for example, if you query for all the owners of a game) will have pagination. The paginated items will return "Connection" types, e.g. `UserConnection`.

For example, you can get a user's game purchases (games in a user's library) with a query like this:

```graphql
query($id:ID!) {
  user(id: $id) {
    gamePurchases {
      nodes {
        game {
          name
        }
      }
      pageInfo {
        hasNextPage
        total
        endCursor
      }
    }
  }
}
```

The `nodes` represent the items in the paginated list, so in this case `nodes` returns an array of `gamePurchase` types. The `pageInfo` field provides information about the status of the current query's pagination. It's useful for getting the total number of items returned by the query, whether more pages exist, and the 'cursor' which can be used to get more pages on subsequent requests.

In this case, the return value of `endCursor` is `"Mw"`, and we can resubmit the same query with `gamePurchases(after: "Mw")` to get all the items on the next page.

```graphql
query($id: ID!) {
  user(id: $id) {
    gamePurchases(after: "Mw") {
      nodes {
        game {
          name
        }
      }
      pageInfo {
        hasNextPage
        total
        endCursor
      }
    }
  }
}
```

You may want to use a variable for the cursor value, to make it easier to page through the query response.

## Mutations

In GraphQL, API requests that are intended to change the data in the API (e.g. adding a game to a user's library) are called [Mutations](https://graphql.org/learn/queries/#mutations). Unlike queries, which only _read_ data, mutations can be used to _write_ data.

Mutations in the vglist API look like the following:

```graphql
mutation($id: ID!) {
  addGameToLibrary(
    gameId: $id,
    hoursPlayed: 150,
    comments: "Pretty good",
    completionStatus: COMPLETED,
    rating: 100
  ) {
    gamePurchase {
      game {
        name
      }
      hoursPlayed
      comments
      completionStatus
      rating
    }
  }
}
```

Mutations start with the `mutation` keyword, and any variables can be defined from there. The and all mutations accept parameters. In this case, we're adding a game to the user's library with 150 hours played, a comment that says "Pretty good", a completion status of `COMPLETED`, and a rating of 100.

The mutation will return the defined data (the `gamePurchase`, the associated game, and the hoursPlayed, comments, completionStatus, and rating) if it was successful. If it failed - for example when the user already has the game in their library - it will instead return an empty `data` object and an `errors` object.

Each different mutation has different parameters. The specific parameters are documented in the GraphQL schema.

## Documentation

I intend to add a GraphiQL editor interface to the website for testing API queries and viewing documentation, but I have not done so in production yet. You should be able to get API documentation for now using a tool like [Insomnia](https://insomnia.rest/).

For writing GraphQL queries, the [GraphQL website](https://graphql.org/) should be a sufficient introduction.

You can also find a lot of example queries inside vglist's API test suite, in [`spec/requests/api/`](https://github.com/connorshea/VideoGameList/tree/master/spec/requests/api). Queries are stored in "HEREDOCs" that look like this:

```ruby
query_string = <<-GRAPHQL
  query {
    activity(feedType: GLOBAL) {
      user {
        username
      }
      eventable {
        __typename
      }
    }
  }
GRAPHQL
```

The query itself is everything between the two `GRAPHQL`s.

## Stability

For now, I reserve the right to make breaking changes to the API, though I don't foresee any particularly major breakage. I intend to stabilize the API over the next few months, and would still encourage anyone that is interested to build things with it (I'd be happy to warn you ahead of time about any changes if you tell me about your API usage in our Discord server).

## Data License

As mentioned above, the vast majority of the data on vglist comes from [Wikidata](https://www.wikidata.org), which licenses all its data as public domain. Data on vglist is licensed under [CC-BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). This is to discourage others from scraping the site. See the 'scraping' section if you want to get a CC-0 copy of the data. All game covers belong to their respective owners.
