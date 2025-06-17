require 'uri'
require 'logger'
require 'slack-ruby-client'
require 'aws-sdk-s3'
require 'json'

Slack.configure do |config|
  config.token = ENV.fetch('SLACK_API_TOKEN', nil)
end

def logger
  @logger ||= Logger.new($stdout, level: Logger::Severity::INFO)
end

def file_list_s3(s3_event)
  bucket = s3_event.dig('bucket', 'name')
  key = URI.decode_www_form_component(s3_event.dig('object', 'key'))

  client = Aws::S3::Client.new
  channel = client.get_object_tagging(bucket:, key:).tag_set.find { |tag| tag.key == 'channel' }.value
  resp = client.list_objects_v2(
    bucket:,
    max_keys: 1000
  )
  list_array = resp.contents.map(&:key)

  [channel, list_array]
end

def post_to_slack(channel, array)
  client = Slack::Web::Client.new

  header = "ファイルのアップロードが完了しました。\n現在ダウンロードできるファイルは以下の通りです。\n"
  body = array.map { |e| "・#{e}" }.join("\n")
  client.chat_postMessage(
    channel:,
    text: header + body
  )
end

def lambda_handler(event:, context:)
  logger.debug(event)
  logger.debug(context)

  event['Records']&.each do |record|
    post_to_slack(*file_list_s3(record['s3']))
  end
rescue StandardError => e
  logger.fatal(e.full_message)
end