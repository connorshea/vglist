const { environment } = require('@rails/webpacker')
const vue = require('./loaders/vue')

// resolve-url-loader must be used before sass-loader
environment.loaders.get('sass').use.splice(-1, 0, {
  loader: 'resolve-url-loader'
});

environment.loaders.append('vue', vue)
module.exports = environment
