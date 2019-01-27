require 'sinatra'

get '/' do
  redirect 'https://github.com/DanielVartanov/youtube-lectures-downloader-telegram-bot'
end

post '/download' do
  'dummy'
end
