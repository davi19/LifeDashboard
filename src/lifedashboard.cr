# TODO: Write documentation for `Lifedashboard`
require "kemal"
public_folder "public"

module Lifedashboard
  VERSION = "0.1.0"
  get "/" do
    render "src/views/login.ecr", "src/views/layouts/layout.ecr"
  end



  post "/" do |env|

   puts       env.params.body
  end
    Kemal.run
end
