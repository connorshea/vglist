const { environment } = require('@rails/webpacker');
const { VueLoaderPlugin } = require('vue-loader');
const vue = require('./loaders/vue');
const { resolve } = require('path');

environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin());
environment.loaders.prepend('vue', vue);

environment.loaders.get('sass').use.splice(-1, 0, {
  loader: 'resolve-url-loader'
});

environment.config.merge({
  resolve:{
    alias: {
      'react': resolve('app/javascript/src/vendor/react-16.13.1'),
      'react-dom': resolve('app/javascript/src/vendor/react-dom-16.13.1'),
      'graphiql': resolve('app/javascript/src/vendor/graphiql-1.0.0-alpha.10')
    }
  }
});

module.exports = environment;
