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
      id
      name
      wikidataId
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
      "engines": [
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
```

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

Currently, there's no pagination! I will change this very soon!

## Documentation

I intend to add a GraphiQL editor interface to the website for testing API queries and viewing documentation, but I have not done so in production yet. You should be able to get API documentation for now using a tool like [Insomnia](https://insomnia.rest/).

## Stability

For now, I reserve the right to make breaking changes to the API, though I don't foresee any particularly major breakage. I intend to stabilize the API over the next few months, and would still encourage anyone that is interested to build things with it (I'd be happy to warn you ahead of time about any changes if you tell me about your API usage in our Discord server).

## Data License

As mentioned above, the vast majority of the data on vglist comes from [Wikidata](https://www.wikidata.org), which licenses all its data as public domain. For now, data from vglist should be considered proprietary (though I intend to license it under CC-BY-SA in the future). This is to discourage others from scraping the site. All game covers belong to their respective owners.
