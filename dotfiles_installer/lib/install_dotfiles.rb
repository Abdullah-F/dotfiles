require 'fileutils'

class InstallDotfiles
  attr_accessor :argv, :stdin, :stdout

  def initialize(argv, stdin, stdout)
    self.argv     = argv
    self.stdin    = stdin
    self.stdout   = stdout
  end

  def symlink(options)
    existing       = File.expand_path options.fetch :existing
    new            = File.expand_path options.fetch :new
    new_is_symlink = Kernel.test 'l', new
    new_exists     = Kernel.test 'e', new

    if new_is_symlink && File.realdirpath(new) == File.realdirpath(existing)
      # noop, work would be redundant
    elsif new_is_symlink || new_exists
      should_overwrite = prompt "Overwrite #{new.inspect}? [y/n]", /^(y|n)/i do |response|
        response.downcase.start_with? 'y'
      end
      if should_overwrite
        FileUtils.rm_rf new
        FileUtils.ln_s existing, new
      end
    else
      FileUtils.mkdir_p File.dirname(new)
      FileUtils.ln_s    existing, new
    end
  end

  def append(file_name, content)
    FileUtils.mkdir_p File.dirname file_name
    FileUtils.touch file_name
    includes_content = File.read(file_name).include? content
    unless includes_content
      File.open(file_name, 'a') { |file| file.puts content }
    end
  end

  private

  def prompt(message, validation, &interpret)
    begin
      stdout.write message
      result = stdin.gets
    end until result =~ validation
    interpret.call result
  end
end