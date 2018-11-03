_ = require("underscore")
User = require('./models/user')
Event = require('./models/event')
Theme = require('./models/theme')
Product = require('./models/product')
Project = require('./models/project')
async = require('async')

module.exports.log = (req, res, next) ->
    if req.method is 'POST' or req.method is 'PUT' or req.method is 'DELETE'
      if req.path.split('/')[1] is 'api'

        type = req.path.split('/')[2]
        type = type.substr(0, type.length-1)
        mid = req.path.split('/')[3]

        method = req.method
        modelData = {}

        getModel = (cb) ->
          if req.method is 'DELETE'
            if type is 'theme'
              schema = Theme
            else if type is 'project'
              schema = Project
            else if type is 'product'
              schema = Product
            schema.findOne({_id: mid}).select('title').exec (err, doc) ->
              modelData = doc
              cb()
          else
            modelData = res.locals.bundle
            cb()

        updateModel = (cb) ->
          if type is 'theme'
            schema = Theme
          else if type is 'project'
            schema = Project
          else if type is 'product'
            schema = Product
          schema.update {_id: mid}, {last_updated: new Date()}, (err, doc) ->
            cb()


        sendPacket = (cb) ->
          User.findOne {email: req.session.email}, (err, user) ->
            Event.create {
                verb: method
                type: type
                model: modelData
                changes: req.body
                mid: mid
                owner: user._id
              }, (err, e) ->
                Event.findOne({_id: e._id}).populate('owner').exec (err, doc) ->
                  cb()

        async.series [getModel, updateModel, sendPacket], (err, results) ->
          next()
      else
        next()
    else
      next()

