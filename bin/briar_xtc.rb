require_relative './briar_dot_xamarin'
require_relative './briar_env'
require_relative './briar_rm'
require 'awesome_print'
require 'ansi/logger'

@log = ANSI::Logger.new(STDOUT)

# not yet - maybe never
##use <tt>rake install</tt> to install a gem at +path_to_gemspec+
## returns the version of the gem installed
#def rake_install_gem(path_to_gemspec)
#
#  #out = `"cd #{path_to_gemspec}; rake install"`
#
#  out = nil
#  Dir.chdir(File.expand_path(path_to_gemspec)) do
#    system 'rake install'
#  end
#
#
#  #cmd = "cd #{path_to_gemspec} ; rake install"
#  #output = []
#  #IO.popen(cmd).each do |line|
#  #  p line.chomp
#  #  output << line.chomp
#  #end
#
#  puts "out = '#{out}'"
#  exit 1
#  tokens = out.split(' ')
#  gem = tokens[0]
#  version = tokens[1]
#  @log.info { "installed #{gem} #{version}" }
#  version
#end

def briar_xtc_submit(device_set, profile, opts={})
  default_opts = {:build_script => ENV['IPA_BUILD_SCRIPT'],
                  :ipa => ENV['IPA'],
                  :profiles => ENV['XTC_PROFILES'],
                  :account => expect_xtc_account(),
                  :other_gems => ENV['XTC_OTHER_GEMS_FILE'],
                  :xtc_staging_dir => expect_xtc_staging_dir(),
                  :briar_dev => ENV['XTC_BRIAR_GEM_DEV'] == '1',
                  :calabash_dev => ENV['XTC_CALABASH_GEM_DEV'] == '1',
                  :async_submit => ENV['XTC_WAIT_FOR_RESULTS'] == '0',
                  :rebuild => true}


  opts = default_opts.merge(opts)

  build_script = opts[:build_script]

  if build_script
    expect_build_script(build_script)
    if opts[:rebuild]
      cmd = "#{build_script}"
    else
      cmd = "#{build_script} -"
    end
    system cmd
    briar_remove_derived_data_dups
  end

  account = opts[:account]
  api_key = read_api_token(account)

  if opts[:briar_dev]
    briar_path = `bundle show briar`.strip
    system('gem uninstall briar --no-executables --ignore-dependencies --quiet',
           :err => '/dev/null')
    Dir.chdir(File.expand_path(briar_path)) do
      system 'rake install'
    end
  end

  if opts[:calabash_dev]
    calabash_path = `bundle show calabash-cucumber`.strip
    system('gem uninstall calabash-cucumber --no-executables --ignore-dependencies --quiet',
           :err => '/dev/null')

    Dir.chdir(File.expand_path(calabash_path)) do
      system 'rake install'
    end
  end

  other_gems = []
  if opts[:other_gems] != ''
    path = File.expand_path(opts[:other_gems])
    File.read(path).split("\n").each do |line|
      # stay 1.8.7 compat
      next if line.strip.length == 0 or line.chars.to_a.first.eql?('#')
      other_gems << line.strip
    end
  end

  xtc_gemfile = "#{opts[:xtc_staging_dir]}/Gemfile"

  File.open(xtc_gemfile, 'w') do |file|
    file.write("source 'https://rubygems.org'\n")
    if opts[:briar_dev]
      briar_version = `bundle exec briar version`.strip
      file.write("gem 'briar', '#{briar_version}'\n")
    else
      file.write("gem 'briar'\n")
    end

    if opts[:calabash_dev]
      calabash_version = `bundle exec calabash-ios version`.strip
      file.write("gem 'calabash-cucumber', '#{calabash_version}'\n")
    elsif not opts[:briar_dev]
      file.write("gem 'calabash-cucumber'\n")
    end

    other_gems.each do |gem|
      file.write("#{gem}\n")
    end
  end

  sets = read_device_sets
  if sets[device_set]
    device_set = sets[device_set]
  end

  profile = 'default' if profile.nil?

  if opts[:async_submit]
    wait = '--async'
  else
    wait = '--no-async'
  end

  ipa = File.basename(File.expand_path(expect_ipa(opts[:ipa])))

  cmd = "DEBUG=0 test-cloud submit #{ipa} #{api_key} -d #{device_set} -c cucumber.yml -p #{profile} #{wait}"
  puts Rainbow("cd xamarin; #{cmd}").green
  Dir.chdir(opts[:xtc_staging_dir]) do
    exec cmd
  end
end


def briar_xtc(args)
  arg_len = args.length
  if arg_len == 0
    ap read_device_sets
    exit 0
  end

  device_set = args[0]
  profile = arg_len == 1 ? nil : args[1]


  if arg_len == 3
    rebuild_arg = args[2]
    unless rebuild_arg == '-'
      @log.fatal { "unknown optional argument '#{rebuild_arg}' expected '-'" }
      exit 1
    end
    opts = {:rebuild => false}
  else
    opts = {:rebuild => true}
  end

  if arg_len > 3
    @log.warn{ "expected at most 3 args by found '#{args}' - ignoring extra input" }
  end

  briar_xtc_submit(device_set, profile, opts)
end
