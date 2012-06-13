# Export Plugin
module.exports = (BasePlugin) ->

	# Define Plugin
	class RestPlugin extends BasePlugin
		# Plugin Name
		name: 'rest'

		# Run when the server setup has finished
		serverAfter: ({server},next) ->
			# Prepare
			docpad = @docpad
			config = @config

			# Hook into all post requests
			server.post /./, (req,res,next) =>
				docpad.log "info", "Request url = #{req.url}"
				docpad.log "info", "Request body = #{JSON.stringify req.body, null, 4}"
				# Check is maintainer
				if config.requireAuthentication and docpad.getPlugin('authenticate').isMaintainer() is false
					res.send(405) # Not authorized
					return next()

				docpad.log "info", "Authentication OK or not needed"

				# Fetch the document
				docpad.log "info", "Documents collection = #{JSON.stringify docpad.getCollection('documents'), null, 4}"

				docpad.getCollection('documents').findOne url: req.url, (err,document) ->
					# Error?
					docpad.log "info", "Searching document..."
					docpad.log "info", "Error ? : #{JSON.stringify err, null, 4}"
					return next(err)  if err

					docpad.log "info", "Document found = #{JSON.stringify document, null, 4}"
					# Empty?
					unless document
						return next()

					# Update it's meta data
					for own key, value of req.body
						document.meta.set(key:value)  if document.meta.attributes[key]?
					
					# Save the changes
					document.write (err) ->
						return next(err)  if err
						res.send JSON.stringify {success:true}
			next()