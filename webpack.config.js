import { resolve } from 'path';
import { VueLoaderPlugin } from 'vue-loader';
import webpack from "webpack";

// Extracts CSS into .css file
import MiniCssExtractPlugin from 'mini-css-extract-plugin';
// Removes exported JavaScript files from CSS-only entries
import RemoveEmptyScriptsPlugin from 'webpack-remove-empty-scripts';

const mode = process.env.NODE_ENV === 'development' ? 'development' : 'production';

/**
 * @type {import('webpack').Configuration}
 */
const config = {
  mode: mode,
  devtool: mode === 'development' ? false : "source-map",
  entry: {
    application: [
      "./app/javascript/application.ts",
      "./app/assets/stylesheets/application.scss",
    ]
  },
  output: {
    filename: "[name].js",
    sourceMapFilename: "[file].map",
    chunkFormat: "module",
    path: resolve(import.meta.dirname, "app/assets/builds"),
  },
  optimization: {
    moduleIds: 'deterministic',
  },
  plugins: [
    new webpack.DefinePlugin({
      'process.env.NODE_ENV': JSON.stringify(mode),
      'process.env.SENTRY_DSN_JS': JSON.stringify(process.env.SENTRY_DSN_JS),
    }),
    new RemoveEmptyScriptsPlugin(),
    new MiniCssExtractPlugin(),
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1
    }),
    new VueLoaderPlugin()
  ],
  module: {
    rules: [
      {
        test: /\.vue$/,
        loader: 'vue-loader',
        options: {
          compilerOptions: {
            preserveWhitespace: false
          }
        }
      },
      {
        test: /(\.min)?\.s?[ac]ss$/i,
        use: [
          MiniCssExtractPlugin.loader,
          'css-loader',
          {
            loader: 'sass-loader',
            options: {
              api: 'modern-compiler',
              implementation: 'sass-embedded'
            }
          }
        ],
      },
      {
        test: /\.([cm]?ts|tsx)$/,
        exclude: /(node_modules)/,
        use: [
          {
            loader: "swc-loader",
            options: {
              jsc: {
                parser: {
                  syntax: "typescript",
                  tsx: true,
                  decorators: true
                },
                transform: {
                  decoratorMetadata: true
                }
              }
            },
          },
          resolve('./custom-loader'),
        ],
      }
    ]
  },
  resolve: {
    // Add additional file types
    extensions: ['.ts', '.vue', '.js', '.jsx', '.scss', '.css', '.min.css'],
  },
}

export default config;
