const PnpWebpackPlugin = require('pnp-webpack-plugin');

module.exports = {
  test: /\.(ts|tsx)?(\.erb)?$/,
  use: [
    {
      loader: 'ts-loader',
      options: PnpWebpackPlugin.tsLoaderOptions({
        appendTsSuffixTo: [/\.vue$/],

        // Using `fork-ts-checker-webpack-plugin` See:
        // https://github.com/TypeStrong/fork-ts-checker-webpack-plugin
        // to run type checking in a separate process, so `ts-loader` only does the
        // compilation work. Reduces compile time like crazy. See also:
        // https://github.com/TypeStrong/ts-loader#faster-builds
        transpileOnly: true
      })
    }
  ]
};
