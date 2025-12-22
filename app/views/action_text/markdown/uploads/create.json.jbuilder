json.message "File uploaded successfully"
json.fileName @upload.filename.to_s
json.mimetype @upload.content_type
json.fileUrl @upload.slug_url host: request.host_with_port
json.attachmentSlug @upload.slug
json.streamId @stream_id if @stream_id
