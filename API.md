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
      "wikidataId": 193581,
      "engines": {
        "nodes": [
          {
            "id": "3",
            "name": "Havok",
            "wikidataId": 616957
          },
          {
            "id": "6",
            "name": "Source Engine",
            "wikidataId": 643572
          }
        ]
      }
    }
  }
}
```

vglist's GraphQL endpoint is available at `https://vglist.co/graphql` (queries must be POSTed).

## 'Scraping' the vglist Database

If you just want to scrape the database to create something yourself, it'd be much easier (and much nicer for me) if you'd instead just get the data from [Wikidata](https://www.wikidata.org), which is where the vast majority (>95%) of vglist's data originally came from. The Wikidata import scripts I built for vglist are all open source and are available in [the vglist GitHub repository](https://github.com/connorshea/vglist/tree/main/lib/tasks/import). Game covers were mostly retrieved from the kind folks at [PCGamingWiki](https://www.pcgamingwiki.com) and [MobyGames](https://www.mobygames.com/).

## Authentication

The API does not support public access, and requires that you have a user account and either an API token or OAuth token.

### OAuth

The vglist API supports authentication with [OAuth 2.0](https://www.oauth.com/). This is meant to allow other websites' users to connect their vglist accounts and import/export data, or to allow applications (e.g. a local game library client such as Playnite) to update a user's vglist library whenever they buy or play a game.

<!-- TODO: Make 'native' OAuth applications w/ `urn:ietf:wg:oauth:2.0:oob` work and then document using that here. -->

To create an OAuth application and use OAuth tokens, you'll need a vglist account. In your settings, you'll see a 'Developer' section in the sidebar. On that page you can create a new OAuth application.

Make sure to name it, set the URL to the website you want to redirect to (this is how you get the code after a user authorizes your application), and then set the scopes (`read` if you only want to read data, or `read write` if you want to read _and_ write).

The page will redirect and show the application secret. **Make sure** to copy this somewhere safe, you'll only get to see this secret once. It's encrypted and can't be shown again later. If you want to change the application secret, you'll need to create a new application.

The grant type will always be `authorization_code`. The Authorization URL is `https://vglist.co/settings/oauth/authorize` and the Access Token URL is `https://vglist.co/settings/oauth/token`. The Client ID and Client Secret are provided on the Application page you were redirected to when the application was created. The exact Authorization URL - with query parameters included - is available on the OAuth Application page.

To try the OAuth Application you've created, I would recommend trying to send a GraphQL request using [Insomnia](https://insomnia.rest/). You can create a 'Request', set its type to GraphQL, and authenticate using OAuth 2.0. Then you can play with it as much as you want.

#### Scopes

There are two available scopes for OAuth tokens: `read` and `write`. All access tokens will have the `read` scope by default.

The `read` scope lets you perform GraphQL queries. `write` lets you perform GraphQL mutations.

If you want to use a token with the `write` scope, make sure you send the `write` scope as an explicit part of the OAuth request whenever you send a request. The OAuth application will also need to have the `write` scope in its 'Scopes' field.

If you're getting errors about insufficient scope, make sure you include `&scope=read+write` as part of the authorization URL.

### API Tokens

**NOTE:** If you want to create an application that lets other users log into their accounts on vglist, _use OAuth_. API Tokens are not meant for this purpose, and should never be shared with other users.

API Tokens are different from OAuth in that they last an indefinite amount of time and don't need to be refreshed. They also allow both reading and writing to the API without any scopes being specified. They're useful for creating things like Discord bots, which could be used for things like searching the vglist database with a bot command.

API Tokens can be found in your Settings, in the "Developer" tab. You can click the "View Token" button to view your token or use the "Reset Token" button to change the token to a new, random value. Always keep your token secret, and reset it immediately if you find out the token was leaked or stolen. It can be used to modify your game library, follow/unfollow users, etc.

When sending API requests with an API Token, you need to supply your user email and API Token. You can do so with the `X-User-Email` and `X-User-Token` HTTP headers.

For example, when using the [graphql-client](https://github.com/github/graphql-client) gem in Ruby it might look something like this:

```ruby
GraphQL::Client::HTTP.new("https://vglist.co/graphql") do
  def headers(context)
    {
      "User-Agent": "Example API Client",
      "X-User-Email": "connor@example.com",
      "X-User-Token": "API_TOKEN_HERE",
      "Content-Type": "application/json",
      "Accept": "*/*"
    }
  end
end
```

Always make sure to include a `User-Agent` header with an identifiable name in your requests. These help identify your bot or script, and helps me block bad actors from abusing the API. In the future, they'll likely be required for the API to accept your request.

## Rate Limiting

Currently, there's no rate limiting! I will change this very soon!

## Pagination

All endpoints which return lists of items (for example, if you query for all the owners of a game) will have pagination. The paginated items will return "Connection" types, e.g. `UserConnection`.

For example, you can get a user's game purchases (games in a user's library) with a query like this:

```graphql
query($id: ID!) {
  user(id: $id) {
    gamePurchases {
      nodes {
        game {
          name
        }
      }
      pageInfo {
        hasNextPage
        pageSize
        endCursor
      }
    }
  }
}
```

The `nodes` represent the items in the paginated list, so in this case `nodes` returns an array of `gamePurchase` types. The `pageInfo` field provides information about the status of the current query's pagination. It's useful for getting the `pageSize` for the query, whether more pages exist, and the 'cursor' which can be used to get more pages on subsequent requests.

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
        pageSize
        endCursor
      }
    }
  }
}
```

You may want to use a variable for the cursor value, to make it easier to page through the query response.

You can also use `totalCount` on any Connection types to get the total number of records that a given query returns, regardless of pagination.

```graphql
query {
  games {
    nodes {
      id
      name
    }
    totalCount
  }
}
```

By default, pages in the GraphQL API return sets of 30 items. You can increase or decrease the number of returned items by passing a `first` argument. The maximum number of records that can be requested per page is 100. If you try to go any higher than that, it'll clamp it back down to 100. You can use `first` and `after` in the same query.

```graphql
query {
  # This will return the first 100 records, instead of just the first 30.
  games(first: 100) {
    nodes {
      id
      name
    }
    totalCount
  }
}
```

Please be thoughtful about your API usage, and don't request the maximum number of records per page unless it's necessary. If your use-case works fine with 30 records at a time, just use 30 records.

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

Mutations start with the `mutation` keyword, and any variables can be defined from there. All mutations accept parameters. In this case, we're adding a game to the user's library with 150 hours played, a comment that says "Pretty good", a completion status of `COMPLETED`, and a rating of `100`.

The mutation will return the defined data (the `gamePurchase`, the associated game, `hoursPlayed`, `comments`, `completionStatus`, and `rating`) if it's successful. If it fails - for example when the user already has the game in their library or when the user doesn't have sufficient permissions to perform the action being attempted - it will instead return an empty `data` object and an `errors` object.

Each type of mutation has different parameters. The specific parameters are documented in the GraphQL schema.

## Documentation

You can get documentation and test queries in the GraphiQL editor that's hosted alongside vglist, at [vglist.co/graphiql](https://vglist.co/graphiql). You need to use API Token authentication in the GraphiQL header editor tab. See [#api-tokens] for information on accessing your token.

You should also be able to get API documentation using a tool like [Insomnia](https://insomnia.rest/).

For writing GraphQL queries, the [GraphQL website](https://graphql.org/) should be a sufficient introduction.

You can also find a lot of example queries inside vglist's API test suite, in [`spec/requests/api/`](https://github.com/connorshea/vglist/tree/main/spec/requests/api). Queries are stored in "HEREDOCs" that look like this:

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
