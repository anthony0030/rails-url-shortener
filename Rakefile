# frozen_string_literal: true

require 'bundler/setup'

APP_RAKEFILE = File.expand_path('test/dummy/Rakefile', __dir__)
load 'rails/tasks/engine.rake'

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'

namespace :lint do
  RuboCop::RakeTask.new(:ruby) do |task|
    task.fail_on_error = false
  end

  desc 'Run cspell spell checking'
  task spelling: :environment do
    sh "npx cspell --dot --gitignore '**'; exit 0"
  end

  desc 'Run markdownlint'
  task markdown: :environment do
    sh 'npx markdownlint-cli ./**/*.md; exit 0'
  end
end

desc 'Run all linters'
task lint: %w[lint:ruby lint:spelling lint:markdown]

desc 'Update schema annotations in models, tests, and fixtures'
task annotate: :environment do
  sh 'bundle exec annotate --models'
end

Rake::TestTask.new(:test) do |t|
  t.warning = false
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*test.rb']
end

task :test_prepare do
  # Drop and recreate only the test DB from schema so migrations never get stuck
  Rake::Task['app:db:test:purge'].invoke
  Rake::Task['app:db:schema:load'].invoke
end

task test: :test_prepare

task default: %i[test]
