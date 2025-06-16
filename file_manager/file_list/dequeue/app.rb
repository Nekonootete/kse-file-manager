require 'json'
require 'logger'
require 'rack'
require 'aws-sdk-s3'
require 'slack-ruby-client'
require 'uri'

Slack.configure do |config|
  config.token = ENV.fetch('SLACK_API_TOKEN', nil)
end

def logger
  @logger ||= Logger.new($stdout, level: Logger::Severity::INFO)
end

def file_list_s3
  client = Aws::S3::Client.new

  resp = client.list_objects_v2(
    bucket: ENV.fetch('BUCKET_NAME', nil),
    max_keys: 1000
  )

  resp.contents.map(&:key)
end

def post_to_slack(array, channel)
  client = Slack::Web::Client.new

  client.chat_postMessage(
    channel:,
    text: array.join("\n")
  )
end

def lambda_handler(event:, context:)
  logger.debug(event)
  logger.debug(context)

  event['Records']&.each do |record|
    body = JSON.parse(record['body'])
    post_to_slack(file_list_s3, body['channel'])
  end
rescue StandardError => e
  logger.fatal(e.full_message)
end
