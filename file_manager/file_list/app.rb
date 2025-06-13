require 'json'
require 'logger'
require 'rack'
require 'aws-sdk-s3'
require 'slack-ruby-client'
require 'uri'

def logger
  @logger ||= Logger.new($stdout, level: Logger::Severity::INFO)
end

def verify_request(event)
  env = {
    'rack.input' => StringIO.new(event['body']),
    'HTTP_X_SLACK_REQUEST_TIMESTAMP' => event.dig('headers', 'X-Slack-Request-Timestamp'),
    'HTTP_X_SLACK_SIGNATURE' => event.dig('headers', 'X-Slack-Signature')
  }
  req = Rack::Request.new(env)
  slack_request = Slack::Events::Request.new(req)
  slack_request.verify!
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

def post_to_slack(channel, array)
  client = Slack::Web::Client.new

  client.chat_postMessage(
    channel:,
    text: array.join("\n")
  )
end

def lambda_handler(event:, context:)
  logger.debug(event)
  logger.debug(context)

  verify_request(event)

  params = URI.decode_www_form(event['body']).to_h
  logger.debug(params)

  #event['Records']&.each do |record|
    #list = file_list_s3(record['s3'])
    #post_to_slack(body['event'][''channel], list)
  #end
  
  { statusCode: 200, body: nil}
rescue StandardError => e
  logger.fatal(e.full_message)
  { statusCode: 200, body: e.message }
end
