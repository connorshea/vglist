const { environment } = require('@rails/webpacker');
const typescript = require('./loaders/typescript');
const { VueLoaderPlugin } = require('vue-loader');
const vue = require('./loaders/vue');
const ForkTsCheckerWebpackPlugin = require('fork-ts-checker-webpack-plugin');

environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin());
environment.loaders.prepend('vue', vue);
environment.loaders.prepend('typescript', typescript);

// Makes TypeScript compilation time much faster.
environment.plugins.append(
  'ForkTsCheckerWebpackPlugin',
  new ForkTsCheckerWebpackPlugin({
    vue: true,

    // makes webpack wait for type checking to finish before "emitting"; allows
    // type errors to remain present in the build output from webpack and in
    // webpack-dev-server's darkened overlay
    async: false
  })
);

environment.loaders.get('sass').use.splice(-1, 0, {
  loader: 'resolve-url-loader'
});

module.exports = environment;
