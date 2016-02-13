require 'sinatra/base'
require 'sinatra/json'

class GitLabMockup

  def initialize(repodirs)
    reponames = repodirs.collect{ |dir| File.basename(dir, '.git').split('-').first[0..-9] }
    # We actully hide whole stderr, not only sinatra, but
    # that's better than keep the noise added by request tracing
    @log, err = IO.pipe
    @server = Thread.fork do
      $stderr.reopen err
      MyServer.start reponames
    end
  end

  def last reponame
    MyServer.last reponame
  end

  def kill
    @server.kill
    @server.join
    $stderr.puts "END MOCKUP"
    dump @log, ' ## '
  end

  def dump(instream, prefix='', outstream=$stdout)
    begin
      line = instream.readline
      outstream.puts "#{prefix}#{line}"
    end until line.start_with?("END MOCKUP")
  end

  class MyServer < Sinatra::Base

    class << self

      def last reponame
        @@lasts[reponame]
      end

      def start(reponames)
        @@repos = reponames
        @@lasts = {}
        @@urls = {}
        run!
      end

    end

    helpers do

      def author
        {
            "id" => 0,
            "name" => "root",
            "username" => "root"
        }
      end

      def project_info(id)
        name = @@repos[id]
        dirname = @@urls[name] or name
        {
          'id' => id,
          'name' => name,
          'default_branch' => 'master',
          'http_url_to_repo' => "http://localhost/tmp/#{dirname}.git",
          'ssh_url_to_repo' => "localhost:/tmp/#{dirname}.git",
          'path' => dirname,
          'path_with_namespace' => "tmp/#{dirname}",
          'web_url' => "http://localhost/tmp/#{name}"
        }
      end

      def mr_response(id)
        {
          'id' => id, 'iid' => id,
          'target_branch' => 'master',
          'source_branch' => 'feature/branch'
        }
      end
    end

    get "/api/v3/projects/:project_id" do
      json project_info(params['project_id'].to_i)
    end

    get "/api/v3/projects/search/:query" do
      reponame = params['query'].split('-').first[0..-9]
      @@urls[reponame] = params['query'] unless @@urls.has_key?(reponame)
      project_id = @@repos.rindex(reponame)
      json [ project_info(project_id) ]
    end

    get "/api/v3/projects/:project_id/merge_requests" do
      json [ mr_response(params['project_id']) ]
    end

    post "/api/v3/projects/:project_id/merge_request/:mr_id/comments" do
      reponame = @@repos[params['project_id'].to_i]
      @@lasts[reponame] = "/mr_comment/#{params[:mr_id]} - #{params[:note]}"
      json author: author , note: request.body.string , created_at: Time.new.utc.strftime("%FT%TZ")
    end

    post "/api/v3/projects/:project_id/repository/commits/:sha/comments" do
      reponame = @@repos[params['project_id'].to_i]
      @@lasts[reponame] = "/comment/#{params[:sha]} - #{params[:note]}"
      json author: author , note: request.body.string , created_at: Time.new.utc.strftime("%FT%TZ")
    end

    post "/api/v3/projects/:project_id/statuses/:sha" do
      reponame = @@repos[params['project_id'].to_i]
      @@lasts[reponame] = "/status/#{params[:sha]} - #{params[:state]} - #{params[:target_url]}"
      json state: params[:state] , target_url: params[:target_url] , created_at: Time.new.utc.strftime("%FT%TZ")
    end

  end

end

