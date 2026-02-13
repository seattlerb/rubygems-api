require "minitest/autorun"
require "rubygems/commands/api_command"
require "json"

module TestRubygems; end

# sabotage open-uri
class URI::HTTP
  def read(_) = raise "no"
end

class TestRubygems::TestApi < Minitest::Test
  attr_accessor :cmd, :inn, :out, :err

  def setup
    self.cmd = Gem::Commands::ApiCommand.new
    self.inn = StringIO.new
    self.out = StringIO.new
    self.err = StringIO.new
  end

  def test_sanity
    def cmd.read_url(_) = "[3,2,1]"

    out = "[\n  1,\n  2,\n  3\n]\n"
    assert_api out, "", %w[ /api/woot -j sort|. ]
  end

  def test_execute__vanilla
    def cmd.read_url(_) = "[3,2,1]"

    out = "[3,2,1]\n"
    assert_api out, "", %w[ /api/woot ]
  end

  def test_cmd__help
    assert_gem_output(/gem api URL/, "") do
      cmd.show_help
    end
  end

  def assert_api out, err, *args
    cmd.handle_options args.flatten

    assert_gem_output out, err do
      cmd.execute
    end
  end

  def assert_gem_output exp_out, exp_err
    ui = Gem::StreamUI.new inn, out, err

    Gem::DefaultUserInteraction.use_ui ui do
      yield
    end

    o_type = Regexp === exp_out ? :match : :equal
    e_type = Regexp === exp_err ? :match : :equal

    send "assert_#{o_type}", exp_out, out.string
    send "assert_#{e_type}", exp_err, err.string
  end
end
