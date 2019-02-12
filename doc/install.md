#### metadata.rb

```
+depends 'poise-ruby-build'
+depends 'application_git'
+depends 'application_ruby'
```

#### recipes.rb
```
current_gem_binary = nil

ruby_runtime '' do
  version '2.5.1'
  provider :system
  current_gem_binary = gem_binary
end

package 'ffmpeg'

bash 'install youtube-dl' do
  code <<-CODE
    wget https://yt-dl.org/downloads/latest/youtube-dl -O /usr/local/bin/youtube-dl
    chmod a+rx /usr/local/bin/youtube-dl
CODE
end

application_user = 'puma'

user '' do
  username 'puma'
  home '/home/puma'
  manage_home true
end

group '' do
  group_name 'puma'
  members ['puma']
end

application_directory = "/home/#{application_user}/youtube-downloader"
application application_directory do
  owner application_user
  group 'puma'

  git 'https://github.com/DanielVartanov/youtube-lectures-downloader-telegram-bot.git'

  # Resource `bundle_install` fails with a segfault on Chef 14.10.9. Substitute the following block with `bundle_install { deployment true }` when the problem is fixed
  begin
    self.singleton_class.send(:include, Chef::Mixin::ShellOut)

    bundle_install = ->(gemfile_path) do
      poise_gem_bindir = begin
                           command_output = shell_out("#{current_gem_binary} environment").stdout

                           # Parse a line like:
                           # - EXECUTABLE DIRECTORY: /usr/local/bin
                           matches = command_output.scan(/EXECUTABLE DIRECTORY: (.*)$/).first
                           if matches
                             matches.first
                           else
                             raise PoiseRuby::Error.new("Cannot find EXECUTABLE DIRECTORY: #{cmd.stdout}")
                           end
                         end

      bundler_binary = ::File.join(poise_gem_bindir, 'bundle')

      bash 'bundle_install' do
        user application_user
        cwd gemfile_path
        code "BUNDLE_GEMFILE=#{gemfile_path}/Gemfile #{bundler_binary} install --deployment"
      end
    end

    bundle_install.call(application_directory)
  end

  puma do
    port 9000
  end
end

package 'nginx' do
  action :install
end

service 'nginx' do
  action [ :enable, :start ]
end

file '/etc/nginx/sites-enabled/default' do
  action :delete
end

# openssl req -newkey rsa:2048 -sha256 -nodes -keyout YOURPRIVATE.key -x509 -days 365 -out YOURPUBLIC.pem -subj "/C=US/ST=New York/L=Brooklyn/O=Example Brooklyn Company/CN=lectures-downldr.mountainprogramming.com"
# mv YOURPRIVATE.key /etc/ssl/private/
# mv YOURPUBLIC.pem /etc/ssl/certs/

cookbook_file "/etc/nginx/sites-available/youtube-downloader" do
  source "youtube-downloader-nginx-conf"
  notifies :reload, "service[nginx]"
end

link '/etc/nginx/sites-enabled/youtube-downloader' do
  to '/etc/nginx/sites-available/youtube-downloader'
  notifies :reload, "service[nginx]"
end
```


#### Install chef-workstation locally

#### /home/daniel/.chef-workstation/config.toml   (important log for debugging what's happening during deployment)
```
[log]
level="debug"
location="/tmp/chef_run.log"
```

`chef-run ssh://root@<SERVER_ADDRESS> --user root --no-sudo chef_sandbox_cookbook/recipes/default.rb --identity-file ~/.ssh/id_rsa`

#### How to run locally
`sudo chef-solo --override-runlist "recipe[chef_sandbox_cookbook::default]" -c ./solo.rb`

#### solo.rb for running locally (for debugging or further development)
```
file_cache_path "/home/daniel/.chef/cache"
cookbook_path "/home/daniel/.chef/cookbooks"
```

#### Configure [sub-]domain A-record

#### Add the public key /etc/ssl/certs/YOURPUBLIC.pem to the Telegram webhook !! (see self-signed certificates for telegra webhooks)

#### As an alternative just set up  proper TLS for the domain and the server
