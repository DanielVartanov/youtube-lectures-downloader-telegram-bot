require 'sinatra'
require 'pathname'
require 'digest/md5'
require 'json'

MY_DOMAIN = 'lectures-downldr.mountainprogramming.com'
VIDEOS_DIRECTORY = Pathname.new '/tmp/video_files/'

get '/' do
  redirect 'https://github.com/DanielVartanov/youtube-lectures-downloader-telegram-bot'
end

post '/download' do
  body = request.body.read
  json = JSON.parse body
  chat_id = json['message']['chat']['id']
  video_url = json['message']['text']

  video_url_hash = Digest::MD5.hexdigest video_url
  unique_video_subdirectory = VIDEOS_DIRECTORY + video_url_hash

  system <<-CMD
    mkdir -p #{unique_video_subdirectory}
    cd #{unique_video_subdirectory}
    youtube-dl #{video_url} --format bestaudio --extract-audio --audio-format mp3 --audio-quality 0
CMD

  download_downloaded_url = "http://#{MY_DOMAIN}/download_downloaded/#{video_url_hash}"

  content_type :json
  { method: 'sendMessage', chat_id: chat_id, text: download_downloaded_url }.to_json
end

get '/download_downloaded/:video_url_hash' do
  unique_video_subdirectory = VIDEOS_DIRECTORY + params[:video_url_hash]
  audio_file_path = unique_video_subdirectory.glob('*.mp3').first

  attachment audio_file_path
end
