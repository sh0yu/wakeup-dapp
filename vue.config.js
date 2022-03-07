const { defineConfig } = require('@vue/cli-service')
const webpack = require('webpack')

module.exports = defineConfig({
  transpileDependencies: true,
  configureWebpack: {
    plugins: [
      new webpack.ProvidePlugin({
        Buffer: ['buffer', 'Buffer'],
        process: 'process/browser'
      })
    ],
    resolve: {
      fallback: {
        "assert": false,
        "buffer": require.resolve("buffer"),
        "crypto": false,
        // "crypto": require.resolve("crypto-browserify"),
        "fs": false,
        "os": false,
        "http": false,
        "https": false,
        "stream": false
      }
    }
  }
})
