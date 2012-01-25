
begin
  require 'bones'
rescue LoadError
  abort '### Please install the "bones" gem ###'
end

task :default => 'test:run'
task 'gem:release' => 'test:run'

Bones {
  name     'result_parser'
  authors  'Vicente Bosch'
  email  'vbosch@gmail.com'
  url  'http://github.com/vbosch/result_parser'
  ignore_file  '.gitignore'
}

