# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :rspec, all_after_pass: true ,
              all_on_start: true do
  
  watch(%r{^spec/.+_spec\.rb$})

  watch('lib/yaoc.rb')  { "spec" }

  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/unit/lib/#{m[1]}_spec.rb" }
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/integration/lib/#{m[1]}_spec.rb" }

  watch('spec/spec_helper.rb')  { "spec" }

  watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }

end


guard :bundler do
  watch('Gemfile')
  # Uncomment next line if your Gemfile contains the `gemspec' command.
  watch(/^.+\.gemspec/)
end
