require 'json'
require 'logger'
require 'rack'
require 'aws-sdk-sqs'
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

def send_to_queue(channel)
  client = Aws::SQS::Client.new

  client.send_message(
    queue_url: ENV.fetch('QUEUE_NAME', nil),
    message_body: {
       channel:
    }.to_json
  )
end

def lambda_handler(event:, context:)
  logger.debug(event)
  logger.debug(context)

  verify_request(event)

  params = URI.decode_www_form(event['body']).to_h
  #puts params
  #puts params['channel_name']
  send_to_queue(params['channel_name'])
  
  { statusCode: 200, body: nil }
rescue StandardError => e
  logger.fatal(e.full_message)
  { statusCode: 200, body: e.message }
end
