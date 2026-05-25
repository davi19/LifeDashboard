# TODO: Write documentation for `Lifedashboard`
require "kemal"

module Lifedashboard
  VERSION = "0.1.0"
  get "/" do
      "Hello World"
  end

Kemal.run
end
