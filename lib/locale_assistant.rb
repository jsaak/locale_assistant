#!/usr/bin/env ruby

require 'optparse'

class LocaleAssistantException < Exception
   attr_reader :exit_code, :message

   def initialize(exit_code,message)
      @exit_code = exit_code
      @message = message
   end
end

class LocaleAssistant
   def run
      begin
         require Dir.pwd+'/config/l_assistant.conf.rb'
      rescue LoadError
         raise LocaleAssistantException.new(-1,%Q|Needs a config file located at CURRENT_DIR/config/l_assistant.conf.rb
something like this:

module LocaleAssistantConf
   Files = ['config/locales/#lang#.yml',
            'config/locales/#lang#_models.yml',
            'vendor/engines/contract_management/config/locales/#lang#.yml',
            'vendor/engines/contract_management/config/locales/#lang#_models.yml' ]
   Languages = ['hu','en','he']
   IgnoreList = []
end
|)
      end

      options = parse_command_line

      if LocaleAssistantConf::Languages.include?(ARGV[0])
         puts "using " + ARGV[0] + " as source language"
         LocaleAssistantConf::Files.each do |file|
            process_file(Dir.pwd+'/',file,ARGV[0],options[:inspecting_mode],options[:destructive],options[:tempfile],options[:add_hyphens])
         end
      else
         raise LocaleAssistantException.new(-2,"Usage: locale_assistant [options] source_language")
      end
   end

   def parse_command_line
      options = {}

      optparse = OptionParser.new do |opts|
         opts.banner = "Usage: locale_assistant [options] source_language"

         options[:destructive] = false
         opts.on( '-D', '--destructive', 'If you want to clear keys that are not in the source language' ) do
            options[:destructive] = true
         end

         options[:tempfile] = false
         opts.on( '-t', '--tempfile', 'Use .temp files for inspecting before overwriting' ) do
            options[:tempfile] = true
         end

         options[:inspecting_mode] = false
         opts.on( '-i', '--inspecting-mode', 'Do not make changes, just list the missing keys' ) do
            options[:inspecting_mode] = true
         end

         options[:add_hyphens] = false
         opts.on( '-a', '--add_hyphens', 'Add "--- \n" to the beginning of every yaml file' ) do
            options[:add_hyphens] = true
         end

         opts.on( '-h', '--help', 'Display this screen' ) do
            raise LocaleAssistantException.new(-3,opts)
         end
      end

      optparse.parse!
      return options
   end

   def load_file(fn)
      arr = []
      hash = {}

      keystore = []
      indentstore = []
      spaces = -1

      begin
         f = File.open(fn)
         linecount = 0
         f.each_line do |line|
            linecount += 1
            next if line.strip.size == 0             # remove empty lines
            next if line.lstrip.start_with? '#'      # remove full line comments
            next if line.start_with? '---'           # remove hyphens

            key,val = line.strip.split(/:/,2)

            if val.nil?
               f.close
               raise LocaleAssistantException.new(-4,"ERROR line can not be parsed at #{fn}:#{linecount}")
            end

            val = val.strip

            if (val.strip[0..0] == '|') or (val.strip[0..0] == '>')
               f.close
               raise LocaleAssistantException.new(-5,"ERROR multiline is not supported at #{fn}:#{linecount}")
            end 

            val = '' if val.start_with? '#'           # remove comments from non leaf elements

            curr_spaces = (line.size - line.lstrip.size)

            if curr_spaces > spaces
               indentstore.push(curr_spaces-spaces)
               spaces = curr_spaces
               keystore.push(key)
            elsif curr_spaces == spaces
               keystore.pop
               keystore.push(key)
            elsif curr_spaces < spaces
               keystore.pop
               while curr_spaces < spaces
                  spaces -= indentstore.pop
                  keystore.pop
               end
               keystore.push(key)
            end

            unless val == ''
               x = keystore.join('.')
               hash[x] = val
               arr.push([x,val])
            end
         end
         f.close

         arr.sort!
      rescue Errno::ENOENT
      end

      return [arr,hash]
   end

   def write_out(fn,array,hash,country_code,add_hyphens)
      f = File.new(fn,'w+')
      prev_x = []
      indent = 0

      f << "--- \n" if add_hyphens

      array.each do |key,val|
         next if LocaleAssistantConf::IgnoreList.include?(key)
         x = key.split('.')
         x[0] = country_code

         counter = 0
         prev_x.each do |fragment|
            counter +=1
            break if x[counter-1] != fragment
         end

         indent = 0
         counter -= 1 if counter > 1
         x[counter..-1].each do |fragment|
            f << ('  '*(counter+indent)) + fragment + ':'
            if indent+1 == x[counter..-1].size
               value2 = hash[country_code+key[2..-1]]
               if value2.nil?
                  f << val.gsub(/^(['"]?)/,' \1TODO ')
               else
                  f << ' ' + value2.to_s
               end
            end
            f << "\n"
            indent += 1
         end

         prev_x = x
      end
      f.close
   end

   def process_file(path,file,source,inspecting_mode,destructive,use_tempfile,add_hyphens)
      arrays = {}
      hashes = {}
      LocaleAssistantConf::Languages.each do |lang|
         arrays[lang],hashes[lang] = load_file(path + file.gsub('#lang#',lang))
      end

      arrays[source].each do |key,val|
         general_key = key[2..-1]
         (LocaleAssistantConf::Languages-[source]).each do |lang|
            localized_key = lang+general_key
            unless hashes[lang].include?(localized_key)
               if LocaleAssistantConf::IgnoreList.include?(localized_key)
                  #puts fn_beg+lang+fn_end + ' ignoring:' + localized_key
               else
                  arrays[lang] << [localized_key,val]
                  puts file.gsub('#lang#',lang) + ' MISSING: ' + localized_key
               end
            end
         end
      end

      #ignore lists
      LocaleAssistantConf::IgnoreList.each do |key|
         lang = key[0..1]
         base_key = key[3..-1]
         arrays[lang] << [key,hashes[lang][base_key]]
      end

      if inspecting_mode == false
         LocaleAssistantConf::Languages.each do |lang|
            (arrays[lang]).sort! {|a,b| a[0] <=> b[0]}
            language_to_use = lang
            language_to_use = source if destructive

            file_suffix = ''
            file_suffix = '.temp' if use_tempfile

            write_out(path + file.gsub('#lang#',lang)+file_suffix,arrays[language_to_use],hashes[lang],lang,add_hyphens)
         end
      end
   end
end
