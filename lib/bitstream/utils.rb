# Author:: Natsuki Kawai (natsuki.kawai@gmail.com)
# Copyright:: Copyright (c) 2012 Natsuki Kawai
# License:: 2-clause BSDL or Ruby's

module BitStream

  module Utils

    def self.class2symbol(type)
      name = type.name.split("::").last
      name = self.camel2snake(name).intern
    end

    def self.camel2snake(camel)
      snake = camel.dup
      snake[0] = snake[0].downcase
      snake.gsub(/[A-Z]/) do |s|
        "_" + s.downcase
      end
    end

  end

end
