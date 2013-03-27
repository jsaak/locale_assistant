#!/usr/bin/env ruby

require 'test/unit'
require 'fileutils'

# begin
   # require 'simplecov'
   # SimpleCov.start do
      # root '../test'
   # end
# rescue LoadError
# end

require 'locale_assistant'

class TestParser < Test::Unit::TestCase
   def setup
      @la = LocaleAssistant.new
      `mkdir testdir`
   end

   def tempfile(str)
      @temp = File.new('testdir/test.temp','w+')
      @temp.write str
      @temp.close
      return 'testdir/test.temp'
   end

   def teardown
      `rm -r testdir`
   end

   def test_parser
      assert_equal([], @la.load_file(tempfile("\n\n\n"))[0])
      assert_equal([], @la.load_file(tempfile('#comment'))[0])
      assert_equal([], @la.load_file(tempfile('    #comment'))[0])
      assert_equal([], @la.load_file(tempfile('    #   ##  # comment'))[0])
      assert_equal([["a.b", "val"]], @la.load_file(tempfile("a: #comment\n  b: val"))[0])
      assert_equal([["a", "val   #comment"]], @la.load_file(tempfile("a: val   #comment"))[0])
      assert_equal([['a','v']], @la.load_file(tempfile("--- \na: v"))[0])
      assert_equal([['a','v']], @la.load_file(tempfile("\n\n\na: v\n\n"))[0])
      assert_equal([['a','v']], @la.load_file(tempfile("\n#comment\n     #comment\na: v\n\n"))[0])
      assert_raise(LocalAssistantException) do
         @la.load_file(tempfile("sallalal"))
      end
      assert_equal([['a.b','v']], @la.load_file(tempfile("a:\n b: v\n"))[0])
      assert_equal([['a.b','v']], @la.load_file(tempfile("a:\n b:        v   \n"))[0])
      assert_equal([['a.b','v:v']], @la.load_file(tempfile("a:\n b: v:v\n"))[0])

      expected_arr = [["a1.c1", "v1"],
                    ["a1.c1.b1", "v2"],
                    ["a1.c1.b2", "v3"],
                    ["a2", "v4"]]

      assert_equal(expected_arr, @la.load_file(tempfile(%Q|
a1:
  c1: v1
     b1: v2
     b2: v3
a2: v4
|))[0])

      assert_equal(expected_arr, @la.load_file(tempfile(%Q|
a1:
  c1: v1
        b1: v2
        b2: v3
a2: v4
|))[0])

   end

   def test_all
      `mkdir -p testdir/config`

      conffile = File.open('testdir/config/l_assistant.conf.rb','w+')
      conffile << %Q|
module ::LocaleAssistantConf
   Files = ['config/#lang#.yml']
   Languages = ['hu','en','es']
   IgnoreList = []
end
|
      conffile.close

      enfile = File.open('testdir/config/en.yml','w+')
      enfile << "en:\n  a: english\n"
      enfile.close

      esfile = File.open('testdir/config/es.yml','w+')
      esfile << "es:\n  a: espanol\n"
      esfile.close

      Dir.chdir('testdir') do
         ARGV[0] = 'en'
         @la.run
      end

      hustr = IO.readlines('testdir/config/hu.yml').join
      assert_equal("hu:\n  a: TODO english\n",hustr)
      esstr = IO.readlines('testdir/config/es.yml').join
      assert_equal("es:\n  a: espanol\n",esstr)
   end
end
