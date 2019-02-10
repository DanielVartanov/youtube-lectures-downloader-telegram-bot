require 'sinatra'
require 'pathname'
require 'digest/md5'

VIDEOS_DIRECTORY = Pathname.new '/tmp/video_files/'

get '/' do
  redirect 'https://github.com/DanielVartanov/youtube-lectures-downloader-telegram-bot'
end

post '/download' do
  body = request.body.read
  json = JSON.parse body
  video_url = json['message']

  video_url_hash = Digest::MD5.hexdigest video_url
  unique_video_subdirectory = VIDEOS_DIRECTORY + video_url_hash

  system <<-CMD
    mkdir -p #{unique_video_subdirectory}
    cd #{unique_video_subdirectory}
    youtube-dl #{video_url} --format bestaudio --extract-audio --audio-format mp3 --audio-quality 0
CMD

  resulting_audio_file = unique_video_subdirectory.glob('*.mp3').first
  send_file resulting_audio_file
end
