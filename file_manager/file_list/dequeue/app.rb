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

def file_list_s3()
  client = Aws::S3::Client.new

  resp = client.list_objects_v2(
    bucket: ENV.fetch('BUCKET_NAME', nil),
    max_keys: 1000
  )

  keys = resp.contents.map(&:key)
end

def post_to_slack(channel, array)
  client = Slack::Web::Client.new

  client.chat_postMessage(
    channel:,
    text: array
  )
end

def lambda_handler(event:, context:)
  logger.debug(event)
  logger.debug(context)

  verify_request(event)

  params = URI.decode_www_form(event['body']).to_h
  #logger.debug(params)
  #puts params
  #puts event
  #puts params['channel_name']
  list = file_list_s3()
  puts list #ok!
  channel = params['channel_name']
  post_to_slack(channel, list)
  
  { statusCode: 200, body: nil }
rescue StandardError => e
  logger.fatal(e.full_message)
  { statusCode: 200, body: e.message }
end
