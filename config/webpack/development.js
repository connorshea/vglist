process.env.NODE_ENV = process.env.NODE_ENV || 'development'

const environment = require('./environment')
const path = require("path");

module.exports = environment.toWebpackConfig()
