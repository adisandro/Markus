const { environment } = require('@rails/webpacker')
const erb =  require('./loaders/erb')
const webpack = require('webpack')

// the ProvidePlugin automatically loads modules instead of having to import or require them
// when '$' or 'jQuery' are encountered as variables at build time, they are filled with the exports of module 'jquery'
// jquery alone works with a simple:
//   import $ from 'jquery/src/jquery';
//   window.$ = window.jQuery = $;
// but this is required for other modules depending on jquery to work, such as jquery-ui
environment.plugins.prepend('Provide', new webpack.ProvidePlugin({
  $: 'jquery',
  jQuery: 'jquery'
}))
// set the right entry point for jquery (which has a non-standard layout), when used by the ProvidePlugin
environment.config.resolve.alias = {
  jquery: 'jquery/src/jquery'
}

environment.loaders.append('erb', erb)
module.exports = environment
