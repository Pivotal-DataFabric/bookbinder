require_relative '../ingest/repo_identifier'

module Bookbinder
  module Config
    class SectionConfig
      def initialize(config)
        @config = config
      end

      def subnav_template
        config['subnav_template']
      end

      def subnav_name
        config['subnav_name']
      end

      def desired_directory_name
        config['directory']
      end

      def repo_name
        repo['name']
      end

      def repo_url
        Ingest::RepoIdentifier.new(repo['name'])
      end

      def repo_ref
        repo['ref'] || 'master'
      end

      def preprocessor_config
        config.fetch('preprocessor_config', {})
      end

      def ==(other)
        config == other.instance_variable_get(:@config)
      end

      def merge(other_section_config)
        SectionConfig.new(config.merge(other_section_config.instance_variable_get(:@config)))
      end

      def inspect
        config.inspect
      end

      private

      def repo
        config.fetch('repository', {})
      end

      attr_reader :config
    end
  end
end

