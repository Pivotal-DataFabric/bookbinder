require 'git'
require_relative '../directory_helpers'
require_relative 'update_failure'
require_relative 'update_success'

module Bookbinder
  module Ingest
    class GitAccessor
      TagExists = Class.new(RuntimeError)
      InvalidTagRef = Class.new(RuntimeError)
      include DirectoryHelperMethods

      def clone(url, name, path: nil, checkout: 'master')
        cached_clone(url, name, Pathname(path)).tap do |git|
          git.checkout(checkout)
        end
      end

      def update(cloned_path)
        Git.open(cloned_path).pull
        Ingest::UpdateSuccess.new
      rescue ArgumentError, Git::GitExecuteError => e
        case e.message
        when /overwritten by merge/
          Ingest::UpdateFailure.new('merge error')
        when /path does not exist/
          Ingest::UpdateFailure.new('not found')
        else
          raise
        end
      end

      def read_file(filename, from_repo: nil, checkout: 'master')
        Dir.mktmpdir do |dir|
          path = Pathname(dir)
          git = cached_clone(from_repo, temp_name("read-file"), path)
          git.checkout(checkout)
          path.join(temp_name("read-file"), filename).read
        end
      end

      def author_date(path)
        Pathname(path).dirname.ascend do |current_dir|
          if current_dir.to_s.include?(source_dir_name) && current_dir.entries.include?(Pathname(".git"))
            git = Git.open(current_dir)
            return git.gblob(path).log.first.author.date
          end
        end
      end

      private

      def temp_name(purpose)
        "bookbinder-git-accessor-#{purpose}"
      end

      def cached_clone(url, name, path)
        dest_dir = path.join(name)
        if dest_dir.exist?
          Git.open(dest_dir)
        else
          Git.clone(url, name, path: path)
        end
      end
    end
  end
end
