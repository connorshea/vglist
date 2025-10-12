import { resolve } from 'path';
import { VueLoaderPlugin } from 'vue-loader';
import webpack from "webpack";

// Extracts CSS into .css file
import MiniCssExtractPlugin from 'mini-css-extract-plugin';

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
      __VUE_PROD_DEVTOOLS__: 'false',
      __VUE_PROD_HYDRATION_MISMATCH_DETAILS__: 'false',
      __VUE_OPTIONS_API__: 'true', // Set to false later if we move off vue-select.
    }),
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
        test: /\.([cm]?ts)$/,
        exclude: /(node_modules)/,
        use: [
          {
            loader: "swc-loader",
            options: {
              jsc: {
                parser: {
                  syntax: "typescript",
                  tsx: false
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
    extensions: ['.ts', '.vue', '.js', '.scss', '.css', '.min.css']
  },
}

export default config;
