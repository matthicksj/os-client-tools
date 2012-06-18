require 'open4'
require 'benchmark'
require 'fileutils'
require 'timeout'

module AppHelper::RHC
  module CallbackHelper
    # Implements a method missing approach that will convert calls
    # like rhc_app_create into 'rhc app create' on the command line
    def method_missing(sym, *args, &block)
      if sym.to_s.start_with?("rhc")
        # Build up the command
        cmd = get_cmd(sym)

        # Get any blocks that should be run after processing
        cmd_block = get_cmd_block(cmd, args[0])

        # Add arguments to the command
        cmd << get_args(cmd, args[0])

        # Run the command, timing it
        time = Benchmark.realtime do
          run(cmd, args[0], &cmd_block).should == 0
        end

        # Log the benchmarking info
        perf_logger.info "#{time} #{sym.to_s.upcase} #{@namespace} #{@login}"
      else
        super(sym, *args, &block)
      end
    end

    def run(cmd, arg=nil)
      logger.info("Running: #{cmd}")

      exit_code = -1
      output = nil

      # Don't let a command run more than 5 minutes
      Timeout::timeout(500) do
        pid, stdin, stdout, stderr = Open4::popen4 cmd
        stdin.close

        # Block until the command finishes
        ignored, status = Process::waitpid2 pid
        out = stdout.read.strip
        err = stderr.read.strip
        logger.debug("Standard Output:\n#{out}")
        logger.debug("Standard Error:\n#{err}")

        # Allow a caller to pass in a block to process the output
        yield status.exitstatus, out, err, arg if block_given?
        exit_code = status.exitstatus
      end

      if exit_code != 0
        logger.error("(#{$$}): Execution failed #{cmd} with exit_code: #{exit_code.to_s}")
      end

      return exit_code
    end

    # Given a method name, convert to an equivalent
    # rhc command line string.  This method handles
    # exceptions like converting rhc_app_add_alias
    # to rhc app add-alias.
    def get_cmd(method_sym)
      cmd = method_sym.to_s.gsub('_', ' ')

      # Handle parameters with a dash
      cmd.gsub!('add alias', 'add-alias')
      cmd.gsub!('remove alias', 'remove-alias')
      cmd.gsub!('force stop', 'force-stop')

      return cmd
    end

    # Print out the command arguments based on the state of the application instance
    def get_args(cmd, cartridge=nil, debug=true)
      args = " "
      args << "-l #{@login} " if @login
      args << "-a #{@name} " if @name
      args << "-p #{@password} " if @password
      args << "-d " if debug

      # Command specific arguments
      case cmd
        when /domain/
          raise "No namespace set" unless @namespace
          args << "-n #{@namespace} "
        when /destroy/
          args << "-b "
        when /snapshot/
          args << "-f #{@snapshot} "
        when /create/
          args << "-r #{@repo} "
        when /add-alias/
          raise "No alias set" unless @alias
          args << "--alias #{@alias} "
        when /cartridge/
          raise "No cartridge supplied" unless cartridge
          args << "-c #{cartridge}"
      end

      args.rstrip
    end

    # This looks for a callback method that is defined for the command.
    # For example, a command with rhc_app_create_callback will match
    # and be returned for the 'rhc app create' command.  The most specific
    # callback will be matched, so rhc_app_create_callback being more
    # specific than rhc_app_callback.
    def get_cmd_callback(cmd, cartridge=nil)
      # Break the command up on spaces
      cmd_parts = cmd.split
      
      # Drop the 'rhc' portion from the array
      cmd_parts.shift

      # Look for a method match ending in _callback
      1..cmd_parts.length do
        begin
          # Look for a callback match and return on any find
          return method((cmd_parts.join("_") + "_callback").to_sym)
        rescue NameError
          # Remove one of the parts to see if there is a more
          # generic match defined
          cmd_parts.pop
        end
      end
    end
  end

  #
  # Begin Post Processing Callbacks
  #
  def app_create_callback(exitcode, stdout, stderr)
    update_uid(stdout)
    persist
  end

  def app_destroy_callback
    FileUtils.rm_rf @repo
    FileUtils.rm_rf @file
    @repo, @file = nil
  end

  def domain_alter_callback
    FileUtils.rm_rf @repo
    # TODO - re-setup repo
  end

  def cartridge_add_callback(exitcode, stdout, stderr, cartridge)
    if cartridge.start_with?('mysql-')
      @mysql_hostname = /^Connection URL: mysql:\/\/(.*)\/$/.match(stdout)[1]
      @mysql_user = /^ +Root User: (.*)$/.match(stdout)[1]
      @mysql_password = /^ +Root Password: (.*)$/.match(stdout)[1]
      @mysql_database = /^ +Database Name: (.*)$/.match(stdout)[1]

      @mysql_hostname.should_not be_nil
      @mysql_user.should_not be_nil
      @mysql_password.should_not be_nil
      @mysql_database.should_not be_nil
    end

    @embed << cartridge
    persist
  end

  def cartridge_remove_callback(exitcode, stdout, stderr, cartridge)
    @mysql_hostname = nil
    @mysql_user = nil
    @mysql_password = nil
    @mysql_database = nil
    @embed.delete(cartridge)
    persist
  end
end
