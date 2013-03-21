Locale Assistant
================

is a lightweight commandline tool
which helps you manage those big yaml files when using rails and multiple languages

if you want to keep things simple and do not need online services like [localeapp](http://www.localeapp.com/ "localeapp")

Workflow
--------------
<pre>
  - install
  - setup
  - edit only your chosen language .yml file
  - run "locale_assistant en" from your rails root direcotry (no need for bundle exec)
    this will sort your en.yml alphabetically (if 'en' is your primary language)
    update or generate other language files (defined in LocaleAssistant::Languages)
    Of course it can not translate, but will insert "TODO (text in other language)" keys in other files
  - commit
</pre>

Install
--------------
<pre>
$ gem install locale_assistant
</pre>
or you can just copy that single file from the bin directory

Setup
--------------
edit <code>RAILSROOT/config/l_assistant.conf.rb</code>
<pre>
module LocaleAssistant
   Files = ['config/locales/#lang#.yml',
            'config/locales/#lang#_models.yml',
            'vendor/engines/contract_management/config/locales/#lang#.yml',
            'vendor/engines/contract_management/config/locales/#lang#_models.yml' ]
   Languages = ['hu','en','he']
   IgnoreList = []
end
</pre>

Usage
--------------
<pre>
$ locale_assistant.rb [options] source_language
    -D, --destructive                If you want to clear keys that are not in the source language
    -t, --tempfile                   Use .temp files for inspecting before overwriting
    -i, --inspecting-mode            Do not make changes, just list the missing keys
    -h, --help                       Display this screen
</pre>

Notes
--------------
<pre>
This script understands only a limited subset of yaml.
I had trouble instructing the yaml parser to cooperate, so i wrote a simple one, just enough to make this workflow fly
Full line comments, empty lines, and comments on non leaf elements are dropped
Comments on leaves are untouched
</pre>
