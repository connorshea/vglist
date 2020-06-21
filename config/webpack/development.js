process.env.NODE_ENV = process.env.NODE_ENV || 'development'

const environment = require('./environment')
const ForkTsCheckerWebpackPlugin = require('fork-ts-checker-webpack-plugin');
const path = require("path");

// Makes TypeScript compilation time much faster.
environment.plugins.append(
  "ForkTsCheckerWebpackPlugin",
  new ForkTsCheckerWebpackPlugin({
    typescript: {
      tsconfig: path.resolve(__dirname, "../../tsconfig.json"),
      extensions: {
        vue: true
      }
    },
    // makes webpack wait for type checking to finish before "emitting"; allows
    // type errors to remain present in the build output from webpack and in
    // webpack-dev-server's darkened overlay
    async: false,
  })
);

module.exports = environment.toWebpackConfig()
