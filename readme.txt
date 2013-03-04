locale_assistant is lightweight commandline tool
which helps you manage those big yaml files when using rails and multiple languages
if you want to keep things simple and do not need online services like localeapp

workflow:
 - install
 - setup
 - then edit only your chosen language
 - run "locale_assistant en" from your rails root direcotry (no need for bundle exec)
   this will sort your en.yml alphabetically (if 'en' is your primary language)
   update or generate other language files (defined in LocaleAssistant::Languages)
   ofcourse it can not translate, but will insert a "TODO (text in other language)" keys
 - commit

install:
gem install loacle_assistant

setup:
edit RAILS_ROOT/config/locale_assistant.conf.rb

module LocaleAssistant
   Files = ['config/locales/#lang#.yml',
            'config/locales/#lang#_models.yml',
            'vendor/engines/contract_management/config/locales/#lang#.yml',
            'vendor/engines/contract_management/config/locales/#lang#_models.yml' ]
   Languages = ['hu','en','he']
   IgnoreList = []
end

usage:
locale_assistant.rb [options] source_language
    -D, --destructive                If you want to clear keys that are not in the source language
    -t, --tempfile                   Use .temp files for inspecting before overwriting
    -i, --inspecting-mode            Do not make changes, just list the missing keys
    -h, --help                       Display this screen

notes:
this script understands only a limited subset of yaml
i had trouble instructing the yaml parser to cooperate
so i wrote a simple one, just enough to make this workflow fly
 

