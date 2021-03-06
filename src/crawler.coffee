_           = require 'lodash'
linkFinder  = require './link_finder'
linkFilter  = require './link_filter'
build       = require './request_builder'

localItFunction = null

config = null

exports.getLinks = (res) ->
  getLinksFn = if config?.getLinks? then config.getLinks else linkFinder.getLinks
  linkFilter.filter(getLinksFn(res.body), config?.samplePercentage)

exports.setConfig = (userconfig) ->
  config = userconfig

setIt = (it) ->
  localItFunction = it

createIt = (url) =>
  localItFunction url, (done) =>
    build.request(url, config.options).end(
      (res) =>
        exports.processResponse(url, res, done)
    )

exports.processResponse = (parent, res, done) =>
  return done(res.text) if not res.ok
  return done("Not a valid response: #{res.text}") if not validate parent, res
  describe "#{parent}", ->
    _.forEach exports.getLinks(res), (link) ->
      linkFilter.processLink link
      exports.crawl link
  done()

validate = (url, res) ->
  return true if not config?.validate?
  return config.validate(url, res.body)

exports.crawl = (url) ->
  createIt url

exports.startCrawl = (config, it) ->
  exports.reset()
  setIt it if it
  exports.setConfig config
  url = config.url
  linkFilter.processLink url
  exports.crawl url

exports.reset = ->
  linkFilter.reset()
  config = null
  localItFunction = null
