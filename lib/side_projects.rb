require "concurrent/array"
require_relative "side_project/base"

module Houston
  class SideProjects

    def initialize
      @array = Concurrent::Array.new
    end

    def start!(project)
      unless project.respond_to?(:start!)
        raise ArgumentError, "<project> must respond to `start!` which should accept no arguments and which should start the side project"
      end

      unless project.respond_to?(:on_complete)
        raise ArgumentError, "<project> must respond to `on_complete` which should accept a block that will be called when the project finishes"
      end

      unless project.respond_to?(:describe)
        raise ArgumentError, "<project> must respond to `describe` which should return a string explaining what Houston is currently doing"
      end

      project.on_complete do
        array.delete project
      end

      array.push project

      project.start!
      project
    end

    def empty?
      array.empty?
    end

    def map(&block)
      array.map(&block)
    end

    def select(&block)
      array.select(&block)
    end

    def reject(&block)
      array.reject(&block)
    end

  private
    attr_reader :array

  end
end
