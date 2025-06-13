require 'json'
require 'logger'
require 'rack'
require 'aws-sdk-s3'
require 'slack-ruby-client'

def logger
  @logger ||= Logger.new($stdout, level: Logger::Severity::INFO)
end

Slack.configure do |config|
  config.token = ENV.fetch('SLACK_API_TOKEN', nil)
end

def file_list_s3(s3_event)
  bucket = s3_event.dig('bucket', 'name')

  client = Aws::S3::Client.new
  resp = client.list_objects_v2(
    bucket: ENV['BUCKET_NAME'],
    max_keys: 1000
  )

  keys = resp.contents.map(&:key)
end

def lambda_handler(event:, context:)
  logger.debug(event)
  logger.debug(context)

  { statusCode: 200, body: }
rescue StandardError => e
  logger.fatal(e.full_message)
  { statusCode: 200, body: e.message }
end
