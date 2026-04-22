# frozen_string_literal: true

require 'bundler/setup'

APP_RAKEFILE = File.expand_path('test/dummy/Rakefile', __dir__)
load 'rails/tasks/engine.rake'

load 'rails/tasks/statistics.rake'

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

Rake::TestTask.new(:test) do |t|
  t.warning = false
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*test.rb']
end

task default: %i[test]
