require "time"
require "rack/utils"
require "rack/mime"
require "goliath/api"


module GuideEmUp
  class Browser < Goliath::API
    def initialize(dir)
      @root = dir
      @data = File.expand_path("../../../data", __FILE__)
    end

    def response(env)
      path_info = Rack::Utils.unescape(env["PATH_INFO"])
      filename  = File.join(@root, path_info)
      datafile  = File.join(@data, path_info)
      if File.file?(filename)
        serve_guide(filename)
      elsif filename.include? ".."
        unauthorized_access
      elsif File.directory?(filename)
        serve_index(filename)
      elsif datafile =~ /\/guideemup\/(css|images|icons|js)\//
        serve_data(datafile.sub 'guideemup', '')
      else
        page_not_found(path_info)
      end
    end

  protected

    def serve_guide(filename)
      body = Guide.new(filename).html
      [200, {
        "Content-Type"   => "text/html; charset=utf-8",
        "Content-Length" => Rack::Utils.bytesize(body).to_s
      }, [body] ]
    end

    def serve_index(path_info)
      body = Index.new(@root, path_info, @data).html
      [200, {
        "Content-Type"   => "text/html; charset=utf-8",
        "Content-Length" => Rack::Utils.bytesize(body).to_s,
      }, [body] ]
    end

    def serve_data(filename)
      if File.exists?(filename)
        body = File.read(filename)
        [200, {
          "Content-Type"   => Rack::Mime.mime_type(File.extname filename),
          "Content-Length" => Rack::Utils.bytesize(body).to_s,
        }, [body] ]
      else
        page_not_found(filename)
      end
    end

    def page_not_found(path_info)
      [404, {
        "Content-Type"   => "text/plain",
        "Content-Length" => "0"
      }, ["File not found: #{path_info}\n"] ]
    end

    def unauthorized_access
      [403, {
        "Content-Type"   => "text/plain",
        "Content-Length" => "0"
      }, ["Forbidden\n"] ]
    end
  end
end